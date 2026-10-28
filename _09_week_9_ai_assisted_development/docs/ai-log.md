# AI Log — Week 9 (Pencarian Judul Catatan)

Dokumen ini menyimpan **prompt**, **output awal AI**, **verifikasi**, dan
**keputusan terima/tolak**. Nilai ada pada verifikasi, bukan pada banyaknya
kode AI.

## 1. Prompt 5 slot (yang benar-benar dipakai)

```text
Peran: senior Flutter dev.
Konteks: project week 7 feature-first Clean Architecture.
  lib/features/notes/{domain,data,presentation}; domain bebas Flutter/SQLite.
  Riverpod 3.4.3 (flutter_riverpod), sqflite 2.4.4, go_router 18.
  Kontrak: NoteRepository.fetchNotes() -> ({List<Note> notes, Failure? failure}).
  Entity Note: {int? id, String title, String body, DateTime updatedAt, bool dirty}.
Tugas: tambah pencarian judul catatan di NotesPage + empty state.
Batas: jangan ubah arsitektur, jangan panggil SQLite dari widget, maks 80 baris,
  jangan sentuh settings/.
Output: kode + 3 test case + cara uji manual.
```

Konteks yang **tidak** disertakan: token/secret apa pun, seluruh repo.
Yang disertakan hanya struktur folder + satu kontrak repository + entity.

## 2. Output awal AI (DRAFT v1, ditempel apa adanya)

```dart
import 'package:sqflite/sqflite.dart';        // (1) import lintas layer

List<Note> filterNotes(List<Note> notes, String query) {
  if (query.isEmpty) return notes;
  return notes.where((note) => note.title.containsIgnoreCase(query)).toList(); // (2)
}

// NotesPage diubah jadi ConsumerStatefulWidget, filter dipanggil dari build():
//   final filtered = filterNotes(items, _query);
//   TextField(onChanged: (v) => setState(() => _query = v))
```

### Verifikasi langkah 1–2: baca + cek import

```bash
grep -n "package:sqflite" lib/features/notes/presentation/pages/notes_page.dart
# 4:import 'package:sqflite/sqflite.dart';   <- pelanggaran dependency rule
```

### Verifikasi langkah 3: cek API nyata → **halusinasi terbukti**

```text
$ flutter analyze
warning • Unused import: 'package:sqflite/sqflite.dart' • notes_page.dart:4:8 • unused_import
  error • The method 'containsIgnoreCase' isn't defined for the type 'String'
          • notes_page.dart:13:43 • undefined_method
```

Bukti lengkap: [`../screenshots/analyze-draft-v1.txt`](../screenshots/analyze-draft-v1.txt).

**Kesimpulan:** `String.containsIgnoreCase()` **tidak ada** di Dart. Ini pola
halusinasi *method fiktif* — API terasa masuk akal (mirip `equalsIgnoreCase`
di Java) tetapi tidak ada di SDK. Cara membuktikan: `flutter analyze` +
autocomplete IDE (Dart `String` hanya punya `contains`, `toLowerCase`, dll).

## 3. Patch AI v2 — kompilasi lolos, logika masih salah

```dart
List<Note> filterNotes(List<Note> notes, String query) {
  if (query.isEmpty) return notes;
  return notes.where((note) => note.title.contains(query)).toList(); // case-sensitive
}
```

`flutter analyze` bersih → terlihat "selesai". Ini contoh *logika yakin tapi
salah*: pencarian "belanja" gagal menemukan "Belanja Bulanan".

### Verifikasi langkah 5: test merah pembukti bug

`test/search_filter_test.dart` ditulis **sebelum** perbaikan, menargetkan
perilaku yang benar (case-insensitive + trim):

```text
$ flutter test test/search_filter_test.dart
Expected: an object with length of <2>
  Actual: [Instance of 'Note']      <- 'BELANJA' hanya menemukan 1 dari 2
Expected: an object with length of <1>
  Actual: []                        <- '  bumi  ' tidak menemukan apa pun (tanpa trim)
Failing tests: 2
```

Bukti: [`../screenshots/test-red-before-fix.txt`](../screenshots/test-red-before-fix.txt).

## 4. Refactor ke Clean Architecture (langkah 5)

| Sebelum (AI v2) | Sesudah (manual + refactor) |
| --- | --- |
| `filterNotes()` di `presentation/pages/notes_page.dart` | `domain/usecases/search_notes.dart` — fungsi murni, bisa diuji tanpa widget |
| `setState(() => _query = ...)` di widget | `searchQueryProvider` (state) + `filteredNotesProvider` (komposisi) |
| `import 'package:sqflite'` di presentation | dihapus; presentation hanya `ref.watch` + render |
| Case-sensitive, tanpa trim | `toLowerCase()` + `trim()` di use case |

Potongan use case final:

```dart
class SearchNotes {
  const SearchNotes();

  List<Note> call(List<Note> notes, String query) {
    final keyword = query.trim().toLowerCase();
    if (keyword.isEmpty) return notes;
    return notes
        .where((note) => note.title.toLowerCase().contains(keyword))
        .toList();
  }
}
```

## 5. Halusinasi kedua: API Riverpod 2 vs 3

Saat menulis empty state, saya memakai `notes.valueOrNull` (ingatan Riverpod 2):

```text
error • The getter 'valueOrNull' isn't defined for the type 'AsyncValue<List<Note>>'
        • notes_page.dart:158:44 • undefined_getter
```

