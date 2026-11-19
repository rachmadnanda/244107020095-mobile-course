import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:week_12_testing_quality_assurance/core/failures.dart';
import 'package:week_12_testing_quality_assurance/features/notes/presentation/pages/notes_page.dart';
import 'package:week_12_testing_quality_assurance/features/notes/presentation/providers/notes_providers.dart';

import 'helpers/fake_note_repository.dart';

void main() {
  late FakeNoteRepository repository;

  Widget buildApp() {
    return ProviderScope(
      overrides: [noteRepositoryProvider.overrideWithValue(repository)],
      child: const MaterialApp(home: NotesPage()),
    );
  }

  Future<void> openAddDialog(WidgetTester tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('add-note-fab')));
    await tester.pumpAndSettle();
  }

  group('AddNoteDialog', () {
    setUp(() {
      repository = FakeNoteRepository();
    });

    testWidgets('menampilkan dialog dan field kosong saat dibuka', (
      tester,
    ) async {
      await openAddDialog(tester);

      expect(find.text('Tambah Catatan'), findsOneWidget);
      expect(find.byKey(const Key('note-title-field')), findsOneWidget);
      expect(find.byKey(const Key('note-body-field')), findsOneWidget);

      final titleField = tester.widget<TextField>(
        find.byKey(const Key('note-title-field')),
      );
      final bodyField = tester.widget<TextField>(
        find.byKey(const Key('note-body-field')),
      );
      expect(titleField.controller?.text, isEmpty);
      expect(bodyField.controller?.text, isEmpty);
    });

    testWidgets('judul kosong ditolak dan dialog tetap terbuka', (
      tester,
    ) async {
      await openAddDialog(tester);

      await tester.enterText(find.byKey(const Key('note-title-field')), '   ');
      await tester.tap(find.byKey(const Key('save-note-button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Judul catatan tidak boleh kosong'), findsOneWidget);
      expect(find.text('Tambah Catatan'), findsOneWidget);
      expect(repository.addNoteCalls, 0);
    });

    testWidgets('judul valid menyimpan catatan lalu menutup dialog', (
      tester,
    ) async {
      await openAddDialog(tester);

      await tester.enterText(
        find.byKey(const Key('note-title-field')),
        '  Belanja  ',
      );
      await tester.enterText(
        find.byKey(const Key('note-body-field')),
        '  susu dan telur  ',
      );
      await tester.tap(find.byKey(const Key('save-note-button')));
      await tester.pumpAndSettle();

      expect(find.text('Tambah Catatan'), findsNothing);
      expect(find.text('Belanja'), findsOneWidget);
      expect(repository.addNoteCalls, 1);
      expect(repository.notes.single.title, 'Belanja');
      expect(repository.notes.single.body, 'susu dan telur');
    });

    testWidgets('kegagalan repository menampilkan pesan dan state tetap', (
      tester,
    ) async {
      repository = FakeNoteRepository(
        addFailure: const LocalFailure('Gagal menyimpan catatan: db penuh'),
      );
      await openAddDialog(tester);

      await tester.enterText(
        find.byKey(const Key('note-title-field')),
        'Catatan gagal',
      );
      await tester.tap(find.byKey(const Key('save-note-button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Gagal menyimpan catatan: db penuh'), findsOneWidget);
      expect(find.text('Tambah Catatan'), findsOneWidget);
      expect(repository.addNoteCalls, 1);
      expect(repository.notes, isEmpty);
    });
  });
}
