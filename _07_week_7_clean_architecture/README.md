# Week 7 — Clean Architecture (Offline Notes)

Refactor project **Minggu 5 (`week5_offline_notes`)** menjadi **Clean
Architecture feature-first**. Bukan project baru — kode yang sudah jalan
dipindahkan dan dipisahkan per layer. Versi "before" tetap utuh di folder
`_05_week_5_local_storage_offline_first/`.

## Tujuan

- Menerapkan prinsip SOLID dan separation of concerns pada kode Flutter nyata.
- Menerapkan struktur feature-first dengan tiga layer: presentation / domain / data.
- Membuktikan dependency rule (dependensi hanya mengarah ke dalam) lewat grep sterilitas.
- Menguji use case dengan repository palsu tanpa SQLite/Dio/Firebase.

## Diagram layer & arah dependensi

```
presentation (widget, notifier, router)
      |
      v  bergantung ke
domain (entity, repository interface, use case, failure)
      ^
      |  diimplementasikan oleh
data (model, repository impl, SQLite, SharedPreferences)
```

Aturan emas: **dependensi hanya mengarah ke dalam.** `domain` tidak mengimpor
Flutter, Dio, SQLite, Firebase, atau SharedPreferences — sehingga logika bisnis
bisa diunit-test murni.

## Struktur folder

```
lib/
├── core/
│   ├── failures.dart          # Failure domain (murni Dart)
│   └── format.dart            # format tanggal/parse murni (bisa diuji)
├── features/
│   ├── notes/
│   │   ├── domain/
│   │   │   ├── entities/note.dart                # entity murni (tanpa mapping)
│   │   │   ├── repositories/note_repository.dart  # INTERFACE
│   │   │   └── usecases/{get_notes, add_note, sync_notes}.dart
│   │   ├── data/
│   │   │   ├── local/{db.dart, note_model.dart}  # mapping hanya di model
│   │   │   └── repositories/note_repository_impl.dart
│   │   └── presentation/
│   │       ├── providers/notes_providers.dart     # SATU-SATUNYA wiring DI
│   │       ├── pages/{notes_page, note_detail_page}.dart
│   │       └── widgets/note_tile.dart
│   └── settings/
│       ├── data/prefs_repository.dart
│       └── presentation/
│           ├── providers/settings_providers.dart
│           └── pages/settings_page.dart
└── main.dart
```

## Fitur utama

1. **Fitur notes** — entity murni `Note`, kontrak `NoteRepository` di domain,
   implementasi `NoteRepositoryImpl` (SQLite) di data, use case
   `GetNotes` / `AddNote` / `SyncNotes`, wiring DI di `notes_providers.dart`.
2. **Fitur settings** — repo `PrefsRepository` di data + provider di
   presentation (tanpa domain layer, lihat AI Challenge §5.4).
3. **Kontrak eksplisit** — repository/use case mengembalikan record
   `(value, failure)`; exception sumber data diubah jadi `Failure` ramah pengguna.
4. **Entity vs model** — mapping SQLite hanya di `NoteModel`; entity bebas mapping.

## Stack teknologi

| Komponen | Paket |
| --- | --- |
| State management / DI | `flutter_riverpod` |
| Navigasi | `go_router` |
| Database lokal | `sqflite` |
| Preferensi | `shared_preferences` |

## Cara menjalankan

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

## Bukti dependency rule (tiga grep sterilitas)

Semua menghasilkan **NOL**:

```text
# 1. Presentation steril dari data mentah
rg "Dio\(|openDatabase|getDatabasesPath|FlutterSecureStorage|SharedPreferences\.getInstance|jsonDecode" lib/features/*/presentation
→ NOL

# 2. Domain steril dari framework & package
rg "import 'package:flutter|import 'package:dio|import 'package:sqflite|import 'package:firebase|package:shared_preferences" lib/features/*/domain lib/core
→ NOL

# 3. Widget tidak menginstansiasi repository (DI bocor)
rg "NoteRepository\(|PrefsRepository\(|NoteRepositoryImpl\(" lib/features/*/presentation/pages lib/features/*/presentation/widgets
→ NOL
```

## Behavior identik (before / after)

Aplikasi berjalan sama persis seperti sebelum refactor (tambah/hapus catatan,
detail, sinkronisasi, mode gelap). Bukti screenshot before/after ada di folder
[`screenshots/`](screenshots/) — folder `_05_...` adalah versi before.

## AI Challenge

Proses lengkap (prompt, output awal AI, tabel usulan-vs-keputusan-final, dan
hasil grep) ada di [`docs/ai-challenge.md`](docs/ai-challenge.md). Audit layer
project lama ada di [`docs/praktikum1-audit.md`](docs/praktikum1-audit.md).

Ringkasan penyederhanaan atas usulan AI: 7 use case → 3, wrapper `Either`
sendiri → record bawaan, data source terpisah → digabung ke repository impl, dan
settings tanpa domain layer.

## Hasil yang dicapai

- `flutter analyze`: 0 error / 0 warning (hanya info `package_names` bawaan
  konvensi penamaan folder repo).
- `flutter test`: 8 test lulus — entity/model round-trip, use case sukses & gagal
  dengan repository palsu (`GetNotes`, `SyncNotes`), provider dengan fake repo,
  dan widget test.
- Tiga grep sterilitas: **NOL** semua.

## Refleksi

**1. Mengapa interface repository harus tinggal di domain, bukan di data? Apa yang rusak bila dibalik?**

Interface menggambarkan **kebutuhan domain**, bukan cara mengambil data. Bila
ditaruh di data, domain harus mengimpor layer di atasnya → dependensi mengarah
ke luar (melanggar dependency rule) dan domain tidak bisa diuji dengan fake yang
mengimplementasikan kontraknya sendiri. Dengan interface di domain, data
"memenuhi" kontrak domain; arah panah tetap ke dalam.

**2. Kapan use case benar-benar dibutuhkan, dan kapan repository langsung ke notifier sudah cukup?**

Use case dibutuhkan saat operasi **menggabungkan >1 repository atau punya aturan
bisnis** (validasi, sorting, sinkron). Contoh di project ini: `SyncNotes`
(gabung `countDirty` + `markAllSynced` + aturan offline). Untuk CRUD satu-baris
(`deleteNote`, `fetchNote`) repository langsung ke notifier sudah cukup — use
case hanya menambah file tanpa menambah kejelasan.

**3. Apa biaya over-engineering (use case per CRUD satu-baris) bagi tim kecil? Kapan biayanya sepadan?**

Biayanya: lebih banyak file/indireksi untuk dipahami, boilerplate tiap operasi,
dan melambatkan perubahan kecil. Untuk tim kecil dengan CRUD sederhana itu tidak
sepadan. Biayanya sepadan bila logika bisnis kompleks, banyak sumber data
(remote + local + cache), atau tim besar yang butuh batas kontrak yang tegas.

**4. Bagian mana dari usulan AI yang Anda tolak atau sederhanakan, dan mengapa?**

Detail di [`docs/ai-challenge.md`](docs/ai-challenge.md). Ringkasnya: menolak
use case per CRUD satu-baris (7 → 3), menolak wrapper `Either`/base-class use
case (pakai record bawaan), menolak data source terpisah untuk SQLite sederhana,
dan tidak memberi settings domain layer — semuanya demi menghindari
over-engineering tanpa mengorbankan dependency rule.
