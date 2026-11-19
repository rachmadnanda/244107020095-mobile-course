import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/dev/dev_seed_service.dart';
import 'core/dev/performance_probe.dart';
import 'features/assistant/presentation/pages/assistant_page.dart';
import 'features/notes/presentation/pages/note_detail_page.dart';
import 'features/notes/presentation/pages/notes_page.dart';
import 'features/settings/presentation/pages/settings_page.dart';
import 'features/settings/presentation/providers/settings_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Alat profiling: isi data uji secara deterministik sebelum app dibuka.
  // Contoh: flutter run --profile --dart-define=SEED_NOTES=1000
  const seedCount = int.fromEnvironment('SEED_NOTES');
  if (!kReleaseMode && seedCount > 0) {
    await const DevSeedService().replaceWithSample(seedCount);
  }

  PerformanceProbe.instance.install();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  static final _router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (context, state) => const NotesPage()),
      GoRoute(
        path: '/note/:id',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '');
          if (id == null) {
            return const Scaffold(
              body: Center(child: Text('ID catatan tidak valid')),
            );
          }
          return NoteDetailPage(noteId: id);
        },
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsPage(),
      ),
      GoRoute(
        path: '/assistant',
        builder: (context, state) => const AssistantPage(),
      ),
    ],
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final darkMode = ref.watch(
      darkModeProvider.select((value) => value.value ?? false),
    );

    return MaterialApp.router(
      title: 'Week 12 - Testing & QA Notes',
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.light,
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      themeMode: darkMode ? ThemeMode.dark : ThemeMode.light,
      routerConfig: _router,
    );
  }
}
