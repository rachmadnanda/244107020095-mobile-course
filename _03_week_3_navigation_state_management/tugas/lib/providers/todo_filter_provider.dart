import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/todo.dart';
import 'todo_provider.dart';

enum TodoFilter { all, completed, incomplete }

class TodoFilterNotifier extends Notifier<TodoFilter> {
  @override
  TodoFilter build() {
    return TodoFilter.all;
  }

  void setFilter(TodoFilter filter) {
    state = filter;
  }
}

final todoFilterProvider = NotifierProvider<TodoFilterNotifier, TodoFilter>(
  TodoFilterNotifier.new,
);

final filteredTodoProvider = Provider<List<Todo>>((ref) {
  final todos = ref.watch(todoListProvider);
  final filter = ref.watch(todoFilterProvider);

  switch (filter) {
    case TodoFilter.all:
      return todos;

    case TodoFilter.completed:
      return todos.where((todo) => todo.done).toList();

    case TodoFilter.incomplete:
      return todos.where((todo) => !todo.done).toList();
  }
});
