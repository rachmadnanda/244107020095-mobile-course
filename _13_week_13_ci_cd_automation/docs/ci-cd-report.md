# Laporan CI/CD — Week 13

Dokumen ini melengkapi [`../README.md`](../README.md). Isinya: alur pipeline,
keputusan desain, analisis kegagalan pertama, perbandingan lingkungan, dan
risiko keamanan yang masih terbuka.

## 1. Lingkungan

| Komponen | Nilai |
| --- | --- |
| Repository | `rachmadnanda/244107020095-mobile-course` |
| Branch utama | `main` |
| Runner | `ubuntu-latest` (GitHub-hosted) |
| Flutter di CI | **3.50.1** stable (dipatok) |
| Flutter di lokal | 3.47.2 stable |
| Folder aplikasi | `_13_week_13_ci_cd_automation` |
| Versi aplikasi | `1.0.1+2` |
| Tag rilis | `v1.0.1` |

Perbedaan versi SDK antara lokal dan CI bukan detail sepele — justru itu
penyebab kegagalan run pertama (bagian 5).

Catatan `pubspec.lock`: menjalankan `flutter pub get` dengan 3.47.2 dan 3.50.1
menghasilkan `test_api` yang berbeda (0.7.12 vs 0.7.14). Lock yang di-commit
adalah hasil 3.47.2; runner 3.50.1 menyelesaikannya sendiri saat `pub get` dan
run #2 tetap hijau. Ini konsekuensi wajar dari SDK yang berbeda, bukan
ketidakstabilan dependency.

## 2. Alur pipeline

```
push / pull_request / workflow_dispatch
        │
        ▼
  actions/checkout@v4              ambil source
        │
        ▼
  subosito/flutter-action@v2       pasang Flutter 3.50.1 + cache
        │
        ▼
  flutter pub get                  dependensi
        │
        ▼
  dart format --set-exit-if-changed
        │  gagal? → stop, job merah
        ▼
  flutter analyze --fatal-infos
        │  gagal? → stop, job merah
        ▼
  flutter test --coverage
        │  gagal? → stop, job merah
        ▼
  flutter build apk --release
        │
        ▼
  flutter build appbundle --release
        │
        ▼
  actions/upload-artifact@v4       android-builds (7 hari)
```

Prinsipnya: **pemeriksaan murah lebih dulu**. Format dan analisis selesai dalam
hitungan detik, sementara build memakan beberapa menit. Kalau test gagal, build
tidak perlu dijalankan sama sekali — itulah yang terjadi pada run #1 (step
build otomatis `skipped`).

## 3. Keputusan desain

### Trigger

| Event | Alasan |
| --- | --- |
| `push` ke `main` | Setiap perubahan yang masuk branch utama diperiksa |
| `pull_request` ke `main` | Perubahan diperiksa **sebelum** merge |
| `workflow_dispatch` | Bisa dijalankan manual untuk menguji pipeline |

### Permission dan concurrency

```yaml
permissions:
  contents: read
```

Job ini hanya membaca kode. Tidak ada langkah yang menulis ke repository, jadi
`contents: read` sudah cukup dan lebih aman daripada default.

```yaml
concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true
```

Kalau ada dua push berurutan ke branch yang sama, run lama dibatalkan. Ini
menghemat menit runner dan mencegah hasil run lama membingungkan.

### Versi Flutter dipatok

Codelab memakai `channel: stable`. Saya menggantinya dengan
`flutter-version: 3.50.1` karena `stable` bergerak setiap rilis. Run pertama
membuktikan biayanya: SDK naik ke 3.50.1 di tengah pengerjaan dan membuat job
merah tanpa ada perubahan kode. Mematok versi membuat hasil dapat
direproduksi; menaikkannya menjadi keputusan sadar, bukan kejadian tak terduga.

### Path artefak

Step `uses:` **tidak** mengikuti `defaults.run.working-directory`. Karena itu
path artefak ditulis lengkap dari root repository:

```yaml
path: |
  _13_week_13_ci_cd_automation/build/app/outputs/flutter-apk/app-release.apk
  _13_week_13_ci_cd_automation/build/app/outputs/bundle/release/app-release.aab
```

`if-no-files-found: error` membuat job gagal kalau artefak tidak ada — lebih
baik gagal terang-terangan daripada "sukses" tanpa file.

### APK dan AAB

| Format | Kegunaan |
| --- | --- |
| APK | Instalasi langsung, uji internal, dibagikan ke penguji |
| AAB | Format distribusi Google Play (Play menangani pembagian per perangkat) |

Keduanya dibangun karena kebutuhannya berbeda; AAB tidak bisa dipasang langsung
di perangkat.

## 4. Hasil run

| | Run #1 | Run #2 | Run #3 | Run #4 | Run #5 |
| --- | --- | --- | --- | --- | --- |
| URL | `45547458858` | `45553405020` | `45557977150` | `45558995522` | `45559999577` |
| Commit | `79284c6` | `a716bb4` | `2cec604` | `12769ee` | `55716ec` |
| Event | push ke `main` | push ke `main` | push ke `main` | push ke `main` | push ke `main` |
| Hasil | ❌ failure | ✅ success | ✅ success | ✅ success | ✅ success |
| Durasi | 1m 9s | 7m 14s | 5m 12s | 6m 0s | 4m 29s |
| Step gagal | Analisis statis | — | — | — | — |
| Artefak | – | 72,6 MB | 72,6 MB | 72,6 MB | 72,6 MB |

