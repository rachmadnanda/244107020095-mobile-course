# AI Challenge — PushService FCM

Dokumen ini merekam proses **AI Challenge**: prompt yang diberikan, output awal
AI, hasil verifikasi terhadap *AI Verification Checklist*, daftar perbaikan
manual, dan keputusan teknis akhir.

- Prompt: [§1](#1-prompt-yang-diberikan)
- Output awal AI: [§2](#2-output-awal-ai) — file mentah `ai-draft-push-service.dart`
- Verifikasi: [§3](#3-ai-verification-checklist)
- Perbaikan manual: [§4](#4-daftar-perbaikan-manual)
- Keputusan & alasan teknis: [§5](#5-keputusan-final--alasan-teknis)
- Android 13+ vs iOS & aturan BuildContext: [§6](#6-bagian-android-13-vs-ios-dan-aturan-buildcontext)

Implementasi final yang dipakai aplikasi: `lib/messaging/push_service.dart`.

---

## 1. Prompt yang diberikan

```text
Aplikasi Flutter Campus Notification App.
Stack: firebase_messaging, flutter_local_notifications,
flutter_secure_storage, go_router, Riverpod.
Buatkan PushService dengan:
- requestPermission + getToken + onTokenRefresh (kirim ke POST /devices)
- onMessage (tampilkan local notification manual)
- onMessageOpenedApp + getInitialMessage (navigasi ke data.route)
- subscribe/unsubscribe topic pengumuman-kampus
- background handler top-level dengan @pragma('vm:entry-point')
Tandai bagian yang BERBEDA untuk Android 13+ vs iOS,
dan bagian yang tidak boleh mengakses BuildContext.
```

## 2. Output awal AI

Output awal AI tersimpan utuh di [`ai-draft-push-service.dart`](ai-draft-push-service.dart).
Ringkasannya, AI mengusulkan satu kelas `PushService` dengan method `init()`,
`_sendTokenToBackend()`, dan background handler berupa **method statis kelas**.

Draf ini **tidak langsung dipakai** — diperiksa dulu terhadap checklist di §3.

## 3. AI Verification Checklist

| # | Item verifikasi | Temuan pada draf AI | Status | Perbaikan manual |
| --- | --- | --- | --- | --- |
| 1 | Background handler top-level + `@pragma('vm:entry-point')` | `static Future<void> onBackgroundMessage(...)` = **method kelas**, tanpa `@pragma` | ❌ Ditolak | Diubah jadi fungsi **top-level** `firebaseMessagingBackgroundHandler` + `@pragma('vm:entry-point')` |
| 2 | `onTokenRefresh` benar-benar mengirim token baru ke backend (bukan cuma log) | Hanya `debugPrint('Token berubah: ...')`; `_sendTokenToBackend` malah **kosong (TODO)** | ❌ Ditolak | `onTokenRefresh.listen(onToken)` memanggil callback yang **POST `/devices`** via `DeviceRepository` |
| 3 | Foreground pakai local notification manual | `onMessage` hanya `debugPrint`, tidak menampilkan banner | ❌ Ditolak | `onMessage` memanggil `_local.show(...)` (banner lokal) |
| 4 | Klik dari 3 state masuk ke rute yang benar | Memakai `navigatorKey.currentState?.pushNamed(...)` + `pushNamed` (bukan GoRouter), route mentah tanpa fallback | ❌ Ditolak | Navigasi lewat **GoRouter** (`router.go`) + `routeFromMessage()` untuk normalisasi route |
| 5 | Token/secret tidak di-hardcode & tidak di-log penuh | `debugPrint('FCM Token: $token')` mencetak token **penuh** | ❌ Ditolak | Token hanya ditampilkan **terpotong** (12 char + `...`); log penuh dihapus |
| 6 | subscribe **dan** unsubscribe topik | Hanya `subscribeToTopic`; tidak ada unsubscribe | ⚠️ Kurang | Ditambah `unsubscribeFromAnnouncements()`, dipanggil saat **logout** |
| 7 | Tidak ada akses BuildContext di background isolate | Draf memakai `navigatorKey` dari dalam handler background | ❌ Ditolak | Handler background tidak menyentuh UI; navigasi hanya di `onMessageOpenedApp` / `getInitialMessage` |
| 8 | Tandai Android 13+ vs iOS | Tidak ada penanda | ⚠️ Kurang | Komentar penanda ditambahkan (lihat §6) |
| 9 | Hasil uji 3 app state | Tidak ada | ⚠️ Kurang | Tabel pengujian: [`fcm-test-matrix.md`](fcm-test-matrix.md) |

## 4. Daftar perbaikan manual

Semua perbaikan diterapkan pada `lib/messaging/push_service.dart` (kecuali
disebut lain):

1. **Background handler top-level.** Method kelas `onBackgroundMessage` diganti
   fungsi top-level `firebaseMessagingBackgroundHandler` dengan
   `@pragma('vm:entry-point')`, didaftarkan lewat `registerBackgroundHandler()`.
2. **`onTokenRefresh` mengirim ke backend.** Draf `debugPrint` diganti
   `FirebaseMessaging.instance.onTokenRefresh.listen(onToken)`; `onToken`
   dikirim ke `POST /devices` lewat `lib/data/device_repository.dart`
   (`DeviceRepository.registerToken`) dari `main.dart`.
3. **Foreground memakai local notification.** `onMessage` menampilkan banner
   manual via `_local.show(...)` dengan `payload` = route hasil
   `routeFromMessage()`.
4. **Navigasi memakai GoRouter.** `navigatorKey`/`pushNamed` dibuang; klik
   background (`onMessageOpenedApp`) dan terminated (`getInitialMessage`) memakai
   `router.go(routeFromMessage(message.data))`.
5. **Token tidak di-log penuh.** Baris `debugPrint` token penuh di
   `lib/pages/home_page.dart` dihapus; UI hanya menampilkan token terpotong,
   token penuh tetap tersedia lewat tombol "Copy Token Penuh" (in-memory).
6. **Unsubscribe topik.** Ditambah `unsubscribeFromAnnouncements()` dan dipanggil
   di `AuthNotifier.logout()`.
7. **Konstanta topik.** String `'pengumuman-kampus'` dijadikan konstanta
   `announcementsTopic` agar tidak terduplikasi.
8. **Penanda Android/iOS & BuildContext** ditambahkan sebagai komentar (§6).

## 5. Keputusan final & alasan teknis

Beberapa keputusan **berbeda dari saran AI**, dengan alasan:

1. **Menolak background handler sebagai method kelas.** Handler background
   dijalankan di isolate terpisah. Entry point harus fungsi top-level yang
   ditandai `@pragma('vm:entry-point')`, jika tidak, tree-shaking pada build
   rilis dapat membuang fungsi tersebut dan handler tidak pernah dipanggil.
2. **Menolak `navigatorKey` + `pushNamed`.** Proyek ini memakai **GoRouter**
   dengan guard login. `Navigator.pushNamed` melewati `redirect` GoRouter
   sehingga bisa membuka halaman tanpa sesi valid. Deep link FCM harus lewat
   `GoRouter` agar guard tetap berlaku. Ditambah `routeFromMessage()` agar route
   `pengumuman/3` (tanpa slash) tetap valid.
3. **Memisahkan navigasi dari background handler.** Handler background tidak
   boleh menyentuh UI/`BuildContext`. Pola yang benar: background hanya mencatat
   data ringan; navigasi dilakukan saat notifikasi **diklik**
   (`onMessageOpenedApp` untuk background, `getInitialMessage` untuk terminated).
4. **Local notification manual untuk foreground.** Sistem Android tidak
   menampilkan banner otomatis saat aplikasi foreground, jadi harus dibuat
   manual — jika tidak, pengguna tidak melihat apa pun padahal pesan diterima.
5. **`onTokenRefresh` wajib benar-benar POST.** Mengabaikannya membuat backend
   menyimpan token basi; setelah reinstall/clear data, notifikasi tidak sampai.
   Karena itu draf `debugPrint` ditolak dan diganti pengiriman nyata.
6. **Tidak mencetak token penuh.** Token FCM adalah kredensial pengiriman;
   membocorkannya lewat log memungkinkan pihak lain mengirim notifikasi ke
   perangkat. Untuk keperluan uji, token diambil on-demand lewat tombol copy.

## 6. Bagian Android 13+ vs iOS, dan aturan BuildContext

### Android 13+ vs iOS

| Aspek | Android 13+ (API 33) | iOS |
| --- | --- | --- |
| Izin notifikasi | Dialog runtime `POST_NOTIFICATIONS` via `requestPermission()` | Dialog runtime via `requestPermission()` (butuh capability Push di Xcode) |
| Android < 13 | Otomatis `authorized` | — |
| Ikon local notification | `AndroidInitializationSettings('@mipmap/ic_launcher')` | — |
| Inisialisasi iOS | — | `DarwinInitializationSettings()` |
| Banner saat foreground | Selalu perlu local notification manual | Bisa otomatis bila `foregroundPresentationOptions` diatur; di codelab tetap dipakai local notification agar seragam |
| Pengiriman | FCM token | FCM token + **APNs key** di Firebase Console |

### Bagian yang tidak boleh mengakses `BuildContext`

- `firebaseMessagingBackgroundHandler` — berjalan di isolate terpisah, **tanpa**
  widget tree. Tidak boleh memakai `BuildContext`, `Navigator`, `ScaffoldMessenger`,
  maupun `ref`/Riverpod. Tugasnya hanya mencatat/menyimpan data ringan.
- `onMessage` (foreground) dan `onMessageOpenedApp` — berjalan di isolate utama,
  jadi boleh memicu navigasi, tetapi **melalui GoRouter** yang diteruskan sebagai
  parameter, bukan `BuildContext` yang disimpan sebagai variabel global.

## 7. Cara mereproduksi

1. Berikan prompt pada §1 ke AI coding assistant.
2. Simpan output mentah (draf) — di sini diarsipkan sebagai `ai-draft-push-service.dart`.
3. Bandingkan dengan checklist §3, catat status tiap item.
4. Terapkan perbaikan §4 dan uji 3 app state memakai `fcm-test-matrix.md`.
