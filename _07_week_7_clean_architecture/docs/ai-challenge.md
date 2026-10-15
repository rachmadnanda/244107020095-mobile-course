# AI Challenge — Refactor ke Clean Architecture (fitur notes + settings)

Dokumen ini merekam proses AI Challenge untuk codelab Week 7: prompt, output
awal AI (draf usulan), verifikasi terhadap checklist, tabel usulan-vs-keputusan
final, dan alasan teknis.

- Prompt: [§1](#1-prompt-yang-diberikan)
- Output awal AI: [§2](#2-output-awal-ai-ringkasan)
- Tabel usulan vs keputusan: [§3](#3-tabel-usulan-vs-keputusan-final)
- Verifikasi checklist + grep: [§4](#4-ai-verification-checklist)
- Keputusan & alasan: [§5](#5-keputusan-final--alasan-teknis)

Implementasi final: `lib/features/` + `lib/core/`.

---

## 1. Prompt yang diberikan

```text
Project Flutter saya: week5_offline_notes (catatan offline + settings dark mode).
Kondisi kini: folder lib/{data, pages, widgets}, repository tercampur dengan
implementasi, provider DI tersebar di file halaman, entity dan model jadi satu
kelas, exception mentah mencapai UI.
Tugas:
1. Usulkan struktur feature-first Clean Architecture (presentation/domain/data)
   untuk fitur notes (dan settings).
2. Untuk tiap file lama, sebutkan tujuan barunya (pindah/pecah/hapus).
3. Tandai bagian yang over-engineering bila diterapkan ke CRUD sederhana,
   dan kapan use case benar-benar dibutuhkan vs repository langsung.
4. Tunjukkan wiring DI dengan Riverpod (tanpa package DI tambahan).
Jelaskan trade-off setiap keputusan.
```

## 2. Output awal AI (ringkasan)

AI mengusulkan struktur feature-first berikut. **Draf ini diverifikasi dulu**
(checklist §4) sebelum diterapkan — bukan langsung dipakai.

```text
lib/
├── core/
│   ├── failures.dart
│   ├── result.dart            # wrapper Either<Failure, T> sendiri
│   └── usecase.dart           # abstract class UseCase<Params, Result>
├── features/
│   ├── notes/
│   │   ├── domain/
│   │   │   ├── entities/note.dart
│   │   │   ├── repositories/note_repository.dart
│   │   │   └── usecases/   # get, get_by_id, add, delete, count_dirty, mark_synced, sync  (7 use case)
│   │   ├── data/
│   │   │   ├── models/note_model.dart
│   │   │   ├── datasources/notes_local_data_source.dart   # lapisan tambahan
│   │   │   └── repositories/note_repository_impl.dart
│   │   └── presentation/
│   │       ├── providers/notes_providers.dart
│   │       └── pages/...
│   └── settings/
│       ├── domain/entities/settings.dart + usecases/...   # entity + use case untuk prefs
│       ├── data/...
│       └── presentation/...
```

## 3. Tabel usulan vs keputusan final

| # | Usulan AI | Keputusan final | Alasan singkat |
| --- | --- | --- | --- |
| 1 | 7 use case untuk tiap operasi CRUD (get, getById, add, delete, countDirty, markSynced, sync) | **3 use case**: `GetNotes`, `AddNote`, `SyncNotes`. Sisanya (fetchNote, deleteNote, countDirty, markAllSynced) langsung repository → notifier | Use case per CRUD satu-baris = over-engineering; lihat §5.2 |
| 2 | Wrapper `Result`/`Either` sendiri (`core/result.dart`) + `core/usecase.dart` abstract base | **Record Dart** `(value, failure)` bawaan bahasa; tanpa base class use case | Behavior sama, lebih sedikit kode & dependensi; record sudah idiomatik Dart 3 |
| 3 | Lapis `datasources/notes_local_data_source.dart` terpisah dari repository impl | **Digabung**: `NoteRepositoryImpl` langsung pegang `Database` | Untuk CRUD SQLite sederhana, data source terpisah tidak menambah nilai |
| 4 | Fitur settings punya entity + use case sendiri | **Tanpa entity/use case** — hanya repo (`PrefsRepository`) di data + provider di presentation | Settings hanya read/write prefs; domain kosong = pura-pura berlapis |
| 5 | `Failure` + return record di repository | **Diterapkan persis** | Selaras dengan kontrak domain & kebutuhan test |
| 6 | Interface repository di domain, impl di data | **Diterapkan** | Syarat dependency rule |
| 7 | Entity bebas mapping, `NoteModel` extends `Note` | **Diterapkan** | Mapping hanya di model |
| 8 | Wiring DI terpusat di satu file provider per fitur | **Diterapkan** (`notes_providers.dart`, `settings_providers.dart`) | Widget tidak `new Repository()` |
| 9 | `core/format.dart` untuk formatting murni | **Ditambah** (Refactoring Challenge) | Fungsi format tanggal/parse bisa diuji tanpa widget |

## 4. AI Verification Checklist

| # | Item verifikasi | Hasil | Bukti |
| --- | --- | --- | --- |
| 1 | Interface repository di domain, implementasi di data? | ✅ | `features/notes/domain/repositories/note_repository.dart` (abstract) vs `features/notes/data/repositories/note_repository_impl.dart` |
| 2 | Domain bebas import Flutter/Dio/SQLite/Firebase? | ✅ | Grep 2 di bawah → NOL |
| 3 | AI membuat use case untuk tiap CRUD satu-baris? | ⚠️ **Ya, 7 buah → disederhanakan jadi 3** | Usulan #1 ditolak sebagian; alasan §5.2 |
| 4 | Entity bebas mapping (`toMap`/`fromMap` hanya di model)? | ✅ | `domain/entities/note.dart` murni; `data/local/note_model.dart` yang mapping |
| 5 | Wiring DI terpusat di provider, widget tidak `new Repository()`? | ✅ | Grep 3 di bawah → NOL |
| 6 | Keputusan final boleh berbeda dari saran AI selama berargumen | ✅ | Lihat §3 & §5 |

### Hasil tiga grep verifikasi

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

Bukti visual ketiga grep (dan `flutter test` hijau) tersedia di
`../screenshots/greps-zero.png` dan `../screenshots/tests-pass.png`
(lihat `../screenshots/README.md`).

## 5. Keputusan final & alasan teknis

### 5.1 Interface repository di domain (diterapkan)

Kontrak ditentukan oleh kebutuhan domain, sehingga interface harus tinggal di
domain. Bila dibalik (interface di data), domain akan bergantung ke luar —
melanggar dependency rule dan membuat domain tidak bisa diuji dengan fake yang
mengimplementasikan kontraknya sendiri.

### 5.2 Use case hanya saat ada logika (AI yang usulkan 7 disederhanakan jadi 3)

Use case bernilai bila operasi **menggabungkan >1 repository atau punya aturan
bisnis**. Di fitur ini:

- `SyncNotes` → menggabungkan `countDirty` + `markAllSynced` **dan** aturan
  "tolak saat offline" → **layak jadi use case**.
- `GetNotes`, `AddNote` → operasi dominan UI, dipakai presentation berulang →
  use case tipis yang tetap memberi titik uji domain tanpa SQLite.
- `deleteNote`, `fetchNote`, `countDirty`, `markAllSynced` → CRUD satu-baris →
  **repository langsung ke notifier**; membuat use case hanya menambah file
  tanpa menambah kejelasan.

### 5.3 Record bawaan, bukan wrapper Either sendiri

`({List<Note> notes, Failure? failure})` memberi sinyal sukses/gagal eksplisit
tanpa melempar exception ke UI, dan tanpa membuat/menguji tipe `Either` sendiri.
Pola kontraknya identik dengan `fpdart/dartz`, jadi migrasi mudah bila nanti
diperlukan.

### 5.4 Settings tanpa domain layer

Settings hanya baca/tulis preferensi lokal. Memaksakan entity + use case di sini
adalah over-engineering: domain-nya kosong dan tidak ada aturan bisnis. Cukup
repo di data + provider di presentation, tetap mematuhi aturan dependensi.

### 5.5 Repository impl langsung pegang `Database` (tanpa data source terpisah)

Untuk satu sumber data lokal yang sederhana, memisah `NotesLocalDataSource`
hanya menambah indireksi. Bila kelak ada remote + local + cache, lapisan data
source baru layak ditambah — saat kebutuhannya nyata, bukan sekarang.
