import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';

import 'route_parser.dart';

final _local = FlutterLocalNotificationsPlugin();

/// Topik broadcast pengumuman kampus (broadcast ke semua mahasiswa).
const announcementsTopic = 'pengumuman-kampus';

/// Payload dari klik banner saat app belum siap (terminated).
String? pendingDeepLink;

/// Callback navigasi saat banner lokal (foreground) diklik dan app sudah hidup.
/// Diisi dari `main.dart` setelah GoRouter dibuat.
void Function(String route)? onNotificationTap;

/// Background handler — WAJIB top-level & @pragma.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('BG message: ${message.messageId}');
}

void registerBackgroundHandler() {
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
}

Future<bool> requestNotificationPermission() async {
  final settings = await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );
  return settings.authorizationStatus == AuthorizationStatus.authorized ||
      settings.authorizationStatus == AuthorizationStatus.provisional;
}

Future<void> initLocalNotifications() async {
  const android = AndroidInitializationSettings('@mipmap/ic_launcher');
  const ios = DarwinInitializationSettings();
  await _local.initialize(
    settings: const InitializationSettings(android: android, iOS: ios),
    onDidReceiveNotificationResponse: (response) {
      final route = response.payload;
      if (route == null || route.isEmpty) return;
      // App hidup -> navigasi langsung. Belum siap -> simpan untuk
      // diproses `handleTerminated` saat startup.
      if (onNotificationTap != null) {
        onNotificationTap!(route);
      } else {
        pendingDeepLink = route;
      }
    },
  );
}

Future<void> initFcmToken({
  required Future<void> Function(String token) onToken,
}) async {
  final token = await FirebaseMessaging.instance.getToken();
  if (token != null) await onToken(token);

  FirebaseMessaging.instance.onTokenRefresh.listen(onToken);

  await FirebaseMessaging.instance.subscribeToTopic(announcementsTopic);
}

/// Berhenti dari topik broadcast (mis. saat logout).
Future<void> unsubscribeFromAnnouncements() =>
    FirebaseMessaging.instance.unsubscribeFromTopic(announcementsTopic);

/// Foreground + background-click listener.
void listenForeground(GoRouter router) {
  FirebaseMessaging.onMessage.listen((message) async {
    final route = routeFromMessage(message.data);
    const androidDetails = AndroidNotificationDetails(
      'pengumuman',
      'Pengumuman Kampus',
      importance: Importance.high,
      priority: Priority.high,
    );
    await _local.show(
      id: message.hashCode,
      title: message.notification?.title ?? 'Pengumuman',
      body: message.notification?.body ?? '',
      notificationDetails: const NotificationDetails(android: androidDetails),
      payload: route,
    );
  });

  FirebaseMessaging.onMessageOpenedApp.listen((message) {
    router.go(routeFromMessage(message.data));
  });
}

Future<void> handleTerminated(GoRouter router) async {
  final initial = await FirebaseMessaging.instance.getInitialMessage();
  debugPrint('>>> TERMINATED: data = ${initial?.data}');
  if (initial != null) {
    final route = routeFromMessage(initial.data);
    debugPrint('>>> TERMINATED route = $route');
    router.go(route);
  }
  debugPrint('>>> pendingDeepLink = $pendingDeepLink');
  if (pendingDeepLink != null) {
    router.go(pendingDeepLink!);
    pendingDeepLink = null;
  }
}
