// =============================================================================
// OUTPUT AWAL AI (DRAF) — BELUM DIVERIFIKASI
// -----------------------------------------------------------------------------
// File ini adalah draf pertama yang dihasilkan AI dari prompt pada
// docs/ai-challenge.md. File ini TIDAK dipakai aplikasi (dikecualikan dari
// `flutter analyze`) dan disimpan hanya sebagai bukti proses AI Challenge.
//
// Temuan verifikasi & perbaikan manual: lihat docs/ai-challenge.md.
// Implementasi final yang benar: lib/messaging/push_service.dart.
// =============================================================================

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class PushService {
  final _local = FlutterLocalNotificationsPlugin();
  final navigatorKey = GlobalKey<NavigatorState>();

  Future<void> init() async {
    // Minta izin notifikasi.
    await FirebaseMessaging.instance.requestPermission();

    // Ambil token dan kirim ke backend.
    final token = await FirebaseMessaging.instance.getToken();
    debugPrint('FCM Token: $token');
    await _sendTokenToBackend(token!);

    // Pantau perubahan token.
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      debugPrint('Token berubah: $newToken');
    });

    // Langganan topik pengumuman kampus.
    await FirebaseMessaging.instance.subscribeToTopic('pengumuman-kampus');

    // Foreground.
    FirebaseMessaging.onMessage.listen((message) {
      debugPrint('Foreground: ${message.notification?.title}');
    });

    // Background lalu diklik.
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      navigatorKey.currentState?.pushNamed(message.data['route']);
    });

    // Terminated lalu diklik.
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) {
      navigatorKey.currentState?.pushNamed(initial.data['route']);
    }
  }

  Future<void> _sendTokenToBackend(String token) async {
    // TODO: kirim ke POST /devices
  }

  // Background handler.
  static Future<void> onBackgroundMessage(RemoteMessage message) async {
    debugPrint('Background: ${message.messageId}');
  }
}
