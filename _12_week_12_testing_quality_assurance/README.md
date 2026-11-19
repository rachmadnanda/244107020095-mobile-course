# Week 12 — Pengujian dan Jaminan Kualitas

Melanjutkan aplikasi catatan **Week 11** (`../_11_week_11_performance_optimization/`)
— bukan project baru. Minggu ini tidak menambah fitur; fokusnya adalah
**membuktikan perilaku aplikasi dengan pengujian** dan memakai cakupan kode
sebagai bahan evaluasi.

> **Status verifikasi (19 November 2026):**
> `dart format` bersih · `flutter analyze` **No issues found** ·
> **95/95 test unit + widget lulus** · **1/1 integration test lulus** di
> emulator Android 15 (API 35) · cakupan baris **84,3%** (477/566 baris yang
> tercatat di `lcov`). Bukti mentah ada di [`screenshots/`](screenshots/README.md),
> rincian skenario di [`docs/testing-report.md`](docs/testing-report.md).

## Pemetaan 8 halaman modul

| # | Halaman modul | Yang dikerjakan di project ini | Bukti |
| --- | --- | --- | --- |
| 1 | Selamat datang | Menyiapkan project lanjutan Week 11 + `integration_test`; tidak ada fitur baru | `pubspec.yaml` |
| 2 | Strategi pengujian | Memetakan fitur catatan ke unit, widget, dan integrasi | tabel di bawah |
| 3 | Unit dan kasus tepi | Validasi judul, pencarian, sinkronisasi, state failure | `test/validate_note_test.dart`, `test/search_filter_test.dart`, `test/notes_state_failure_test.dart` |
| 4 | Async dan dependensi | Repository sebagai kontrak + fake untuk sukses/gagal | `test/helpers/fake_note_repository.dart` |
| 5 | Pengujian widget | Dialog tambah, halaman detail, pencarian, empty state | `test/add_note_dialog_test.dart`, `test/note_detail_page_test.dart` |
| 6 | Integrasi dan regresi | Alur tambah → detail → cari di emulator | `integration_test/app_test.dart` |
| 7 | Praktikum test suite | Skenario sukses, kasus tepi, kegagalan; unit + widget + integrasi | tabel skenario |
| 8 | Cakupan, tugas, refleksi | `flutter test --coverage`, ringkasan, temuan, refleksi | [`screenshots/coverage-summary.txt`](screenshots/coverage-summary.txt) |

## Jenis pengujian yang dipakai

| Jenis | Yang diperiksa | Contoh di aplikasi ini |
| --- | --- | --- |
| Unit | Logika/aturan tanpa UI | `AddNote` menolak judul kosong; `SearchNotes` abaikan kapitalisasi; `NotesNotifier` tidak mengubah state saat repository gagal |
| Widget | Tampilan dan interaksi widget | Dialog tambah menampilkan error; daftar menampilkan empty state; halaman detail menampilkan “Catatan tidak ditemukan” |
| Integrasi | Beberapa bagian bekerja bersama di perangkat | Menekan FAB → menyimpan catatan ke SQLite → membuka detail → mencari judul |

## Test baru minggu ini

| Berkas | Jumlah | Fokus |
| --- | ---: | --- |
| `test/add_note_dialog_test.dart` | 4 widget | Dialog awal, judul kosong, simpan sukses, repository gagal |
| `test/note_detail_page_test.dart` | 3 widget | Data tampil, catatan tidak ditemukan, error baca |
| `test/notes_state_failure_test.dart` | 3 unit | Fetch gagal → state error; add/delete gagal tidak mengubah state |
| `integration_test/app_test.dart` | 1 integrasi | Tambah catatan → buka detail → cari |

Total suite: **95 test unit/widget** (85 lama + 10 baru) dan **1 integration
test**.

## Rekap suite

