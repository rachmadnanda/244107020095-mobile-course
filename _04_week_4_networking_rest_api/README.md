# Week 4 - Networking REST API
## Rachmad Febriananda_244107020095

Laporan codelab Pemrograman Mobile minggu 4. Project ini membangun aplikasi
daftar posts dari JSONPlaceholder menggunakan Dio, repository pattern, dan
Riverpod.

## Struktur Project

```text
_04_week_4_networking_rest_api/
├── README.md
├── lib/
├── test/
├── docs/
├── screenshots/
└── 04-week-4-networking-rest-api/
		├── README.md
		├── lib/
		├── test/
		├── docs/
```

Folder `04-week-4-networking-rest-api/` adalah salinan mini project portfolio
yang dibuat setelah tahapan praktikum. Laporan utama ini mencakup seluruh
proses pembelajaran dan implementasi pada project minggu 4.

## Praktikum 1 - Dio dan Model Data

Praktikum pertama membuat model `Post` dan client Dio terpusat.

Implementasi utama:

- [`lib/data/models/post.dart`](lib/data/models/post.dart) berisi model
	`Post`, `fromJson`, dan `toJson`.
- [`lib/data/api_client.dart`](lib/data/api_client.dart) berisi base URL
	JSONPlaceholder, timeout 10 detik, header JSON, dan `LogInterceptor`.
- [`lib/data/repositories/post_repository.dart`](lib/data/repositories/post_repository.dart)
	menjadi pintu akses data dari API.

`Post.fromJson` menggunakan cast defensif seperti `(json['id'] as num?)?.toInt() ?? 0`
dan `json['title'] as String? ?? ''`, sehingga field yang hilang atau bernilai
null tidak langsung menyebabkan aplikasi crash.

Commit tahap ini: `9160255 add week 4 praktikum 1 dio and data model`.

## Praktikum 2 - Provider dan Error Handling

Praktikum kedua mengekspos repository melalui `AsyncNotifierProvider`.

Implementasi utama:

- [`lib/data/providers.dart`](lib/data/providers.dart) menyediakan Dio,
	repository, `postListProvider`, refresh, serta helper testing.
- [`lib/data/network_errors.dart`](lib/data/network_errors.dart) memetakan
	`DioException` menjadi pesan yang lebih ramah pengguna.
- [`lib/pages/post_list_page.dart`](lib/pages/post_list_page.dart) menampilkan
	loading, error dengan tombol retry, empty, dan success.

Exception dari `build()` provider otomatis menjadi `AsyncError`, sehingga UI
tidak perlu melakukan try/catch untuk setiap pembacaan provider.

Commit tahap ini: `9dfdb10 praktikum 2, provider dan error handling`.

## Praktikum 3 - Pagination Infinite Scroll

Praktikum ketiga menambahkan pagination server menggunakan query `_page` dan
`_limit` dengan 10 item per halaman.

Implementasi utama:

- `PostRepository.fetchPostsPage()` mengambil data per halaman.
- [`lib/data/paged_posts.dart`](lib/data/paged_posts.dart) menyimpan items,
	page, `isLoadingMore`, `hasMore`, dan error.
- [`lib/pages/paged_post_page.dart`](lib/pages/paged_post_page.dart)
	menggunakan `ScrollController` dan memuat halaman berikutnya 200 pixel
	sebelum ujung list.

Guard `isLoadingMore` mencegah request ganda ketika listener scroll terpanggil
berulang. Data lama tetap ditampilkan apabila request halaman berikutnya gagal.

Commit tahap ini: `bf5f329 praktikum 3 pagination`.

## AI Challenge

AI Challenge membuat fitur comments dari endpoint
`GET /comments?postId={id}` menggunakan Dio dan Riverpod.

Prompt, implementasi, checklist verifikasi, test, dan evaluasi hasil AI
didokumentasikan di [`docs/ai-challenge.md`](docs/ai-challenge.md).

Implementasi terkait:

- [`lib/data/models/comment.dart`](lib/data/models/comment.dart)
- [`lib/data/repositories/comment_repository.dart`](lib/data/repositories/comment_repository.dart)
- [`lib/data/comment_provider.dart`](lib/data/comment_provider.dart)
- [`test/comment_test.dart`](test/comment_test.dart)

Hasil verifikasi AI:

