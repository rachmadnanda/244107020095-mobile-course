# Offline Notes — Week 5

Aplikasi Flutter untuk mengelola catatan secara offline-first. Catatan
tersimpan di SQLite dan preferensi aplikasi tersimpan di SharedPreferences.

## Tujuan dan fitur

- CRUD catatan persisten, diurutkan berdasarkan `updated_at` terbaru.
- Cache-first: daftar dan detail dibaca dari repository lokal.
- Badge `Belum tersinkron` untuk catatan dengan `dirty = 1`.
- Sinkronisasi simulasi melalui `syncNotes`; dirty menjadi `0` hanya setelah
  proses berhasil.
- Toggle tema terang/gelap dan waktu terakhir aplikasi dibuka.
- Detail catatan melalui GoRouter (`/note/:id`).
- Mode offline untuk membuktikan catatan tetap dapat dibaca dan ditambahkan.

## Stack teknologi

- Flutter dan Dart
- Riverpod untuk dependency injection dan state management
- `sqflite` untuk SQLite
- `shared_preferences` untuk preferensi kecil
- GoRouter untuk navigasi

## Struktur

```text
lib/       Kode aplikasi, repository, database, provider, dan halaman
test/      Unit test model/provider dan widget terisolasi
docs/      Prompt AI, perbandingan storage, dan keputusan offline-first
screenshots/ Bukti mode offline dan badge dirty (diisi saat demo)
```

## Menjalankan

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

Pada aplikasi, aktifkan switch `Offline`, tambah catatan, dan buka daftar
catatan untuk melihat badge dirty. Matikan switch tersebut lalu tekan tombol
sinkronisasi untuk melihat badge hilang setelah proses berhasil.

## Aturan konflik dan sinkronisasi

Perubahan lokal diberi `dirty = 1`. Sinkronisasi memproses catatan dirty
secara non-blocking terhadap tampilan; UI tetap dapat membaca dan menambah
catatan. Konflik menggunakan aturan last-write-wins berdasarkan `updated_at`.
Jika operasi sinkronisasi nantinya perlu retry individual, prioritas berikutnya
adalah tabel outbox berisi operasi, payload, percobaan terakhir, dan error.

## Hasil testing

`test/note_test.dart` memverifikasi mapping aman ketika field map hilang,
serialisasi flag dirty, provider sukses dengan `FakeNoteRepository`, dan
provider error tanpa membuka SQLite sungguhan. `test/widget_test.dart`
memverifikasi tampilan `NoteTile` secara terisolasi.

## Refleksi

### Mengapa daftar catatan bukan SharedPreferences?

SharedPreferences adalah key-value store, bukan database koleksi. Jika daftar
disimpan sebagai JSON besar, pencarian, pengurutan, update satu item, transaksi,
dan migrasi menjadi rapuh serta harus memuat ulang seluruh koleksi. Risiko
korupsi atau konflik penulisan juga lebih besar ketika jumlah catatan bertambah.

### Kapan cache-first cukup?

Cache-first cukup untuk catatan yang harus dapat dibaca tanpa jaringan dan
ketika data lokal terbaru lebih berguna daripada menunggu server. Data seperti
harga real-time memerlukan network-first atau stale-while-revalidate karena
nilai lama dapat menyebabkan keputusan bisnis yang salah.

### Dirty flag menjadi antrean sync

Dirty flag adalah antrean minimal: query `WHERE dirty = 1` mengambil pekerjaan,
lalu flag diubah ke nol setelah server menjawab sukses. Proses ini berjalan
async sehingga tidak memblokir interaksi UI. Tabel outbox diperlukan ketika
setiap operasi (create/update/delete) harus dipertahankan, diulang terpisah,
diurutkan, atau dilacak error-nya.

### Rekomendasi AI yang ditolak

Tidak ada rekomendasi storage utama yang ditolak. Rekomendasi SharedPreferences
untuk preferensi dan SQLite untuk catatan sesuai kebutuhan. Klaim `real-time`
untuk `sqflite` tidak diterima sebagai fitur bawaan; aplikasi ini memakai
invalidasi provider setelah mutasi, sedangkan stream `watch()` tersedia secara
langsung pada Drift.

## Referensi dan dokumentasi AI

- [AI Challenge](docs/ai-challenge.md)
- [Offline-first dan aturan konflik](docs/offline-first.md)