| Berkas | Unit | Widget |
| --- | ---: | ---: |
| `validate_note_test.dart` | 5 | — |
| `search_filter_test.dart` | 6 | — |
| `note_test.dart` | 7 | — |
| `notes_state_test.dart` | 3 | — |
| `notes_state_failure_test.dart` | 3 | — |
| `provider_disposal_test.dart` | 2 | — |
| `chat_history_cap_test.dart` | 2 | — |
| `chat_notifier_test.dart` | 5 | — |
| `privacy_guard_test.dart` | 10 | — |
| `ask_assistant_test.dart` | 10 | — |
| `gemini_repository_test.dart` | 17 | — |
| `no_hardcoded_secrets_test.dart` | 2 | — |
| `widget_test.dart` | — | 1 |
| `search_widget_test.dart` | — | 4 |
| `rebuild_scope_test.dart` | — | 2 |
| `assistant_widget_test.dart` | — | 9 |
| `add_note_dialog_test.dart` | — | 4 |
| `note_detail_page_test.dart` | — | 3 |
| **Total** | **72** | **23** |

## Skenario yang diuji

| Kode | Skenario | Jenis | Harapan | Bukti |
| --- | --- | --- | --- | --- |
| U1 | Judul `"  Belanja  "` | Unit (sukses) | Disimpan sebagai `"Belanja"`, body ikut di-trim | `validate_note_test.dart` |
| U2 | Judul kosong / hanya spasi | Unit (kasus tepi) | `ValidationFailure`, repository **tidak** dipanggil | `validate_note_test.dart` |
| U3 | Repository gagal saat menyimpan | Unit (kegagalan) | Failure diteruskan, bukan dilempar | `validate_note_test.dart` |
| U4 | Fetch daftar gagal | Unit (kegagalan) | State error, bukan daftar kosong | `notes_state_failure_test.dart` |
| U5 | Hapus catatan gagal | Unit (kegagalan) | Item tetap ada di daftar | `notes_state_failure_test.dart` |
| W1 | Dialog tambah dibuka | Widget | Field tampil kosong | `add_note_dialog_test.dart` |
| W2 | Simpan dengan judul kosong | Widget (kasus tepi) | SnackBar muncul, dialog tetap terbuka, repository tidak dipanggil | `add_note_dialog_test.dart` |
| W3 | Simpan catatan valid | Widget (sukses) | Dialog tertutup, catatan muncul di daftar | `add_note_dialog_test.dart` |
| W4 | Simpan gagal di repository | Widget (kegagalan) | Pesan error tampil, dialog tetap terbuka | `add_note_dialog_test.dart` |
| W5 | Buka detail catatan | Widget | Judul, isi, dan badge dirty tampil | `note_detail_page_test.dart` |
| W6 | Detail untuk id yang tidak ada | Widget (kasus tepi) | “Catatan tidak ditemukan” | `note_detail_page_test.dart` |
| W7 | Gagal membaca detail | Widget (kegagalan) | Pesan error yang ramah | `note_detail_page_test.dart` |
| I1 | Tambah → detail → cari | Integrasi (alur utama) | Catatan tersimpan di SQLite dan ditemukan kembali | `integration_test/app_test.dart` |

## Fake repository

Pengujian unit/widget tidak memakai SQLite asli atau jaringan. Semua akses data
melewati kontrak `NoteRepository`, lalu diganti fake yang deterministik:

```dart
final repository = FakeNoteRepository(
  notes: [Note(id: 1, title: 'Belanja', updatedAt: DateTime(2026, 1, 1))],
  addFailure: const LocalFailure('Gagal menyimpan catatan: db penuh'),
);
```

Fake bisa disuntik kegagalan lewat `fetchFailure`, `fetchNoteFailure`,
`addFailure`, dan `deleteFailure`, sehingga jalur sukses **dan** gagal bisa
diuji tanpa database atau internet. Fake juga mencatat `addNoteCalls`,
`deleteNoteCalls`, `fetchNotesCalls`, dan `deletedIds`; counter ini dipakai
untuk membuktikan bahwa operasi tertentu tidak memicu query ulang.

## Integration test

`integration_test/app_test.dart` menjalankan aplikasi sungguhan di emulator:

1. Hapus `offline_notes.db` sebelum `app.main()` agar test tidak bergantung
   pada data lama.
