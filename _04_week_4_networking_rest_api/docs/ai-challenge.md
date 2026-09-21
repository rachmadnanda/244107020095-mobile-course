# AI Challenge — Comments API

## 1. Tujuan

Membuat repository layer Flutter untuk mengambil data komentar dari
JSONPlaceholder menggunakan Dio dan flutter_riverpod.

Endpoint yang digunakan:

`GET /comments?postId={id}`

## 2. Prompt AI

Prompt yang digunakan:

> Buatkan repository layer Flutter untuk endpoint GET /comments?postId={id}
> dari JSONPlaceholder menggunakan Dio + flutter_riverpod.
> Requirements:
> - Model Comment dengan fromJson aman null (postId, id, name, email, body).
> - CommentRepository dengan method fetchComments(postId) + timeout 10 detik.
> - AsyncNotifierProvider dengan penanganan error otomatis (AsyncError)
>   dan fungsi pesan error ramah pengguna untuk timeout, connection error,
>   404, dan 500.
> - Satu unit test untuk fromJson dengan field yang hilang.
> Jelaskan setiap bagian kode dalam komentar.

## 3. Implementasi

Implementasi terdiri dari:

- `lib/data/models/comment.dart`
- `lib/data/repositories/comment_repository.dart`
- `lib/data/comment_provider.dart`
- `test/comment_test.dart`

### Model Comment

Model `Comment` memiliki field:

- `postId`
- `id`
- `name`
- `email`
- `body`

Method `fromJson` menggunakan null-aware casting dan nilai default
agar aplikasi tetap aman ketika field JSON hilang atau bernilai null.

### CommentRepository

Repository bertanggung jawab mengambil data komentar dari API.

Endpoint:

`GET /comments?postId={id}`

Request menggunakan Dio dan timeout 10 detik.

### AsyncNotifierProvider

`commentProvider` menggunakan `AsyncNotifierProvider.family`.

Provider menerima `postId` sebagai parameter sehingga setiap post dapat
mengambil komentar berdasarkan ID masing-masing.

Status loading dan error ditangani menggunakan `AsyncValue`.

### Error Handling

Pesan error dibuat lebih ramah pengguna untuk beberapa kondisi:

- connection timeout
- send timeout
- receive timeout
- connection error
- HTTP 404
- HTTP 500
- error jaringan lainnya

## 4. Pengujian

Unit test dibuat untuk:

1. `Comment.fromJson` dengan field yang hilang.
2. `Comment.fromJson` dengan nilai null.
3. Pesan error timeout.
4. Pesan error HTTP 404.
5. Pesan error HTTP 500.

## 5. Verifikasi

Perintah yang digunakan:

```bash
flutter analyze
flutter test
```
Hasil yang diharapkan:

No issues found!

dan seluruh unit test berhasil dijalankan.

## 6. Evaluasi Implementasi AI

Implementasi diperiksa kembali terhadap requirement AI Challenge.

Hasil pemeriksaan:

 Model Comment tersedia.
 fromJson aman terhadap field yang hilang.
 CommentRepository tersedia.
 Endpoint /comments?postId={id} digunakan.
 Timeout 10 detik digunakan.
 AsyncNotifierProvider.family digunakan.
 Error timeout ditangani.
 Connection error ditangani.
 HTTP 404 ditangani.
 HTTP 500 ditangani.
 Unit test field yang hilang tersedia.
 Edge case nilai null diuji.