Run #3–#5 membuktikan hal yang mudah terlewat: commit yang hanya mengubah
Markdown tetap menjalankan format, analisis, 95 test, dan build. Pipeline tidak
membedakan "commit penting" dan "commit dokumentasi".

Karena setiap commit memicu run baru, commit dokumentasi terakhir memakai
penanda `[skip ci]`. Itu keputusan sadar untuk menghentikan rantai run yang
hanya mengubah Markdown — bukan untuk menghindari pemeriksaan, karena kode
aplikasi tidak berubah pada commit tersebut.

Yang penting bukan nomor run terakhir, melainkan bahwa **setelah `a716bb4`
tidak ada lagi run yang merah**.

Step pada run #2, semuanya hijau:

| # | Step | Status |
| --- | --- | --- |
| 1 | Set up job | ✅ |
| 2 | Checkout | ✅ |
| 3 | Siapkan Flutter | ✅ |
| 4 | Ambil dependensi | ✅ |
| 5 | Periksa format | ✅ |
| 6 | Analisis statis | ✅ |
| 7 | Jalankan test | ✅ |
| 8 | Build APK | ✅ |
| 9 | Build App Bundle | ✅ |
| 10 | Unggah artefak | ✅ |

Artefak `android-builds`: 72,6 MB, SHA-256
`f0329404ad8d91f5ec04f9dde77ff12829ae2e7deed9e7c8962dfddeb1bc4b15`.

## 5. Analisis kegagalan pertama

### Gejala

Run #1 gagal di step **Analisis statis** setelah 1m 4s. Step berikutnya
(`Jalankan test`, `Build APK`, `Build App Bundle`, `Unggah artefak`) berstatus
`skipped`.

### Reproduksi

Log detail GitHub Actions membutuhkan login, dan saya tidak memilikinya di
lingkungan ini. Jadi kegagalan direproduksi secara lokal dengan mengunduh versi
SDK yang dipakai runner:

```bash
curl -L -o flutter_3501.tar.xz \
  https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.50.1-stable.tar.xz
tar -xf flutter_3501.tar.xz
./flutter/bin/flutter --version    # Flutter 3.50.1 • Dart 3.14.0
```

Salinan project dijalankan dengan SDK tersebut:

```bash
flutter analyze --fatal-infos
# 15 issues found
```

### Akar masalah

Flutter 3.50.1 menambahkan anotasi `@Deprecated` pada library
`package:flutter/material.dart`:

> *'Use package:material_ui/material_ui.dart instead. This feature was
> deprecated after v3.47.0-0.0.pre.'*

Lima belas file mengimpor `package:flutter/material.dart`. Semuanya menghasilkan
`info • deprecated_member_use`, dan `--fatal-infos` mengubah `info` menjadi
kegagalan.

Perbandingan langsung:

| Perintah | Flutter 3.47.2 (lokal) | Flutter 3.50.1 (CI) |
| --- | --- | --- |
| `flutter analyze` | No issues found | 15 issues |
| `flutter analyze --fatal-infos` | No issues found | **gagal** |

### Perbaikan

1. **Migrasi ke `material_ui`.** Tambah `material_ui: ^1.11.1` (paket resmi
   Flutter, `environment: flutter >=3.47.0`) dan ganti import di 15 file:

   ```dart
   // sebelum
   import 'package:flutter/material.dart';
   // sesudah
   import 'package:material_ui/material_ui.dart';
   ```

2. **Naikkan AGP 9.1.0 → 9.1.1.** Setelah analisis lolos, build gagal dengan:

   > *Your project's Android Gradle Plugin version (9.1.0) is lower than
   > Flutter's minimum supported version of 9.1.1.*

   Ini masalah kedua yang juga hanya muncul dengan Flutter 3.50.1.

3. **Patok `flutter-version: 3.50.1`** di workflow.

### Urutan verifikasi

Migrasi diuji di salinan terpisah sebelum menyentuh repository:

| Langkah | Hasil |
| --- | --- |
| `flutter pub get` (3.50.1) | Changed 1 dependency |
| `flutter analyze --fatal-infos` | No issues found |
| `flutter test` | 95/95 lulus |
| `flutter build apk --release` | 52,1 MB (setelah AGP dinaikkan) |
| `flutter build appbundle --release` | 51,8 MB |

Baru setelah semua hijau, perubahan diterapkan ke repository dan di-push.

## 6. Versioning

| Item | Nilai |
| --- | --- |
| Sebelum | `1.0.0+1` (Week 12) |
| Sesudah | `1.0.1+2` |
| Tag | `v1.0.1` |

Format `versi+build`:

- `1.0.1` — versi aplikasi yang dilihat pengguna.
- `2` — build number; harus naik untuk setiap unggahan baru ke Play Store,
  walaupun versi aplikasinya sama.

