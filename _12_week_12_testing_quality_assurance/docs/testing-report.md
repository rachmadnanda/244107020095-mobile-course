# Laporan Pengujian — Week 12

Dokumen ini melengkapi [`../README.md`](../README.md). Isinya: lingkungan
pengujian, matriks skenario, desain fake, analisis cakupan, dan batasan yang
masih terbuka.

## 1. Lingkungan

| Komponen | Nilai |
| --- | --- |
| Flutter | 3.47.2 (stable) |
| Dart | mengikuti Flutter SDK |
| Perangkat integration test | emulator `sdk_gphone64_x86_64` |
| Android | 15 (API 35), 1080×2280 @ 440 dpi |
| Build | debug (integration test), host VM (unit/widget) |
| Data | SQLite lokal; integration test menghapus `offline_notes.db` lebih dulu |
| Jaringan | tidak dipakai untuk test (fake HTTP/repository) |

## 2. Piramida pengujian

| Lapisan | Alat | Kecepatan | Yang dibuktikan |
| --- | --- | --- | --- |
| Unit | `test()` | Milidetik | Aturan bisnis, validasi, pemetaan failure, state notifier |
| Widget | `testWidgets()` | Ratusan milidetik | Render, finder, input, SnackBar, dialog, empty/error state |
| Integrasi | `integration_test` | Puluhan detik | Wiring app nyata: router → provider → repository → SQLite |

Pembagiannya sengaja: semakin ke bawah, semakin sedikit test, tetapi semakin
tinggi keyakinan bahwa bagian-bagian benar-benar tersambung.

## 3. Matriks skenario

Kolom “Aktual” adalah hasil yang benar-benar diamati saat suite dijalankan,
bukan harapan yang ditulis belakangan.

| Kode | Skenario | Jenis | Langkah | Aktual |
| --- | --- | --- | --- | --- |
| U1 | Judul valid dengan spasi di tepi | Unit | `AddNote.call(title: '  Belanja  ')` | Lulus; judul tersimpan `Belanja`, body ter-trim |
| U2 | Judul kosong | Unit | `AddNote.call(title: '')` | Lulus; `ValidationFailure`, repository 0 panggilan |
| U3 | Judul hanya spasi | Unit | `AddNote.call(title: '   ')` | Lulus; `ValidationFailure`, repository 0 panggilan |
| U4 | Repository gagal saat add | Unit | `SpyNoteRepository(fail: true)` | Lulus; `LocalFailure` diteruskan, tidak dilempar |
| U5 | Fetch daftar gagal | Unit | `FakeNoteRepository(fetchFailure: …)` | Lulus; state `AsyncError`, `value == null` |
| U6 | Add gagal di state notifier | Unit | `addNote` dengan `addFailure` | Lulus; daftar tetap 1 item, failure dikembalikan |
| U7 | Delete gagal di state notifier | Unit | `deleteNote` dengan `deleteFailure` | Lulus; item tetap ada, `deletedIds` kosong |
| W1 | Dialog tambah dibuka | Widget | Tap FAB, `pumpAndSettle` | Lulus; field judul/isi kosong |
| W2 | Simpan judul kosong | Widget | Isi `'   '`, tap Simpan | Lulus; SnackBar “Judul catatan tidak boleh kosong”, dialog tetap terbuka |
| W3 | Simpan catatan valid | Widget | Isi judul/isi, tap Simpan | Lulus; dialog tertutup, catatan muncul di daftar |
| W4 | Simpan gagal | Widget | Fake `addFailure`, tap Simpan | Lulus; pesan error tampil, dialog tetap terbuka |
| W5 | Detail catatan ada | Widget | `NoteDetailPage(noteId: 1)` | Lulus; judul, isi, badge dirty tampil |
| W6 | Detail tidak ditemukan | Widget | Repository mengembalikan `null` | Lulus; “Catatan tidak ditemukan” |
| W7 | Detail gagal dibaca | Widget | `fetchNoteFailure` | Lulus; pesan error tampil |
| I1 | Alur utama | Integrasi | Tambah → detail → kembali → cari | Lulus; catatan tersimpan dan ditemukan |

Test lama yang tetap dijalankan: pencarian, empty state, `NoteTile`, rebuild
scope, asistensi AI, privasi, Gemini repository, batas riwayat chat,
auto-dispose provider, dan penjaga API key.

## 4. Desain fake repository

Kontrak yang dipakai:

```dart
abstract interface class NoteRepository {
  Future<({List<Note> notes, Failure? failure})> fetchNotes();
  Future<({Note? note, Failure? failure})> fetchNote(int id);
  Future<({Note? note, Failure? failure})> addNote({
    required String title,
    String body,
  });
  Future<({Failure? failure})> deleteNote(int id);
  Future<({int count, Failure? failure})> countDirty();
  Future<({Failure? failure})> markAllSynced();
}
```

`FakeNoteRepository` mengimplementasikan seluruh kontrak dan menyediakan:

| Field | Efek |
| --- | --- |
| `notes` | Data awal yang dikembalikan `fetchNotes` |
| `dirtyCount` | Nilai `countDirty` |
| `fetchFailure` | `fetchNotes` mengembalikan failure |
| `fetchNoteFailure` | `fetchNote` mengembalikan failure |
| `addFailure` | `addNote` mengembalikan failure tanpa menambah data |
| `deleteFailure` | `deleteNote` mengembalikan failure tanpa menghapus data |

Selain itu ada counter `fetchNotesCalls`, `fetchNoteCalls`, `addNoteCalls`,
`deleteNoteCalls`, `countDirtyCalls`, `markAllSyncedCalls`, dan daftar
`deletedIds`. Counter ini dipakai untuk membuktikan, misalnya, bahwa
`addNote` tidak memicu pembacaan ulang seluruh tabel.

