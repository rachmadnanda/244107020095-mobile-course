import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:_07_week_7_clean_architecture/features/notes/domain/entities/note.dart';
import 'package:_07_week_7_clean_architecture/features/notes/presentation/widgets/note_tile.dart';

void main() {
  testWidgets('NoteTile menampilkan badge dirty', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NoteTile(
            note: Note(
              title: 'Offline',
              body: 'Isi',
              updatedAt: DateTime(2026, 9, 28),
              dirty: true,
            ),
            onTap: () {},
            onDelete: () {},
          ),
        ),
      ),
    );

    expect(find.text('Offline'), findsOneWidget);
    expect(find.text('Belum tersinkron'), findsOneWidget);
  });
}
