import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'messaging/push_service.dart';
import 'pages/announcement_page.dart';
import 'pages/home_page.dart';
import 'pages/login_page.dart';
import 'providers/auth_provider.dart';
import 'routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  registerBackgroundHandler();
  await initLocalNotifications();
  await requestNotificationPermission();
  await initFcmToken(
    onToken: (token) async {
      // Untuk Praktikum 2, cukup print token (backend belum ada).
      debugPrint('Token dikirim ke backend: ${token.substring(0, 12)}...');
      // Di produksi: dio.post('/devices', data: {'fcm_token': token});
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
        GoRoute(path: AppRoutes.login, builder: (_, __) => const LoginPage()),
        GoRoute(path: AppRoutes.home, builder: (_, __) => const HomePage()),
        GoRoute(
          path: AppRoutes.announcement,
          builder: (_, s) => AnnouncementPage(id: s.pathParameters['id'] ?? ''),
        ),
      ],
    );

    // Daftarkan handler FCM — foreground + klik background.
    listenForeground(_router);
    // Handle terminated setelah frame pertama.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      handleTerminated(_router);
    });
  }

  @override
  void dispose() {
    _refreshNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authStateProvider, (_, __) {
      _refreshNotifier.value++;
    });

    return MaterialApp.router(title: 'Campus Notify', routerConfig: _router);
  }
}