Fake **bukan** mock yang mengharapkan urutan pemanggilan tertentu. Fake adalah
implementasi kecil dengan state yang bisa dikendalikan; test tetap memeriksa
perilaku yang terlihat (daftar berubah/tidak berubah, pesan muncul, dialog
tertutup/tetap terbuka).

## 5. Isolasi test

- Setiap widget test membuat `ProviderScope` baru dan `FakeNoteRepository`
  baru; tidak ada state yang dibagi antar test.
- Test unit memakai `ProviderContainer` baru dengan `addTearDown(dispose)`.
- Integration test menghapus database sebelum aplikasi dijalankan:

  ```dart
  final dbPath = p.join(await getDatabasesPath(), 'offline_notes.db');
  await databaseFactory.deleteDatabase(dbPath);
  ```

- Pada test fetch-failure, retry Riverpod dimatikan
  (`retry: (_, _) => null`) agar state error bisa diperiksa. Ini hanya berlaku
  di test; aplikasi produksi tetap memakai perilaku retry bawaan Riverpod.
- Tidak ada `Future.delayed` untuk “menunggu” UI. Test memakai `pump`,
  `pumpAndSettle`, dan finder berbasis `Key`.

## 6. Analisis cakupan

Perintah:

```bash
flutter test --coverage
./tool/coverage_summary.sh
```

Ringkasan:

| Metrik | Nilai |
| --- | ---: |
| Baris tercatat | 566 |
| Baris tertutup | 477 |
| Cakupan baris | **84,3%** |
| File `lib/` yang muncul di lcov | 22 dari 32 |

Rincian yang relevan:

| Area | Cakupan | Catatan |
| --- | ---: | --- |
| Use case notes | 100% | Add/Get/Search/Sync |
| `note_detail_page.dart` | 100% | Sukses, tidak ditemukan, error |
| `note_tile.dart` | 100% | Render dan badge |
| `add_note_dialog.dart` | 96,8% | Hampir seluruh jalur UI |
| `notes_providers.dart` | 95,7% | Termasuk jalur failure |
| `notes_page.dart` | 73,8% | Bagian AppBar/offline belum semua |
| `note_repository_impl.dart` | 0% | Hanya dijalankan integration test |
| `db.dart` | 0% | Hanya dijalankan integration test |
| `api_key_store.dart` | 14,3% | Butuh plugin secure storage |

**Interpretasi.** Cakupan 84,3% bukan “aplikasi 84,3% bebas bug”. Angka ini
mengukur baris yang dieksekusi oleh test unit/widget. Justru lapisan data nyata
(`NoteRepositoryImpl` dan `db.dart`) tidak tercatat karena sengaja diganti fake
di unit/widget test; lapisan itu baru diuji oleh integration test, yang tidak
masuk ke lcov. Flutter juga tidak menghasilkan data cakupan cabang, sehingga
cabang `if/else` tidak bisa dilaporkan terpisah.

## 7. Hasil perintah

```text
$ dart format --set-exit-if-changed .
Formatted 52 files (0 changed) in 0.18 seconds.

$ flutter analyze
Analyzing _12_week_12_testing_quality_assurance...
No issues found! (ran in 4.5s)

$ flutter test
00:14 +95: All tests passed!

$ flutter test integration_test/app_test.dart -d emulator-5554
00:00 +0: alur utama: tambah catatan, buka detail, lalu cari
00:11 +1: (tearDownAll)
00:16 +1: All tests passed!
```

Log lengkap ada di [`../screenshots/`](../screenshots/README.md).

## 8. Batasan dan temuan terbuka

1. Jalur sukses SQLite belum punya unit test; hanya integration test yang
   menjalankannya.
2. `main.dart`, router, dan halaman pengaturan belum diuji mendalam.
3. `flutter_secure_storage` tidak diuji karena butuh plugin platform.
4. Gemini API nyata tidak dipanggil; HTTP diuji dengan client palsu.
5. Tidak ada data cakupan cabang dari Flutter.
6. Integration test baru dijalankan di satu emulator.
7. Integration test hanya menguji alur bahagia; error database belum diuji
   end-to-end.
8. Perilaku retry Riverpod di produksi tidak diuji khusus (dimatikan hanya di
   satu test agar error state bisa diamati).

## 9. Refleksi

**Bug apa yang paling mungkin terlewat tanpa pengujian yang ditulis?**
Kegagalan yang tetap terlihat seperti sukses: dialog menutup padahal simpan
gagal, item hilang dari layar padahal delete gagal, atau daftar berubah menjadi
kosong saat fetch error. Test jalur gagal memastikan state tidak berubah dan
pesan yang benar muncul.

**Bagian mana yang perlu fake, dan bagaimana fake membuat pengujian lebih
konsisten?**
`NoteRepository` dan `AiAssistantRepository`. Keduanya adalah batas lambat dan
bergantung lingkungan. Fake memberi data dan failure yang deterministik,
sehingga test tidak bergantung pada isi database, jaringan, atau kuota API.

**Apa perbedaan nilai pengujian widget dan integrasi?**
Widget test cepat dan presisi untuk satu layar; integrasi membuktikan sambungan
antar layer (router, provider, repository, SQLite) yang tidak terlihat oleh
widget test. Keduanya diperlukan: widget test menjaga detail perilaku,
integration test menjaga alur utama tetap utuh.

## 10. Reproduksi

```bash
flutter pub get
dart format --set-exit-if-changed .
flutter analyze
flutter test
flutter test --coverage
./tool/coverage_summary.sh
flutter test integration_test/app_test.dart -d emulator-5554
```
