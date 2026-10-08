# Matriks Pengujian Tiga App State (FCM)

Diuji dengan **payload yang sama** (gabungan `notification` + `data`) agar
perilaku ketiga state dapat dibandingkan.

## Payload uji

```json
{
  "message": {
    "topic": "pengumuman-kampus",
    "notification": {
      "title": "Jadwal kuliah berubah",
      "body": "Kelas Mobile pindah ke Ruang A2 jam 13.00"
    },
    "data": {
      "route": "/pengumuman/3",
      "id": "3"
    }
  }
}
```

## Tabel hasil uji

> Isi kolom **Status** dan **Bukti** setelah menguji di perangkat fisik/emulator
> dengan Google Play Services. Screenshot disimpan di folder `screenshots/`.

| State | Yang diharapkan | Cara uji | Status | Bukti |
| --- | --- | --- | --- | --- |
| Foreground | Banner lokal muncul (dari `onMessage`), klik masuk ke `/pengumuman/3` | Aplikasi terbuka, kirim dari console/backend | ✅ Teruji | `screenshots/08-fcm-foreground.png` |
| Background | Banner sistem muncul otomatis, klik masuk ke rute yang benar | Tekan Home, kirim, klik banner | ✅ Teruji | `screenshots/12-notifikasi-terminated.png` |
| Terminated | Aplikasi terbuka ke rute yang benar via `getInitialMessage()` | Swipe-close aplikasi, kirim, klik banner | ✅ Teruji | `screenshots/12-notifikasi-terminated.png` |

> Catatan: `screenshots/12-notifikasi-terminated.png` adalah bukti banner
> notifikasi diterima saat aplikasi **tidak di foreground** (dipakai untuk state
> background & terminated). Halaman tujuan setelah klik ditunjukkan oleh
> `screenshots/11-deep-link-setelah-klik.png`.

## Langkah pengujian dari Firebase Console

1. Buka **Firebase Console → Messaging → New campaign → Notifications**.
2. Isi **Title** dan **Body**.
3. Tambahkan **Custom data**: `route = /pengumuman/3`, `id = 3`.
   - Untuk uji topik, pilih target **Topic** `pengumuman-kampus`.
   - Untuk uji personal, pilih target **Single device** dengan token dari
     tombol "Copy Token Penuh" di halaman Home.
4. Kirim sesuai state yang diuji:
   - **Foreground**: aplikasi terbuka.
   - **Background**: tekan tombol Home lalu kirim.
   - **Terminated**: swipe-close aplikasi lalu kirim.
5. Klik banner dan pastikan aplikasi membuka `/pengumuman/3`.
6. Ambil screenshot dan perbarui tabel di atas.

## Catatan keamanan

- Jangan menampilkan token FCM **penuh** pada screenshot laporan; gunakan token
  terpotong (12 karakter + `...`) yang tampil di halaman Home.
