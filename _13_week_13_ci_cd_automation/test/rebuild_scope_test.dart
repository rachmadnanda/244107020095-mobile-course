import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:week_13_ci_cd_automation/features/notes/domain/entities/note.dart';
import 'package:week_13_ci_cd_automation/features/notes/presentation/pages/notes_page.dart';
import 'package:week_13_ci_cd_automation/features/notes/presentation/providers/notes_providers.dart';

import 'helpers/fake_note_repository.dart';

Widget _app(FakeNoteRepository repository) {
  return ProviderScope(
    overrides: [noteRepositoryProvider.overrideWithValue(repository)],
    child: const MaterialApp(home: NotesPage()),
  );
}

void main() {
  testWidgets('mengetik pencarian tidak membangun ulang AppBar/FAB', (
    tester,
  ) async {
    final repository = FakeNoteRepository(
      notes: [
        Note(id: 1, title: 'Belanja Bulanan', updatedAt: DateTime(2026, 1, 1)),
        Note(id: 2, title: 'Bumi Manusia', updatedAt: DateTime(2026, 1, 2)),
      ],
    );

    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();

    final fabBefore = tester.widget<FloatingActionButton>(
      find.byType(FloatingActionButton),
    );
    final syncFinder = find.ancestor(
      of: find.byIcon(Icons.sync),
      matching: find.byType(IconButton),
    );
    final syncBefore = tester.widget<IconButton>(syncFinder);

    await tester.enterText(find.byType(TextField), 'bumi');
    await tester.pumpAndSettle();

    expect(find.text('Bumi Manusia'), findsOneWidget);
    expect(find.text('Belanja Bulanan'), findsNothing);

    final fabAfter = tester.widget<FloatingActionButton>(
      find.byType(FloatingActionButton),
    );
    final syncAfter = tester.widget<IconButton>(syncFinder);

    // Instance yang sama membuktikan root halaman tidak ikut rebuild.
    expect(identical(fabBefore, fabAfter), isTrue);
    expect(identical(syncBefore, syncAfter), isTrue);
  });

  testWidgets('query kosong mengembalikan seluruh daftar', (tester) async {
    final repository = FakeNoteRepository(
      notes: [
        Note(id: 1, title: 'Belanja Bulanan', updatedAt: DateTime(2026, 1, 1)),
        Note(id: 2, title: 'Bumi Manusia', updatedAt: DateTime(2026, 1, 2)),
      ],
    );

    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'bumi');
    await tester.pumpAndSettle();
    expect(find.text('Belanja Bulanan'), findsNothing);

    await tester.enterText(find.byType(TextField), '');
    await tester.pumpAndSettle();
    expect(find.text('Belanja Bulanan'), findsOneWidget);
    expect(find.text('Bumi Manusia'), findsOneWidget);
  });
}
