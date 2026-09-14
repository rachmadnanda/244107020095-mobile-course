import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'todo_provider.dart';

class StatsNotifier extends AsyncNotifier<List<String>> {
  @override
  Future<List<String>> build() async {
    await Future.delayed(const Duration(seconds: 2));

    final todos = ref.watch(todoListProvider);

    final total = todos.length;
    final completed = todos.where((todo) => todo.done).length;
    final incomplete = total - completed;

    return [
      'Total tugas: $total',
      'Tugas selesai: $completed',
      'Tugas belum selesai: $incomplete',
    ];
  }

  Future<void> refresh() async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      await Future.delayed(const Duration(seconds: 2));

      final todos = ref.read(todoListProvider);

      final total = todos.length;
      final completed = todos.where((todo) => todo.done).length;
      final incomplete = total - completed;

      return [
        'Total tugas: $total',
        'Tugas selesai: $completed',
        'Tugas belum selesai: $incomplete',
      ];
    });
  }
}

final statsProvider = AsyncNotifierProvider<StatsNotifier, List<String>>(
  StatsNotifier.new,
);
