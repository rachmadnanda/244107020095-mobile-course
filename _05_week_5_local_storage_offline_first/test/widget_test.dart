import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:_05_week_5_local_storage_offline_first/data/local/note.dart';
import 'package:_05_week_5_local_storage_offline_first/widgets/note_tile.dart';

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
