import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/todo_filter_provider.dart';
import '../providers/todo_provider.dart';
import '../widgets/todo_tile.dart';

class TodoPage extends ConsumerWidget {
  const TodoPage({super.key});

  void _showAddTodoDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Tambah Todo'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(labelText: 'Judul tugas'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                final title = controller.text.trim();

                if (title.isNotEmpty) {
                  ref.read(todoListProvider.notifier).add(title);
                }

                Navigator.pop(context);
              },
              child: const Text('Tambah'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todos = ref.watch(filteredTodoProvider);
    final filter = ref.watch(todoFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Todo List'),
        actions: [
          PopupMenuButton<TodoFilter>(
            initialValue: filter,
            onSelected: (value) {
              ref.read(todoFilterProvider.notifier).setFilter(value);
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: TodoFilter.all, child: Text('Semua')),
              PopupMenuItem(
                value: TodoFilter.completed,
                child: Text('Selesai'),
              ),
              PopupMenuItem(
                value: TodoFilter.incomplete,
                child: Text('Belum selesai'),
              ),
            ],
          ),
        ],
      ),
      body: todos.isEmpty
          ? const Center(child: Text('Belum ada tugas'))
          : ListView.builder(
              itemCount: todos.length,
              itemBuilder: (context, index) {
                final todo = todos[index];

                return TodoTile(
                  todo: todo,
                  onToggle: () {
                    final allTodos = ref.read(todoListProvider);

                    final originalIndex = allTodos.indexOf(todo);

                    ref.read(todoListProvider.notifier).toggle(originalIndex);
                  },
                  onDelete: () {
                    final allTodos = ref.read(todoListProvider);

                    final originalIndex = allTodos.indexOf(todo);

                    ref.read(todoListProvider.notifier).remove(originalIndex);
                  },
                  onTap: () {
                    final allTodos = ref.read(todoListProvider);

                    final originalIndex = allTodos.indexOf(todo);

                    context.push('/detail/$originalIndex');
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddTodoDialog(context, ref);
        },
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        onDestinationSelected: (index) {
          if (index == 1) {
            context.go('/stats');
          }
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.checklist), label: 'Todo'),
          NavigationDestination(
            icon: Icon(Icons.bar_chart),
            label: 'Statistik',
          ),
        ],
      ),
    );
  }
}