Diverifikasi ke source package yang benar-benar terpasang:

```bash
grep -rn "get value" ~/.pub-cache/hosted/pub.dev/riverpod-3.4.3/lib/src/common/result.dart
# 30:  ValueT? get value;
```

Di Riverpod 3.4.3 getter-nya `value` (nullable), bukan `valueOrNull`.
Pola halusinasi: *package kadaluarsa* — API versi lama dipakai pada versi baru.

## 6. AI Challenge — review kode search (3 temuan)

Prompt:

```text
Review kode search Flutter ini sebagai senior dev.
Konteks: feature-first (presentation->domain<-data), Riverpod, SQLite + Dio.
Fokus: kebenaran, arsitektur, test. Abaikan style.
Beri 3 temuan + level blocker/saran + alasan.
```

### Temuan #1 — (blocker) tombol clear tidak mengosongkan field

> Observasi: `TextField` tidak punya `controller`; tombol clear hanya mengubah
> `searchQueryProvider`. Dampak: daftar kembali penuh tetapi teks "bumi" tetap
> tampil di field — user melihat filter aktif padahal tidak. Usul: pakai
> `TextEditingController` dan panggil `clear()`.

**Verifikasi:** test merah dengan asersi pada `EditableText.controller.text`:

```text
Expected: empty
  Actual: 'bumi'
```

Bukti: [`../screenshots/test-red-clear-button.txt`](../screenshots/test-red-clear-button.txt).

**Keputusan: DITERIMA + diperbaiki.** `NotesPage` jadi
`ConsumerStatefulWidget` yang memegang `TextEditingController` (di-dispose),
sementara nilai query tetap di provider. Test yang sama kini hijau.

### Temuan #2 — (saran) `SearchNotes` mengembalikan referensi list asli saat query kosong

> Observasi: `if (keyword.isEmpty) return notes;` mengembalikan list yang sama
> dengan state provider. Dampak: pemanggil yang memutasi hasil bisa merusak
> state. Usul: `return List.unmodifiable(notes)` atau `[...notes]`.

**Verifikasi:** `grep -n "return notes;" domain/usecases/search_notes.dart` →
benar, referensi diteruskan. Namun dicek pemakaiannya:
`filteredNotesProvider` hanya `ListView.builder` (read-only), tidak ada mutasi.

**Keputusan: DITOLAK (untuk saat ini).** Menyalin list setiap rebuild saat
query kosong menambah alokasi tanpa manfaat nyata; `Note` sendiri immutable
dan tidak ada satu pun pemanggil yang memutasi hasil. Dicatat sebagai
kandidat perbaikan bila muncul pemanggil baru yang memutasi.

### Temuan #3 — (saran) tambahkan debounce 150 ms pada input pencarian

> Observasi: setiap ketikan langsung mengubah `searchQueryProvider`.
> Dampak: filter dijalankan tiap karakter. Usul: `Timer` debounce 150 ms.

**Verifikasi:** diukur — pencarian adalah **filter in-memory** pada list yang
sudah dimuat (`O(n)` tanpa I/O). Untuk ratusan catatan biayanya mikro.

**Keputusan: DITOLAK.** Debounce menambah state async, `Timer` yang harus
dibatalkan, dan test berbasis waktu (flaky) — over-engineering untuk filter
in-memory. Debounce baru masuk akal bila query memicu I/O (SQLite `LIKE` /
request jaringan).

## 7. Tabel keputusan per file

| File | Keputusan | Alasan |
| --- | --- | --- |
| `presentation/pages/notes_page.dart` (draft AI) | **TOLAK + tulis manual** | Import `sqflite` melanggar dependency rule; filter & `setState` di widget |
| `domain/usecases/search_notes.dart` | **TULIS MANUAL** (AI hanya memberi ide) | Aturan bisnis harus murni & bisa diuji; AI menaruhnya di presentation |
| `presentation/providers/notes_providers.dart` | **TERIMA + REFACTOR** | Ide state query dari AI bagus, tapi dipindah ke provider Riverpod |
| `test/search_filter_test.dart` | **TULIS MANUAL** | Test AI hanya kasus sukses; ditambah kasus gagal, trim, spasi, list kosong |
| `test/search_widget_test.dart` | **TULIS MANUAL** | Butuh fake repository + empty state (AI tidak menyertakan widget test) |
| `TextEditingController` (temuan #1) | **TERIMA** | Bug nyata, dibuktikan test merah |

## 8. Bukti mesin hijau (final)

```text
$ flutter analyze
1 issue found.   <- hanya info package_names (bawaan penamaan folder repo)

$ dart format --set-exit-if-changed .
Formatted 23 files (0 changed)   <- exit 0

$ flutter test
00:09 +23: All tests passed!
```

Bukti: [`../screenshots/analyze-format-final.txt`](../screenshots/analyze-format-final.txt),
[`../screenshots/flutter-test-final.txt`](../screenshots/flutter-test-final.txt).

## 9. Uji manual (3 query)

| Query | Harapan | Hasil |
| --- | --- | --- |
| `bumi` | 1 hasil (Bumi Manusia) | ✅ |
| `BUMI` | 1 hasil (case-insensitive) | ✅ |
| `zzz` | empty state "Tidak ada catatan yang cocok dengan "zzz"" | ✅ |
| (kosong / tombol clear) | semua catatan kembali, field kosong | ✅ |
