# Campus Notify — Week 6: Authentication, Security & FCM

Aplikasi Flutter **Campus Notification App** untuk praktikum Minggu 6. Aplikasi
mendemonstrasikan alur autentikasi berbasis token (mock provider yang siap
diganti Firebase Auth), penyimpanan token yang aman, refresh otomatis via Dio,
serta integrasi Firebase Cloud Messaging (FCM) lengkap dengan deep link ke
halaman pengumuman pada tiga app state.

## Tujuan pembelajaran

- Menjelaskan alur autentikasi dan perbedaan ID token, access token, serta refresh token.
- Menyimpan token secara aman (`flutter_secure_storage`) dan menerapkan refresh otomatis.
- Menjelaskan arsitektur FCM: app server, Firebase, dan perangkat.
- Meminta notification permission dan mengelola token lifecycle (`getToken`, `onTokenRefresh`).
- Membedakan notification payload vs data payload pada state foreground, background, dan terminated.
- Menangani klik notifikasi (deep link dengan GoRouter) dan topic messaging.
- Menerapkan prinsip keamanan dasar (tidak menyimpan secret di kode, tidak log token).

## Fitur utama

1. **Login + guard route** — belum login selalu diarahkan ke `/login` (GoRouter `redirect`).
2. **Token di secure storage** — access & refresh token hanya lewat `TokenStore`
   (`flutter_secure_storage`, Keychain/Keystore), tidak pernah di `SharedPreferences`.
3. **Auto refresh Dio** — interceptor mengulang request **satu kali** saat 401;
   bila refresh ikut mati, sesi dibersihkan dan diarahkan ke `/login`.
4. **FCM terintegrasi** — permission runtime, `getToken`, `onTokenRefresh` dikirim
   ke backend, dan langganan topik `pengumuman-kampus`.
5. **Notifikasi gabungan `notification + data`** — klik membuka `/pengumuman/:id`
   pada state foreground, background, dan terminated.
6. **Refactoring & testing** — rute terpusat (`routes.dart`), parsing payload murni
   (`route_parser.dart`), pemetaan error ramah pengguna (`api_errors.dart`), dan unit test.

## Stack teknologi

| Komponen | Paket |
| --- | --- |
| State management | `flutter_riverpod` |
| Navigasi / deep link | `go_router` |
| HTTP client | `dio` |
| Secure storage | `flutter_secure_storage` |
| Push notification | `firebase_core`, `firebase_messaging` |
| Local notification (foreground) | `flutter_local_notifications` |

## Struktur folder

```
lib/
├── main.dart
├── routes.dart
├── data/
│   ├── api_client.dart      # Dio + interceptor refresh otomatis
│   ├── api_errors.dart      # DioException -> pesan ramah pengguna
│   ├── auth_repository.dart # mock auth (siap diganti Firebase Auth)
│   ├── device_repository.dart # POST /devices (daftar token FCM ke backend)
│   └── token_store.dart     # secure storage token
├── messaging/
│   ├── push_service.dart    # permission, token lifecycle, 3 handler, topik
│   └── route_parser.dart    # parsing RemoteMessage -> route (murni, bisa diunit-test)
├── providers/
│   └── auth_provider.dart
└── pages/
    ├── login_page.dart
    ├── home_page.dart
    └── announcement_page.dart
```

## Cara menjalankan

```bash
flutter pub get
flutter analyze
flutter test
flutter run          # disarankan perangkat fisik / emulator dengan Google Play Services
```

Konfigurasi Firebase:

- `android/app/google-services.json` sudah terpasang dan plugin
  `com.google.gms.google-services` aktif di `android/app/build.gradle.kts`.
- `Firebase.initializeApp()` dipanggil sebelum `runApp`.

## Alur autentikasi & token

```
Login --> access (15 mnt) + refresh (7 hari) tersimpan di secure storage
Request API --header Bearer access--> 401 expired?
Ya --> tukar refresh --> access baru --> ulangi request SEKALI
Refresh ikut kedaluwarsa --> clear() --> kembali ke /login
```

Titik migrasi ke Firebase Auth ada di `AuthRepository.login()`: ganti isi method
dengan `FirebaseAuth.instance.signInWithEmailAndPassword`, sedangkan pola
repository + token refresh tetap sama.

## Alur FCM

```
App Server (backend) --kirim--> Firebase Cloud Messaging --push--> Perangkat
Aplikasi --daftar token--> Backend (simpan token per user)
```

