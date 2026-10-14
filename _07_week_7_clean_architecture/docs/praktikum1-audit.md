# Praktikum 1 — Audit Layer Project Lama

Project: `week5_offline_notes` (hasil copy ke `_07_week_7_clean_architecture`).
Tujuan: memetakan file ke layer dan menandai pelanggaran sebelum refactor.

## 1. Peta file → layer

| File | Layer saat ini | Masalah |
| --- | --- | --- |
| `lib/pages/notes_page.dart` | presentation (+ provider) | Provider DI tersebar di sini; `NotesNotifier` memanggil `NoteRepository()` yang langsung `new` (bukan abstraksi); exception mentah mencapai UI. |
| `lib/pages/note_detail_page.dart` | presentation (+ provider) | Sama: `noteByIdProvider` didefinisikan di file halaman, bergantung pada repository konkret. |
| `lib/pages/settings_page.dart` | presentation (+ provider) | `PrefsRepository()` di-`new` di provider; provider DI tersebar. |
| `lib/widgets/note_tile.dart` | presentation | OK: hanya render `Note`, tanpa jaringan/database. |
| `lib/data/local/note.dart` | data (+ domain tercampur) | **Entity dan model jadi satu kelas** — `toMap`/`fromMap` (mapping SQLite) menempel di kelas bisnis `Note`. |
| `lib/data/repositories/note_repository.dart` | data | **Kontrak + implementasi tercampur satu kelas** (`NoteRepository` sekaligus query SQLite). Tidak ada interface; melempar exception, bukan `Failure`. |
| `lib/data/local/db.dart` | data | OK: hanya membuka SQLite (data source). |
| `lib/data/prefs.dart` | data | `SharedPreferences.getInstance()` langsung di kelas; di-`new` manual di provider + `main.dart`. |
| `lib/data/sync.dart` | data (+ logika bisnis) | `cachePosts`/`readCachedPosts` = data; `syncNotes(repo, offline)` = **logika bisnis** (gabung repository + aturan offline) → calon use case. |

## 2. Tiga pelanggaran klasik (hasil grep)

### Grep A — data mentah di presentation
```
rg "Dio\(|http\.|openDatabase|getDatabasesPath|SharedPreferences\.getInstance|FlutterSecureStorage|jsonDecode" lib/pages lib/widgets
```
Hasil: **NOL** (halaman/widget sudah tidak memegang Dio/SQLite/SharedPreferences langsung).

### Grep B — logika bisnis di `build()`
```
rg "DateFormat|jsonDecode|\.toIso8601String" lib/pages lib/widgets
```
Hasil: **NOL** (formatting/parsing tidak bocor ke `build`).

### Grep C — instansiasi manual (DI bocor)
```
rg "Repository\(|PrefsRepository\(|Dio\(BaseOptions" lib/pages lib/widgets lib/main.dart
```
Hasil (temuan):
```
lib/main.dart:12:        await PrefsRepository().markOpenedNow();
lib/pages/settings_page.dart:6:  final prefsRepositoryProvider = Provider((ref) => PrefsRepository());
lib/pages/notes_page.dart:13:    final noteRepositoryProvider = Provider((ref) => NoteRepository());
```
**Masalah:** provider DI tersebar di file halaman, dan repository **diinstansiasi langsung** (tidak lewat abstraksi). `PrefsRepository()` juga di-`new` di `main()`.

## 3. Masalah struktural (di luar tiga grep)

1. **Entity vs model tercampur** — `Note` (bisnis) memuat `toMap`/`fromMap`.
2. **Kontrak & implementasi tercampur** — tidak ada `NoteRepository` interface di domain.
3. **Exception mentah ke UI** — `syncNotes` melempar `StateError`; repository melempar exception; UI menangkap `$error` generik. Belum ada `Failure`.
4. **Provider DI tersebar** — di file halaman, bukan satu tempat wiring.

## 4. Struktur target (feature-first)

```
lib/
├── core/
│   ├── failures.dart          # Failure domain (murni Dart)
│   └── format.dart            # (Refactoring Challenge) format tanggal / parse rute
├── features/
│   └── notes/
│       ├── domain/
│       │   ├── entities/note.dart               # murni, tanpa mapping
│       │   ├── repositories/note_repository.dart # INTERFACE
│       │   └── usecases/{get_notes, add_note, sync_notes}.dart
│       ├── data/
│       │   ├── local/{db.dart, note_model.dart} # mapping hanya di model
│       │   └── repositories/note_repository_impl.dart
│       └── presentation/
│           ├── providers/notes_providers.dart   # satu-satunya wiring DI
│           └── pages/{notes_page, note_detail_page}.dart
├── features/settings/...      # (Refactoring Challenge) prefs → settings feature
└── main.dart
```
