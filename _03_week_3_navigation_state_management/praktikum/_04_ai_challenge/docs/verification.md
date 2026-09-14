# AI Challenge — Verification

## 1. Static Analysis

Perintah yang digunakan:

```bash
flutter analyze
```

Hasil:

```text
No issues found!
```

## 2. Unit Test

Perintah yang digunakan:

```bash
flutter test
```

Hasil:

```text
All tests passed.
```

## 3. Functional Verification

Aplikasi diuji dengan menjalankan:

```bash
flutter run
```

Hasil pengujian:

* Saat data sedang diproses, aplikasi menampilkan loading indicator.
* Jika proses berhasil, aplikasi menampilkan data statistik.
* Jika terjadi error, aplikasi menampilkan pesan error.
* Tombol `Coba Lagi` dapat digunakan untuk mencoba mengambil data kembali.
* Delay sekitar 2 detik digunakan untuk mensimulasikan proses asynchronous.
* Kemungkinan error sebesar 30% digunakan untuk mensimulasikan kondisi kegagalan.

## 4. Kesimpulan

Implementasi AI Challenge telah diuji menggunakan static analysis, unit test, dan pengujian langsung pada aplikasi.

Implementasi telah memenuhi requirement utama dari praktikum mengenai `AsyncNotifier`, `AsyncValue`, loading state, error state, success state, dan retry.
