import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'pages/detail_page.dart';
import 'pages/stats_page.dart';
import 'pages/todo_page.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) {
        return const TodoPage();
      },
      routes: [
        GoRoute(
          path: 'detail/:id',
          builder: (context, state) {
            return DetailPage(id: state.pathParameters['id']!);
          },
        ),
      ],
    ),
    GoRoute(
      path: '/stats',
      builder: (context, state) {
        return const StatsPage();
      },
    ),
  ],
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Week 3 Todo',
      routerConfig: _router,
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
    );
  }
}
