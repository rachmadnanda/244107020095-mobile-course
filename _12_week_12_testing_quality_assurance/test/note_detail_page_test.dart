import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:week_12_testing_quality_assurance/core/failures.dart';
import 'package:week_12_testing_quality_assurance/features/notes/domain/entities/note.dart';
import 'package:week_12_testing_quality_assurance/features/notes/presentation/pages/note_detail_page.dart';
import 'package:week_12_testing_quality_assurance/features/notes/presentation/providers/notes_providers.dart';

import 'helpers/fake_note_repository.dart';

void main() {
  Widget buildPage(FakeNoteRepository repository) {
    return ProviderScope(
      overrides: [noteRepositoryProvider.overrideWithValue(repository)],
      child: const MaterialApp(home: NoteDetailPage(noteId: 1)),
    );
  }

  group('NoteDetailPage', () {
    testWidgets('menampilkan judul, isi, dan status dirty', (tester) async {
      final repository = FakeNoteRepository(
        notes: [
          Note(
            id: 1,
            title: 'Belanja',
            body: 'susu dan telur',
            updatedAt: DateTime(2026, 11, 19),
            dirty: true,
          ),
        ],
      );

      await tester.pumpWidget(buildPage(repository));
      await tester.pumpAndSettle();

      expect(find.text('Detail Catatan'), findsOneWidget);
      expect(find.text('Belanja'), findsOneWidget);
      expect(find.text('susu dan telur'), findsOneWidget);
      expect(find.text('Belum tersinkron'), findsOneWidget);
      expect(repository.fetchNoteCalls, 1);
    });

    testWidgets('menampilkan pesan saat catatan tidak ditemukan', (
      tester,
    ) async {
      final repository = FakeNoteRepository();

      await tester.pumpWidget(buildPage(repository));
      await tester.pumpAndSettle();

      expect(find.text('Catatan tidak ditemukan'), findsOneWidget);
    });

    testWidgets('menampilkan pesan error saat repository gagal', (
      tester,
    ) async {
      final repository = FakeNoteRepository(
        fetchNoteFailure: const LocalFailure('Gagal membaca catatan: db rusak'),
      );

      await tester.pumpWidget(buildPage(repository));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Gagal membaca catatan: db rusak'),
        findsOneWidget,
      );
    });
  });
}