1. Aplikasi meminta izin notifikasi (`requestNotificationPermission`).
2. Aplikasi mengambil registration token (`FirebaseMessaging.instance.getToken()`).
3. Token dikirim ke backend (`POST /devices` via `DeviceRepository`) dan
   dipantau perubahannya (`onTokenRefresh`).
4. Backend memanggil FCM API untuk mengirim ke token/topik tertentu.

### Payload uji (gabungan notification + data)

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

## Tabel pengujian tiga app state (Praktikum 3)

Diuji dengan payload yang sama seperti di atas. Isi kolom **Bukti** dengan file
di folder `screenshots/`.

| State | Yang diharapkan | Cara uji | Status | Bukti |
| --- | --- | --- | --- | --- |
| Foreground | Banner lokal muncul (dari `onMessage`), klik masuk ke `/pengumuman/3` | Aplikasi terbuka, kirim dari console/backend | ✅ Teruji | [`screenshots/08-fcm-foreground.png`](screenshots/08-fcm-foreground.png) |
| Background | Banner sistem muncul otomatis, klik masuk ke rute yang benar | Tekan Home, kirim, klik banner | ✅ Teruji | [`screenshots/12-notifikasi-terminated.png`](screenshots/12-notifikasi-terminated.png) |
| Terminated | Aplikasi terbuka ke rute yang benar via `getInitialMessage()` | Swipe-close aplikasi, kirim, klik banner | ✅ Teruji | [`screenshots/12-notifikasi-terminated.png`](screenshots/12-notifikasi-terminated.png) |

Matriks lengkap + langkah pengujian: [`docs/fcm-test-matrix.md`](docs/fcm-test-matrix.md).

Catatan pengujian:

- Token di halaman Home hanya ditampilkan **terpotong** (12 karakter pertama + `...`).
- Untuk menguji dari Firebase Console: **Messaging → New campaign**, isi
  `title`/`body`, dan tambahkan custom data `route = /pengumuman/3` (atau targetkan
  topik `pengumuman-kampus`).

## Screenshots

Galeri lengkap + keterangan tiap gambar: [`screenshots/README.md`](screenshots/README.md).

**Login & guard route**

| Login | Login terisi | Home |
| --- | --- | --- |
| ![Login](screenshots/01-login.png) | ![Login terisi](screenshots/02-login-terisi.png) | ![Home](screenshots/03-home.png) |

**Deep link GoRouter**

| Buka Pengumuman #3 | Setelah klik notifikasi |
| --- | --- |
| ![Deep link](screenshots/04-deep-link-pengumuman.png) | ![Deep link notifikasi](screenshots/11-deep-link-setelah-klik.png) |

**Izin notifikasi & token FCM**

| Izin notifikasi (Android 13+) | Token FCM terpotong |
| --- | --- |
| ![Izin notifikasi](screenshots/05-izin-notifikasi.png) | ![Token FCM](screenshots/07-fcm-token-terpotong.png) |

**Kirim dari Firebase Console (topik `pengumuman-kampus`)**

| Campaign aktif | Compose notification | Daftar campaign |
| --- | --- | --- |
| ![Campaign](screenshots/06-fcm-campaign.png) | ![Compose](screenshots/09-fcm-compose.png) | ![Terkirim](screenshots/10-fcm-campaign-terkirim.png) |

**Notifikasi state foreground**

![Banner foreground](screenshots/08-fcm-foreground.png)

**Notifikasi state background & terminated**

![Notifikasi background/terminated](screenshots/12-notifikasi-terminated.png)

## Keamanan

- Token hanya disimpan di `flutter_secure_storage`, **tidak** di `SharedPreferences`.
- Token/secret tidak di-hardcode di Dart.
- Token FCM tidak dicetak **penuh** ke log; hanya versi terpotong untuk laporan.
- Refresh token hanya dikirim lewat body `POST` HTTPS, tidak pernah lewat query URL.
- Halaman Home hanya menampilkan token terpotong untuk screenshot laporan.

## AI Challenge

Proses AI Challenge (prompt, output awal AI, hasil verifikasi, perbaikan manual,
dan keputusan teknis) didokumentasikan di folder `docs/`:

- [`docs/ai-challenge.md`](docs/ai-challenge.md) — prompt, draf AI, checklist, perbaikan, alasan.
- [`docs/ai-draft-push-service.dart`](docs/ai-draft-push-service.dart) — output awal AI (arsip).
- [`docs/fcm-test-matrix.md`](docs/fcm-test-matrix.md) — matriks uji tiga app state.

