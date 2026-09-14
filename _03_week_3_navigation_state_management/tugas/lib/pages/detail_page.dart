import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/todo_provider.dart';

class DetailPage extends ConsumerWidget {
  const DetailPage({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todos = ref.watch(todoListProvider);

    final index = int.tryParse(id);

    if (index == null || index < 0 || index >= todos.length) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detail')),
        body: const Center(child: Text('Todo tidak ditemukan')),
      );
    }

    final todo = todos[index];

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Todo')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(todo.title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            Text(todo.done ? 'Status: Selesai' : 'Status: Belum selesai'),
          ],
        ),
      ),
    );
  }
}
