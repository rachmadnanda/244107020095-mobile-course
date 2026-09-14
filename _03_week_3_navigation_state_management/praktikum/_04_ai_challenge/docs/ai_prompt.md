# AI Challenge — Prompt

Buatkan halaman `StatsPage` pada aplikasi Flutter menggunakan `flutter_riverpod` dengan ketentuan berikut:

1. Gunakan `ConsumerWidget`.
2. Gunakan satu `AsyncNotifierProvider`.
3. Gunakan `AsyncNotifier` untuk mengambil data statistik.
4. Simulasikan proses asynchronous selama 2 detik menggunakan `Future.delayed`.
5. Buat kemungkinan gagal sebesar 30%.
6. Gunakan `AsyncValue` untuk menangani tiga kondisi:

   * loading
   * error
   * success/data
7. Pada kondisi error, tampilkan pesan error dan tombol retry.
8. Buat unit test untuk notifier.
9. Gunakan tipe data provider secara eksplisit.
10. Gunakan API Riverpod yang sesuai dengan versi package terbaru.
11. Berikan kode yang sederhana dan mudah dipahami oleh mahasiswa pemula.
