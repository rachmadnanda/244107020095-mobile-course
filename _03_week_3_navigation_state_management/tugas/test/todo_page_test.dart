import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../lib/pages/todo_page.dart';

void main() {
  testWidgets('user can add a todo', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: TodoPage())),
    );

    await tester.tap(find.byIcon(Icons.add));

    await tester.pumpAndSettle();

    expect(find.text('Tambah Todo'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Kerjakan PR minggu 3');

    await tester.tap(find.text('Tambah'));

    await tester.pumpAndSettle();

    expect(find.text('Kerjakan PR minggu 3'), findsOneWidget);
  });
}
