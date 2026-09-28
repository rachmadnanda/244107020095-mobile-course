# Offline-First

## Cache-first

Aplikasi membaca data dari penyimpanan lokal terlebih dahulu sehingga data
tetap dapat ditampilkan ketika tidak ada koneksi internet.

## Dirty flag

Catatan baru atau catatan yang berubah diberi nilai `dirty = 1`.
Status tersebut menunjukkan bahwa perubahan belum disinkronkan.

## Sync queue

Catatan dengan `dirty = 1` diproses ketika sinkronisasi dijalankan.
Setelah proses sinkronisasi berhasil, nilai dirty diubah menjadi `0`.

## Conflict rule

Aplikasi menggunakan aturan last-write-wins berdasarkan `updated_at`.
Jika terdapat dua versi data yang berbeda, versi dengan waktu perubahan
paling baru digunakan.