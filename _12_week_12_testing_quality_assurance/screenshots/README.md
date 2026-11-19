# Bukti — Week 12

Semua berkas di folder ini adalah **output mentah** dari perintah yang
dijalankan pada 19 November 2026. Tidak ada nilai yang diubah setelah
pengambilan.

## Daftar berkas

| Berkas | Isi |
| --- | --- |
| `analyze-format.txt` | Output `dart format --set-exit-if-changed .` dan `flutter analyze` |
| `unit-widget-tests.txt` | Output lengkap `flutter test` (95 test) |
| `integration-test.txt` | Output `flutter test integration_test/app_test.dart` di emulator |
| `coverage-run.txt` | Output `flutter test --coverage` |
| `coverage-summary.txt` | Ringkasan cakupan baris |
| `coverage-per-file.txt` | Cakupan per file dari `coverage/lcov.info` |

Bukti berbentuk **log teks**, bukan screenshot UI, karena objek yang diuji
adalah perilaku test dan hasil perintah. Setiap angka bisa diverifikasi ulang
dengan perintah di [`../README.md`](../README.md).

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
00:14 +95: All tests passed!          # unit + widget
00:16 +1: All tests passed!           # integration (termasuk build)
Baris : 477/566 (84.3%)               # coverage
```

## Catatan tentang cakupan

`coverage/lcov.info` hanya mencakup baris yang dieksekusi oleh test unit dan
widget. Integration test tidak termasuk dalam lcov, sehingga
`note_repository_impl.dart` dan `db.dart` tampil 0% walaupun alur SQLite
benar-benar dijalankan oleh integration test. Ini dijelaskan di
[`../README.md`](../README.md) dan
[`../docs/testing-report.md`](../docs/testing-report.md).