Ringkasan perbaikan atas draf AI: background handler dijadikan fungsi top-level
ber-`@pragma('vm:entry-point')`, `onTokenRefresh` benar-benar `POST /devices`,
foreground memakai local notification manual, navigasi deep link memakai GoRouter,
dan token tidak lagi di-log penuh.

## Hasil yang dicapai

- `flutter analyze`: 0 error / 0 warning (hanya info `package_names` bawaan
  konvensi penamaan folder repo).
- `flutter test`: 7 test lulus (`test/auth_push_test.dart`) — parsing route,
  logika sesi, dan kegagalan refresh.

## Refleksi

**1. Mengapa refresh token tidak boleh disimpan di SharedPreferences? Apa risikonya bila bocor?**

`SharedPreferences` menyimpan data sebagai file XML (Android) / plist (iOS)
**tanpa enkripsi**. Isinya dapat dibaca pada perangkat yang di-root/jailbreak atau
lewat backup yang diekspor. Refresh token berumur panjang (mis. 7 hari) dan
berfungsi sebagai tiket untuk menerbitkan access token baru tanpa login ulang,
jadi bila bocor penyerang dapat terus menyamar sebagai pengguna — bahkan setelah
kata sandi diganti — sampai refresh token kedaluwarsa/dicabut. Karena itu refresh
token hanya boleh disimpan di `flutter_secure_storage` yang memakai Keychain
(iOS) / Keystore (Android), sedangkan access token cukup di memori.

**2. Apa yang rusak bila `onTokenRefresh` diabaikan selama satu semester perkuliahan?**

FCM registration token dapat berubah kapan saja: reinstall, clear data, restore
dari backup, atau rotasi keamanan Firebase. Bila `onTokenRefresh` tidak dipasang,
backend menyimpan token lama yang sudah tidak valid, sehingga notifikasi ke token
itu **gagal terkirim secara diam-diam** (tidak ada error di sisi server).
Akibatnya mahasiswa tidak menerima pengumuman padahal pengiriman tercatat
"sukses" — masalah baru ketahuan saat ada informasi penting. Karena itu handler
ini wajib agar backend selalu memegang token terbaru.

**3. Kapan memakai topik dan kapan memakai token perangkat? Beri contoh pesan kampus untuk masing-masing.**

- **Topik** untuk **broadcast** ke banyak pengguna tanpa perlu tahu daftarnya:
  semua mahasiswa, satu angkatan, satu kelas, atau satu UKM. Contoh:
  "Kampus libur nasional tanggal 25 Desember", "Jadwal UTS semester 5 sudah
  terbit", "Rapat UKM Programming Club besok pukul 16.00".
- **Token perangkat** untuk **pesan personal/privat** yang hanya relevan bagi
  satu pengguna. Contoh: "Nilai mata kuliah Pemrograman Mobile Anda sudah
  keluar", "Tagihan UKT atas nama Anda jatuh tempo", "Jadwal bimbingan Anda
  diubah ke pukul 10.00".

Aturan praktis: jika pesan boleh dibaca semua orang → **topik**; jika hanya untuk
satu orang atau sensitif → **token perangkat**.

**4. Bagian mana dari draf AI yang Anda tolak atau perbaiki, dan mengapa?**

Detail lengkap ada di [`docs/ai-challenge.md`](docs/ai-challenge.md). Ringkasannya:

- **Menolak background handler sebagai method kelas** → diubah menjadi fungsi
  top-level ber-`@pragma('vm:entry-point')`, karena handler berjalan di isolate
  terpisah dan berisiko terbuang tree-shaking pada build rilis.
- **Memperbaiki `onTokenRefresh` yang hanya `debugPrint`** → diganti pengiriman
  nyata ke `POST /devices` via `DeviceRepository`, agar backend tidak menyimpan
  token basi.
- **Menolak navigasi `navigatorKey.pushNamed`** → diganti `GoRouter.go` +
  `routeFromMessage()`, karena `pushNamed` melewati guard login GoRouter dan route
  mentah (tanpa slash) bisa tidak valid.
- **Memperbaiki foreground yang hanya log** → ditambah local notification manual,
  karena sistem tidak menampilkan banner saat aplikasi terbuka.
- **Menghapus log token penuh** → token FCM adalah kredensial; hanya versi
  terpotong yang ditampilkan untuk laporan.
- **Menambah unsubscribe topik saat logout** yang tidak ada di draf AI.
