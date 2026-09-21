# Mini Project - REST API Posts

Aplikasi daftar data posts dari JSONPlaceholder sebagai tugas minggu 4 networking REST API.

## Tujuan

Menerapkan alur data Flutter yang terpisah dan mudah diuji: UI -> Riverpod -> repository -> Dio -> REST API.

## Fitur utama

- Mengambil posts dari `https://jsonplaceholder.typicode.com/posts`.
- Dio terpusat dengan base URL, timeout 10 detik, header JSON, dan interceptor logging.
- Model `Post.fromJson` aman terhadap field hilang atau bernilai null.
- State loading, error dengan tombol retry, empty, dan success.
- Infinite scroll dengan 10 item per halaman melalui `_page` dan `_limit`.
- Guard request ganda melalui `isLoadingMore`.
- Unit test model/error mapping dan provider dengan repository palsu.
- AI Challenge dan refleksi teknis tersedia di `docs/`.

## Stack teknologi

- Flutter dan Dart 3
- flutter_riverpod
- Dio
- go_router
- JSONPlaceholder
- flutter_test

## Cara menjalankan

Dari folder ini:

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

## Struktur

```text
lib/       source aplikasi, data layer, repository, provider, dan UI
 test/     unit test model, error mapping, dan provider
 docs/     prompt AI, evaluasi hasil, serta refleksi
 screenshots/ tempat menyimpan bukti UI
```

## Hasil yang dicapai

Aplikasi berhasil mengambil dan menampilkan data posts dengan arsitektur repository + Riverpod. Error dari repository diteruskan provider sebagai `AsyncError` untuk alur provider biasa, sedangkan notifier pagination menyimpan error dan menampilkannya pada UI. Test model dan provider palsu lulus tanpa bergantung pada jaringan.