2. Tekan FAB `add-note-fab`.
3. Isi judul dan isi, lalu tekan `save-note-button`.
4. Pastikan judul muncul di daftar.
5. Buka detail, pastikan judul dan isi tampil, lalu kembali.
6. Cari kata `integrasi`, pastikan catatan yang baru dibuat ditemukan.

Perintah dan hasil:

```bash
flutter test integration_test/app_test.dart -d emulator-5554
```

```text
00:00 +0: alur utama: tambah catatan, buka detail, lalu cari
00:11 +1: (tearDownAll)
00:16 +1: All tests passed!
```

## Cakupan pengujian

```bash
flutter test --coverage
./tool/coverage_summary.sh
```

Hasil:

| Cakupan | Hasil |
| --- | ---: |
| Baris total (22 file `lib/` yang tercatat) | **477/566 (84,3%)** |
| Use case notes (`AddNote`, `GetNotes`, `SearchNotes`, `SyncNotes`) | 100% |
| `note_detail_page.dart` / `note_tile.dart` | 100% |
| `add_note_dialog.dart` | 96,8% |
| `notes_providers.dart` | 95,7% |
| `notes_page.dart` | 73,8% |
| `note_repository_impl.dart` / `db.dart` | 0% |
| `api_key_store.dart` | 14,3% |

**Cara membaca angka ini dengan jujur:**

- Cakupan dihitung dari **baris yang tercatat di `lcov`**, bukan seluruh 32
  file `lib/`. `main.dart`, router, dan halaman pengaturan tidak muncul karena
  tidak diimpor oleh test unit/widget.
- `note_repository_impl.dart` dan `db.dart` 0% karena unit/widget test memakai
  fake. Jalur SQLite asli baru dijalankan oleh **integration test**, yang tidak
  masuk ke `flutter test --coverage`.
- `api_key_store.dart` bergantung pada `flutter_secure_storage`; bagian kecil
  yang bisa diuji tanpa plugin sudah tercakup, sisanya tidak.
- `lcov` Flutter tidak menyertakan data cabang (`BRF/BRH`), jadi yang dilaporkan
  hanya cakupan baris.
- Angka cakupan **bukan** target yang dikejar. Test tetap dinilai dari apakah
  ia gagal ketika perilaku rusak, bukan dari persentase.

Log mentah:
[`screenshots/coverage-summary.txt`](screenshots/coverage-summary.txt) dan
[`screenshots/coverage-per-file.txt`](screenshots/coverage-per-file.txt).

## Hasil pemeriksaan

```bash
dart format --set-exit-if-changed .
# Formatted 52 files (0 changed)

flutter analyze
# No issues found!

flutter test
# 00:14 +95: All tests passed!

flutter test integration_test/app_test.dart -d emulator-5554
# 00:16 +1: All tests passed!
```

Bukti lengkap:
[`screenshots/analyze-format.txt`](screenshots/analyze-format.txt),
[`screenshots/unit-widget-tests.txt`](screenshots/unit-widget-tests.txt),
[`screenshots/integration-test.txt`](screenshots/integration-test.txt).

## Temuan yang belum terselesaikan

1. **Jalur sukses SQLite belum punya unit test.** `NoteRepositoryImpl` baru
   dieksekusi oleh integration test; kalau integration test tidak dijalankan,
   cakupan barisnya 0%.
2. **`main.dart`, router, dan halaman pengaturan** belum diuji mendalam.
   Integration test menyentuh wiring utama, tetapi tidak memeriksa semua rute.
3. **`flutter_secure_storage`** tidak diuji karena butuh plugin platform;
   pengujiannya masih terbatas pada lapisan yang bisa dipisahkan.
4. **Gemini API nyata** tidak dipanggil di test; HTTP diuji dengan client palsu
   agar tidak bergantung jaringan dan tidak memakai kuota.
5. **Tidak ada branch coverage.** `lcov` dari Flutter hanya memberi data baris.
6. **Satu emulator saja.** Hasil integration test belum diverifikasi di
   perangkat fisik atau beberapa versi Android.
