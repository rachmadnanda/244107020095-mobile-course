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

## Laporan Praktikum 1 — Audit layer project lama

Audit penuh ada di [`docs/praktikum1-audit.md`](docs/praktikum1-audit.md). Ringkasan:

**Peta file → layer (masalah utama):**

| File lama | Layer | Masalah |
| --- | --- | --- |
| `lib/data/local/note.dart` | data+domain | Entity & model jadi satu kelas; `toMap`/`fromMap` menempel di bisnis. |
| `lib/data/repositories/note_repository.dart` | data | Kontrak + implementasi tercampur; melempar exception, bukan `Failure`. |
| `lib/data/sync.dart` | data+bisnis | `syncNotes` = logika bisnis (gabung repo + aturan offline) → calon use case. |
| `lib/pages/*.dart` | presentation+provider | Provider DI tersebar di halaman; `new Repository()` langsung. |

**Hasil tiga grep audit (before):**
- Grep A (data mentah di presentation): **NOL**.
- Grep B (logika bisnis di `build()`): **NOL**.
- Grep C (DI bocor): **3 temuan** — `PrefsRepository()` di `main.dart`, `PrefsRepository()` & `NoteRepository()` di-instantiate di provider file halaman.

## Laporan Praktikum 2 — Domain & data per fitur

Fitur `notes` dipisah menjadi:

- **Domain** (`features/notes/domain/`): entity `Note` murni (tanpa mapping),
  **interface** `NoteRepository` (return record `(value, failure)`), dan use case
  `GetNotes` / `AddNote` / `SyncNotes` (yang menggabungkan aturan bisnis).
- **Data** (`features/notes/data/`): `NoteModel` (satu-satunya tempat
  `toMap`/`fromMap`, extends `Note` + `toEntity()`), `NoteRepositoryImpl` (SQLite,
  mengubah exception → `LocalFailure`), `db.dart` (data source).

Keputusan: `SyncNotes` layak jadi use case (gabung `countDirty` + `markAllSynced`
+ aturan offline); `deleteNote`/`fetchNote` tetap repository langsung (CRUD
satu-baris). Lihat AI Challenge §5.2.

## Laporan Praktikum 3 — Presentation, DI, verifikasi

- **DI terpusat**: `notes_providers.dart` dan `settings_providers.dart` adalah
  satu-satunya tempat wiring; widget tidak pernah `new Repository()`.
- **Halaman steril**: hanya `ref.watch` + render; tanpa SQL/Dio/JSON/format mentah.
- **Fitur settings** juga dipisah (data + presentation).
- **Verifikasi**: 3 grep sterilitas NOL (lihat bagian "Bukti dependency rule"),
  `flutter analyze` bersih, `flutter test` 8 hijau. Behavior diuji manual identik.

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
detail, sinkronisasi, mode gelap). Inti bukti: **UI sama, struktur folder beda.**
Daftar gambar ada di [`screenshots/README.md`](screenshots/README.md); folder
`_05_...` adalah versi before.

**Placeholder screenshot (jalankan `flutter run` di folder ini):**

| File | Yang ditunjukkan | Membuktikan |
| --- | --- | --- |
| `after-notes-list.png` | Daftar catatan berisi item + badge "Belum tersinkron" | Baca data lewat `GetNotes` tetap jalan |
| `after-add-note.png` | Dialog tambah catatan + hasil setelah disimpan | `AddNote` use case + repo berfungsi |
| `after-note-detail.png` | Halaman detail satu catatan (`/note/:id`) | `fetchNote` + rute tetap jalan |
| `after-sync.png` | SnackBar hasil sinkronisasi | `SyncNotes` + offline toggle berfungsi |
| `after-settings.png` | Halaman pengaturan (mode gelap + waktu terakhir dibuka) | Fitur settings (prefs) tetap jalan |
| `before-notes-list.png` | Daftar catatan dari project `_05_...` (before) | Tampilan sama sebelum refactor |
| `structure-before.png` | Struktur `lib/` lama `{data, pages, widgets}` | Struktur sebelum refactor |
| `structure-after.png` | Struktur `lib/` baru (`core/`, `features/.../{domain,data,presentation}`) | Inti Clean Architecture |
| `tests-pass.png` | Output terminal `flutter test` (8 hijau) | Test lulus |
| `greps-zero.png` | Output terminal 3 grep sterilitas (NOL) | Dependency rule terbukti |

## AI Challenge

Proses lengkap ada di [`docs/ai-challenge.md`](docs/ai-challenge.md). Ringkasan:

**Prompt yang diberikan** (inti):

```text
Project Flutter saya: week5_offline_notes. Kondisi kini: lib/{data, pages, widgets},
repository tercampur implementasi, provider DI tersebar, entity & model satu kelas.
Tugas: (1) usulkan struktur feature-first Clean Architecture untuk notes+settings;
(2) tujuan baru tiap file lama; (3) tandai yang over-engineering untuk CRUD
sederhana + kapan use case dibutuhkan vs repository langsung; (4) wiring DI
Riverpod. Jelaskan trade-off tiap keputusan.
```

**Usulan AI (yang disederhanakan):** 7 use case per operasi CRUD, wrapper
`Either`/`Result` sendiri + base class use case, lapisan `datasources/` terpisah,
dan settings diberi domain layer sendiri.

**Tabel usulan vs keputusan final:**

| Usulan AI | Keputusan final | Alasan |
| --- | --- | --- |
| 7 use case (tiap CRUD) | **3 use case** (`GetNotes`, `AddNote`, `SyncNotes`) | Use case per CRUD satu-baris = over-engineering |
| Wrapper `Either`/`Result` + base class | **Record Dart** `(value, failure)` | Idiomatik Dart 3, lebih sedikit kode |
| `datasources/` terpisah | **Digabung** ke `NoteRepositoryImpl` | Satu sumber data sederhana tidak butuh indireksi |
| Settings ber-domain layer | **Tanpa domain layer** | Settings hanya read/write prefs, domain-nya kosong |
| Interface di domain, impl di data | **Diterapkan** | Syarat dependency rule |
| Entity bebas mapping, `NoteModel` extends `Note` | **Diterapkan** | Mapping hanya di model |
| Wiring DI terpusat di provider | **Diterapkan** | Widget tidak `new Repository()` |

Bukti visual checklist ada di `screenshots/greps-zero.png` (placeholder). Audit
layer project lama: [`docs/praktikum1-audit.md`](docs/praktikum1-audit.md).

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
