import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'data/api_client.dart';
import 'data/api_errors.dart';
import 'data/auth_repository.dart';
import 'data/device_repository.dart';
import 'data/token_store.dart';
import 'messaging/push_service.dart';
import 'pages/announcement_page.dart';
import 'pages/home_page.dart';
import 'pages/login_page.dart';
import 'providers/auth_provider.dart';
import 'routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Klien Dio (dengan refresh token otomatis) dipakai untuk mendaftarkan
  // token FCM ke backend `POST /devices`.
  final deviceRepository = DeviceRepository(
    buildApiClient(TokenStore(), AuthRepository()),
  );

  registerBackgroundHandler();
  await initLocalNotifications();
  await requestNotificationPermission();
  await initFcmToken(
    onToken: (token) async {
      // `onToken` dipanggil lagi oleh onTokenRefresh setiap token berubah,
      // jadi backend selalu menerima token terbaru.
      try {
        await deviceRepository.registerToken(
          token: token,
          platform: defaultTargetPlatform == TargetPlatform.iOS
              ? 'ios'
              : 'android',
        );
      } catch (e) {
        // Offline / backend belum siap: jangan sampai membuat app crash.
        debugPrint('Gagal mendaftarkan token FCM: ${friendlyError(e)}');
      }
    },
  );
  runApp(const ProviderScope(child: CampusNotifyApp()));
}

class CampusNotifyApp extends ConsumerStatefulWidget {
  const CampusNotifyApp({super.key});

  @override
  ConsumerState<CampusNotifyApp> createState() => _CampusNotifyAppState();
}

class _CampusNotifyAppState extends ConsumerState<CampusNotifyApp> {
  final _refreshNotifier = ValueNotifier<int>(0);
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = GoRouter(
      initialLocation: AppRoutes.login,
      refreshListenable: _refreshNotifier,
      redirect: (context, state) {
        final loggedIn = ref.read(authStateProvider).value ?? false;
        final goingLogin = state.matchedLocation == AppRoutes.login;
        if (!loggedIn && !goingLogin) return AppRoutes.login;
        if (loggedIn && goingLogin) return AppRoutes.home;
        return null;
      },
      routes: [
        GoRoute(path: AppRoutes.login, builder: (_, _) => const LoginPage()),
        GoRoute(path: AppRoutes.home, builder: (_, _) => const HomePage()),
        GoRoute(
          path: AppRoutes.announcement,
          builder: (_, s) => AnnouncementPage(id: s.pathParameters['id'] ?? ''),
        ),
      ],
    );

    // Klik banner lokal saat foreground -> navigasi via router yang sama.
    onNotificationTap = _router.go;

    // Daftarkan handler FCM — foreground + klik background.
    listenForeground(_router);
    // Handle terminated setelah frame pertama.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      handleTerminated(_router);
    });
  }

  @override
  void dispose() {
    onNotificationTap = null;
    _refreshNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authStateProvider, (_, _) {
      _refreshNotifier.value++;
    });

    return MaterialApp.router(title: 'Campus Notify', routerConfig: _router);
  }
}