Alasan memilih **patch**: tidak ada fitur baru dan tidak ada perubahan yang
merusak kompatibilitas. Isinya migrasi import dan kenaikan AGP — perbaikan
internal.

Tag `v1.0.1` dibuat **setelah** run #2 hijau, sehingga tag menunjuk commit yang
sudah lolos pemeriksaan. Ini penting: tag pada commit yang belum terverifikasi
membuat source, log pipeline, dan artefak tidak bisa dicocokkan.

## 7. Rahasia dan konfigurasi

Prinsip yang dipakai:

| Jenis data | Tempat yang benar | Catatan |
| --- | --- | --- |
| Token, password, keystore | GitHub Actions Secrets | Tidak pernah masuk repository |
| URL API, nama environment | File konfigurasi biasa | Konfigurasi publik, bukan credential |
| Nilai `--dart-define` | Boleh di workflow | **Bukan** secret: bisa diekstrak dari APK |
| API key Gemini di aplikasi | Input pengguna → `flutter_secure_storage` | Bukan konstanta di kode |

Workflow Week 13 **tidak memakai secret sama sekali**. Itu disengaja: build
debug-signed tidak butuh kredensial, sehingga tidak ada yang bisa bocor.

Test `test/no_hardcoded_secrets_test.dart` menjaga agar API key tidak tertulis
di `lib/`, dan test itu ikut berjalan di CI.

## 8. Risiko keamanan yang masih terbuka

| Risiko | Dampak | Mitigasi yang belum dilakukan |
| --- | --- | --- |
| APK/AAB ditandatangani **debug key** | Tidak layak publikasi; bisa ditandatangani ulang siapa pun | Keystore rilis + Secrets, injeksi hanya di workflow rilis |
| Keystore produksi belum ada | Belum bisa rilis resmi | Ikuti panduan signing Flutter; jangan taruh di workflow PR |
| Artefak kedaluwarsa 7 hari | Bukti hilang setelah sepekan | Arsipkan di luar GitHub |
| Action dipin ke **tag**, bukan SHA | Tag bisa dipindahkan pemilik action | Pin ke commit SHA |
| Belum ada branch protection | PR merah tetap bisa di-merge | Aktifkan required check `test-and-build` |
| Log publik | Siapa pun bisa membaca log | Jangan cetak secret; `--dart-define` bukan secret |
| Build tanpa `--obfuscate` | Nama kelas/simbol mudah dibaca dari APK | Tambahkan `--obfuscate --split-debug-info` untuk rilis |

## 9. Batasan

1. **Integration test tidak jalan di CI** — runner tidak punya emulator; hanya
   95 test unit/widget yang dijalankan.
2. **Peringatan Node.js 20** pada `actions/checkout@v4` (dipaksa jalan di
   Node.js 24). Belum mengganggu.
3. **Gradle/AGP/Kotlin akan segera tidak didukung** — peringatan build lokal:
   Gradle ≥ 9.5.0, AGP ≥ 9.3.1, Kotlin ≥ 2.4.20.
4. **Satu varian build** — belum ada flavor, `--split-per-abi`, atau build iOS.
5. **Cakupan tidak diunggah** — `--coverage` dijalankan tetapi `lcov` tidak
   disimpan sebagai artefak.
6. **`ci.yml` lama** (Week 8) diperbaiki tetapi belum diverifikasi lewat run,
   karena hanya terpicu `pull_request`.

## 10. Refleksi

**Masalah apa yang ditemukan otomatis sebelum perubahan di-merge?**
Dua masalah yang tidak terlihat di laptop: 15 import `material.dart` yang sudah
deprecated di Flutter 3.50.1, dan AGP 9.1.0 di bawah minimum Flutter 3.50.1.
Keduanya akan membuat build release gagal. CI juga memastikan 95 test tetap
dijalankan pada setiap push, termasuk commit yang tampaknya hanya dokumentasi.

**Informasi apa yang dibutuhkan untuk menyelidiki build yang gagal?**
Nama step yang gagal, commit SHA pemicu, versi SDK runner, dan pesan galat.
Karena log detail butuh login, saya mereproduksi kegagalan dengan mengunduh
Flutter 3.50.1 lokal — cara itu memberi pesan lengkap tanpa menebak. Tanpa versi
SDK dipatok, kegagalan seperti ini sulit direproduksi.

**Bagian mana yang masih perlu persetujuan manual sebelum rilis?**
Signing key, keputusan versi dan tag, isi changelog, dan pengujian di perangkat
fisik. CI membuktikan kode lolos format, analisis, test, dan bisa dibangun —
bukan bahwa aplikasi layak dipublikasikan.

## 11. Reproduksi

```bash
cd _13_week_13_ci_cd_automation
flutter pub get
dart format --output=none --set-exit-if-changed .
flutter analyze --fatal-infos
flutter test --coverage
flutter build apk --release
flutter build appbundle --release
```

Memicu pipeline: push ke `main`, buka PR ke `main`, atau **Actions → Flutter CI
→ Run workflow**.