- Model aman terhadap field hilang dan nilai null.
- UI tidak memanggil Dio secara langsung.
- Timeout, connection error, HTTP 404, dan HTTP 500 memiliki pesan khusus.
- Konfigurasi Dio tetap terpusat.
- Edge case null ditambahkan ke test.

Commit tahap ini: `d04285d ai-challenge`.

## Refactoring dan Testing

Refactoring yang dilakukan:

1. Mengekstrak baris post menjadi [`lib/pages/post_tile.dart`](lib/pages/post_tile.dart).
2. Memindahkan `friendlyErrorMessage` ke
	 [`lib/data/network_errors.dart`](lib/data/network_errors.dart).
3. Menambahkan detail post dengan GoRouter pada route `/post/:id` melalui
	 [`lib/pages/post_detail_page.dart`](lib/pages/post_detail_page.dart).
4. Menambahkan test model, error mapping, provider sukses, dan provider error
	 dengan repository palsu di [`test/post_test.dart`](test/post_test.dart).

Test menggunakan `ProviderContainer` dan fake repository, sehingga tidak
melakukan request HTTP sungguhan.

Commit tahap ini: `189ba1d reafctoring & testing`.

## Mini Project / Industry Challenge

Mini project portfolio tersedia di folder
[`04-week-4-networking-rest-api/`](04-week-4-networking-rest-api/).

Fitur yang dicapai:

- Daftar posts dari JSONPlaceholder melalui repository dan Riverpod.
- Dio terpusat dengan base URL, timeout, dan interceptor logging.
- Model `fromJson` aman null.
- Loading, error + retry, empty, dan success state.
- Infinite scroll dengan 10 item per halaman.
- Guard request ganda saat pagination.
- Test model/error mapping, provider fake repository, AI Challenge, dan
	widget smoke test.

Dokumentasi mini project:

- [`04-week-4-networking-rest-api/README.md`](04-week-4-networking-rest-api/README.md)
- [`04-week-4-networking-rest-api/docs/ai-challenge.md`](04-week-4-networking-rest-api/docs/ai-challenge.md)
- [`04-week-4-networking-rest-api/docs/refleksi.md`](04-week-4-networking-rest-api/docs/refleksi.md)

## Refleksi

### Mengapa UI dilarang memanggil Dio langsung?

UI seharusnya mengatur tampilan dan interaksi, bukan detail HTTP, parsing JSON,
timeout, atau pemetaan error. Jika UI memanggil Dio langsung, kode menjadi
berulang, sulit diuji tanpa jaringan, dan perubahan endpoint menyebar ke banyak
widget. Repository menjadi satu batas yang jelas untuk data dan error.

### Kapan pagination client-side cukup?

Pagination client-side cukup untuk dataset kecil yang sudah tersedia di memori,
misalnya data lokal. Untuk dataset besar atau yang terus berubah, pagination
server dengan `_page` dan `_limit` lebih tepat karena mengurangi transfer data,
memori, dan waktu tunggu.

### Bagaimana exception menjadi AsyncError?

`AsyncNotifier.build` mengembalikan Future dari repository. Riverpod menangkap
exception Future tersebut dan mengubahnya menjadi `AsyncError`. Try/catch
eksplisit tetap dibutuhkan saat melakukan retry manual, menggabungkan halaman
berikutnya, atau mempertahankan data lama ketika request lanjutan gagal.

### Bagian hasil AI yang diperbaiki

Hasil awal AI untuk pagination belum memiliki state loading awal dan sempat
menghasilkan fragmen `ListView.builder` yang tidak valid. Perbaikannya adalah
membuat state `isLoading`, `isLoadingMore`, `hasMore`, dan error lebih eksplisit,
membersihkan widget builder, serta menambahkan empty state. Perbaikan ini
dilakukan agar empat state UI dapat dibedakan dan source lulus analyzer.

## Cara Menjalankan

Project utama:

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

Mini project portfolio:

```bash
cd 04-week-4-networking-rest-api
flutter pub get
flutter analyze
flutter test
flutter run -d chrome
```

## Hasil Verifikasi

- `flutter analyze`: lulus tanpa issue pada mini project.
- `flutter test`: 10 test lulus pada mini project.
- Test provider menggunakan repository palsu dan tidak bergantung pada jaringan.
- Struktur portfolio tersedia dalam folder `04-week-4-networking-rest-api/`.

