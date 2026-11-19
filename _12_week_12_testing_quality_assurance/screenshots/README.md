# Bukti — Week 12

Folder ini berisi dua bentuk bukti dari eksekusi yang sama pada 19 November
2026:

- **`.png`** — tangkapan layar terminal sungguhan (jendela `foot` di sesi
  Wayland), diambil dengan `grim` setelah perintah selesai. Tidak ada gambar
  yang disusun atau diedit; yang terlihat adalah keluaran apa adanya.
- **`.txt`** — log teks mentah yang bisa dibaca, dicari, dan dibandingkan
  (diambil dengan `tee`).

## Daftar berkas

| Berkas | Isi |
| --- | --- |
| `01-format-analyze.png` | `dart format --set-exit-if-changed .` dan `flutter analyze` |
| `02-flutter-test.png` | `flutter test --reporter expanded` — 95 test lulus |
| `03-integration-test.png` | `flutter test integration_test/app_test.dart -d emulator-5554` — 1 test lulus |
| `04-coverage.png` | `flutter test --coverage` + `./tool/coverage_summary.sh` — 477/566 (84,3%) |
| `analyze-format.txt` | Log teks format + analyze |
| `unit-widget-tests.txt` | Log teks lengkap `flutter test` (95 test) |
| `integration-test.txt` | Log teks integration test |
| `coverage-run.txt` | Log teks `flutter test --coverage` |
| `coverage-summary.txt` | Ringkasan cakupan baris |
| `coverage-per-file.txt` | Cakupan per file dari `coverage/lcov.info` |

Semua angka bisa diverifikasi ulang dengan perintah di
[`../README.md`](../README.md). Durasi di tangkapan layar berasal dari eksekusi
saat gambar diambil; log teks berasal dari eksekusi lain pada hari yang sama,
jadi detiknya bisa berbeda walaupun jumlah test yang lulus sama.

## Kondisi pengujian

- Waktu: 19 November 2026.
- Flutter: 3.47.2 stable.
- Perangkat integration test: emulator `sdk_gphone64_x86_64`,
  Android 15 (API 35), 1080×2280 @ 440 dpi.
- Build integration test: debug.
- Data: SQLite lokal; database `offline_notes.db` dihapus sebelum test.
- Jaringan: tidak dipakai (repository/HTTP palsu).
- Perintah unit/widget dijalankan di host, bukan di perangkat.

## Cara memverifikasi

```bash
# Dari folder _12_week_12_testing_quality_assurance
flutter test
flutter test --coverage
./tool/coverage_summary.sh
flutter test integration_test/app_test.dart -d emulator-5554
```

Hasil yang diharapkan:

```text
00:11 +95: All tests passed!          # unit + widget
01:19 +1: All tests passed!           # integration (termasuk build)
Baris : 477/566 (84.3%)               # coverage
```

## Catatan tentang cakupan

`coverage/lcov.info` hanya mencakup baris yang dieksekusi oleh test unit dan
widget. Integration test tidak termasuk dalam lcov, sehingga
`note_repository_impl.dart` dan `db.dart` tampil 0% walaupun alur SQLite
benar-benar dijalankan oleh integration test. Ini dijelaskan di
[`../README.md`](../README.md) dan
[`../docs/testing-report.md`](../docs/testing-report.md).