7. **Integration test hanya alur bahagia.** Jalur gagal ditutup di level unit
   dan widget; belum ada integration test untuk error database.
8. **Riverpod 3 mencoba ulang provider yang gagal.** Pada test fetch-failure,
   retry dimatikan agar state error bisa diamati; perilaku retry produksi tidak
   diuji khusus.

## Refleksi

**1. Bug apa yang paling mungkin terlewat tanpa pengujian yang ditulis?**

Bug yang paling mungkin terlewat adalah **kegagalan yang “terlihat sukses”**.
Contohnya: dialog tambah catatan menutup diri walaupun penyimpanan gagal,
daftar menghapus item dari layar padahal `DELETE` di database gagal, atau
provider berubah menjadi daftar kosong ketika pembacaan database error. Tanpa
test jalur gagal, UI tetap terlihat benar sampai pengguna kehilangan data.
Karena itu test baru tidak hanya menguji happy path, tetapi juga memastikan
state **tidak berubah** saat repository mengembalikan failure.

**2. Bagian mana yang perlu fake, dan bagaimana fake membuat pengujian lebih
konsisten?**

Akses data (`NoteRepository`) dan HTTP (`AiAssistantRepository`) perlu fake.
Keduanya adalah batas yang lambat, berubah-ubah, dan bergantung lingkungan.
Dengan `FakeNoteRepository`, test bisa menentukan daftar catatan, menghitung
pemanggilan, dan menyuntik kegagalan tanpa SQLite. Dengan fake HTTP, respons
401/429/500, body rusak, dan timeout bisa diuji tanpa jaringan. Hasilnya
deterministik: test tidak gagal karena database berisi data lama atau karena
kuota API habis.

**3. Apa perbedaan nilai pengujian widget dan integrasi pada fitur ini?**

Widget test memberi umpan balik cepat untuk **satu layar**: apakah dialog
menampilkan validasi, apakah empty state muncul, apakah tombol memanggil aksi
yang benar. Integrasi memberi keyakinan pada **sambungan antar bagian**:
`main()` → router → `NotesPage` → dialog → `NotesNotifier` → `NoteRepository`
→ SQLite → halaman detail. Widget test bisa lulus walaupun wiring database
salah; integration test bisa menangkap kesalahan itu, tetapi lebih lambat dan
hanya dijalankan di perangkat. Keduanya saling melengkapi, bukan pengganti.

## Menjalankan

```bash
flutter pub get

dart format --set-exit-if-changed .
flutter analyze
flutter test

flutter test --coverage
./tool/coverage_summary.sh

# Butuh emulator/perangkat aktif
flutter test integration_test/app_test.dart -d emulator-5554
```

## Struktur penting

```text
lib/                              # aplikasi Week 11 + Key untuk test
test/
├── helpers/fake_note_repository.dart   # fake sukses + failure
├── add_note_dialog_test.dart           # BARU — 4 widget test
├── note_detail_page_test.dart          # BARU — 3 widget test
├── notes_state_failure_test.dart       # BARU — 3 unit test
└── …                                   # 85 test lama
integration_test/
└── app_test.dart                       # BARU — alur utama
tool/
└── coverage_summary.sh                 # ringkasan lcov tanpa paket tambahan
docs/
└── testing-report.md                   # matriks skenario & analisis
screenshots/                            # log mentah hasil perintah
```

## Dokumentasi

- [`docs/testing-report.md`](docs/testing-report.md) — matriks skenario,
  desain fake, analisis coverage, dan batasan.
- [`screenshots/README.md`](screenshots/README.md) — inventaris bukti dan
  kondisi pengukuran.
- [`screenshots/unit-widget-tests.txt`](screenshots/unit-widget-tests.txt) —
  output `flutter test`.
- [`screenshots/integration-test.txt`](screenshots/integration-test.txt) —
  output integration test.
- [`screenshots/coverage-summary.txt`](screenshots/coverage-summary.txt) —
  ringkasan cakupan.