## Dokumentasi Screenshot Berdasarkan Waktu

Screenshot berikut disusun berdasarkan timestamp pada nama file, dari proses
awal praktikum sampai hasil pengujian akhir. Semua gambar berada di folder
[`screenshots/`](screenshots/).

### 1. Praktikum 1 - Model `Post`

Menampilkan model `Post` dengan `fromJson` aman null dan `toJson` pada editor,
serta halaman awal aplikasi pada emulator.

![Praktikum 1 - model Post](screenshots/satty-2026-09-21_19%3A19%3A36.png)

File: `screenshots/satty-2026-09-21_19:19:36.png`

### 2. Praktikum 2 - Success State

Daftar posts berhasil dimuat dari JSONPlaceholder dan ditampilkan melalui
provider Riverpod.

![Praktikum 2 - daftar posts berhasil dimuat](screenshots/satty-2026-09-21_19%3A46%3A56.png)

File: `screenshots/satty-2026-09-21_19:46:56.png`

### 3. Praktikum 2 - Daftar Posts

Daftar posts menampilkan data hingga bagian akhir koleksi, termasuk post nomor
92 sampai 100.

![Praktikum 2 - bagian akhir daftar posts](screenshots/satty-2026-09-21_19%3A47%3A09.png)

File: `screenshots/satty-2026-09-21_19:47:09.png`

### 4. Praktikum 2 - Error dan Retry

Saat koneksi timeout, UI menampilkan pesan error yang ramah pengguna dan tombol
`Coba lagi`.

![Praktikum 2 - error timeout dan retry](screenshots/satty-2026-09-21_19%3A47%3A50.png)

File: `screenshots/satty-2026-09-21_19:47:50.png`

### 5. Praktikum 2 - Success Setelah Retry

Setelah koneksi tersedia kembali, daftar posts berhasil dimuat ulang.

![Praktikum 2 - daftar posts setelah retry](screenshots/satty-2026-09-21_19%3A48%3A33.png)

File: `screenshots/satty-2026-09-21_19:48:33.png`

### 6. Praktikum 3 - Pagination Halaman Pertama

Halaman pertama pagination menampilkan 10 posts dan indikator loading untuk
memuat halaman berikutnya.

![Praktikum 3 - halaman pertama pagination](screenshots/satty-2026-09-21_20%3A14%3A04.png)

File: `screenshots/satty-2026-09-21_20:14:04.png`

### 7. Praktikum 3 - Pagination Mendekati Akhir

Infinite scroll berhasil menambahkan data secara bertahap sampai mendekati
akhir koleksi.

![Praktikum 3 - pagination mendekati akhir](screenshots/satty-2026-09-21_20%3A37%3A43.png)

File: `screenshots/satty-2026-09-21_20:37:43.png`

### 8. Refactoring dan Testing

Test provider dengan fake repository dijalankan tanpa request HTTP sungguhan;
terminal menunjukkan seluruh 9 test lulus.

![Refactoring dan testing - semua test lulus](screenshots/satty-2026-09-21_22%3A41%3A16.png)

File: `screenshots/satty-2026-09-21_22:41:16.png`

### 9. Mini Project - Pagination Sedang Berjalan

Mini project menampilkan posts pada halaman pagination berikutnya dan indikator
loading ketika request halaman selanjutnya sedang berlangsung.

![Mini project - pagination berjalan](screenshots/satty-2026-09-21_23%3A32%3A42.png)

File: `screenshots/satty-2026-09-21_23:32:42.png`

### 10. Refactoring - Detail Post dengan GoRouter

Route `/post/:id` berhasil membuka halaman detail post dan menampilkan title
serta body lengkap.

![Refactoring - detail post](screenshots/satty-2026-09-21_23%3A33%3A02.png)

File: `screenshots/satty-2026-09-21_23:33:02.png`

### 11. Mini Project - Semua Data Termuat

Pagination mencapai post 100 dan menampilkan pesan `Semua data termuat.`
sebagai penanda bahwa tidak ada halaman berikutnya.

![Mini project - semua data termuat](screenshots/satty-2026-09-21_23%3A33%3A30.png)

File: `screenshots/satty-2026-09-21_23:33:30.png`
