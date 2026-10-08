# Screenshots — Bukti Campus Notification App

Kumpulan bukti pengujian untuk laporan Tugas Minggu 6. Setiap gambar diberi nama
berurutan sesuai alur pengujian.

## 1. Autentikasi & guard route

| # | File | Keterangan |
| --- | --- | --- |
| 1 | [`01-login.png`](01-login.png) | Halaman `/login` — guard route mengarahkan pengguna yang belum login ke sini. |
| 2 | [`02-login-terisi.png`](02-login-terisi.png) | Login dengan email & kata sandi valid (`febrianarachmad@gmail.com`). |
| 3 | [`03-home.png`](03-home.png) | Halaman Home setelah login berhasil (redirect dari `/login`). |

## 2. Deep link GoRouter

| # | File | Keterangan |
| --- | --- | --- |
| 4 | [`04-deep-link-pengumuman.png`](04-deep-link-pengumuman.png) | Tombol "Buka Pengumuman #3" membuka `/pengumuman/3`. |
| 11 | [`11-deep-link-setelah-klik.png`](11-deep-link-setelah-klik.png) | Aplikasi membuka `/pengumuman/3` setelah banner notifikasi diklik. |

## 3. Izin notifikasi & FCM

| # | File | Keterangan |
| --- | --- | --- |
| 5 | [`05-izin-notifikasi.png`](05-izin-notifikasi.png) | Dialog izin notifikasi runtime Android 13+ (`requestPermission`). |
| 7 | [`07-fcm-token-terpotong.png`](07-fcm-token-terpotong.png) | Token FCM ditampilkan **terpotong** (`e26ZyLKXRX-f...`) di Home + tombol copy. |

## 4. Pengiriman dari Firebase Console

| # | File | Keterangan |
| --- | --- | --- |
| 6 | [`06-fcm-campaign.png`](06-fcm-campaign.png) | Campaign FCM aktif, target **topik `pengumuman-kampus`**. |
| 9 | [`09-fcm-compose.png`](09-fcm-compose.png) | Compose notification: target *Subscribers of pengumuman-kampus topic*. |
| 10 | [`10-fcm-campaign-terkirim.png`](10-fcm-campaign-terkirim.png) | Daftar campaign terkirim (status Active/Completed). |

## 5. Notifikasi per app state

| State | File | Keterangan |
| --- | --- | --- |
| Foreground | [`08-fcm-foreground.png`](08-fcm-foreground.png) | Aplikasi terbuka → banner lokal tampil (dari `onMessage`). |
| Background | [`12-notifikasi-terminated.png`](12-notifikasi-terminated.png) | Aplikasi tidak di foreground → banner sistem muncul dengan judul/isi pengumuman. |
| Terminated | [`12-notifikasi-terminated.png`](12-notifikasi-terminated.png) | Notifikasi diterima saat aplikasi tidak berjalan → banner sistem muncul; klik membuka rute tujuan (`11-deep-link-setelah-klik.png`). |

> Catatan: `12-notifikasi-terminated.png` adalah bukti banner notifikasi diterima
> saat aplikasi **tidak di foreground** (dipakai untuk state background &
> terminated). `11-deep-link-setelah-klik.png` menunjukkan halaman tujuan
> `/pengumuman/3` setelah banner diklik.
