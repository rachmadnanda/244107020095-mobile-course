import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:_07_week_7_clean_architecture/core/failures.dart';
import 'package:_07_week_7_clean_architecture/features/notes/domain/entities/note.dart';
import 'package:_07_week_7_clean_architecture/features/notes/domain/repositories/note_repository.dart';
import 'package:_07_week_7_clean_architecture/features/notes/presentation/pages/notes_page.dart';
import 'package:_07_week_7_clean_architecture/features/notes/presentation/providers/notes_providers.dart';

/// Repository palsu minimal untuk widget test (tanpa SQLite).
class _FakeRepo implements NoteRepository {
  _FakeRepo(this.items);

  final List<Note> items;

  @override
  Future<({List<Note> notes, Failure? failure})> fetchNotes() async =>
      (notes: items, failure: null);

  @override
  Future<({Note? note, Failure? failure})> fetchNote(int id) async =>
      (note: null, failure: null);

  @override
  Future<({Note? note, Failure? failure})> addNote({
    required String title,
    String body = '',
  }) async => (note: null, failure: null);

  @override
  Future<({Failure? failure})> deleteNote(int id) async => (failure: null);

  @override
  Future<({int count, Failure? failure})> countDirty() async =>
      (count: 0, failure: null);

  @override
  Future<({Failure? failure})> markAllSynced() async => (failure: null);
}

Widget _app(List<Note> items) => ProviderScope(
  overrides: [noteRepositoryProvider.overrideWithValue(_FakeRepo(items))],
  child: const MaterialApp(home: NotesPage()),
);

void main() {
  final sample = [
    Note(title: 'Belanja Bulanan', updatedAt: DateTime(2026, 10, 21)),
    Note(title: 'Bumi Manusia', updatedAt: DateTime(2026, 10, 22)),
  ];

  testWidgets('empty state muncul saat query tidak cocok', (tester) async {
    await tester.pumpWidget(_app(sample));
    await tester.pumpAndSettle();

    expect(find.text('Belanja Bulanan'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'zzz-tak-ada');
    await tester.pumpAndSettle();

    expect(
      find.text('Tidak ada catatan yang cocok dengan "zzz-tak-ada"'),
      findsOneWidget,
    );
    expect(find.text('Belanja Bulanan'), findsNothing);
  });

  testWidgets('pencarian case-insensitive menyaring daftar', (tester) async {
    await tester.pumpWidget(_app(sample));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'BUMI');
    await tester.pumpAndSettle();

    expect(find.text('Bumi Manusia'), findsOneWidget);
    expect(find.text('Belanja Bulanan'), findsNothing);
  });

  testWidgets('tombol clear mengembalikan seluruh daftar', (tester) async {
    await tester.pumpWidget(_app(sample));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'bumi');
    await tester.pumpAndSettle();
    expect(find.text('Belanja Bulanan'), findsNothing);

    await tester.tap(find.byTooltip('Hapus pencarian'));
    await tester.pumpAndSettle();

    expect(find.text('Belanja Bulanan'), findsOneWidget);
    expect(find.text('Bumi Manusia'), findsOneWidget);

    // Temuan AI #1: tombol clear harus benar-benar mengosongkan isi field,
    // bukan hanya state provider.
    final editable = tester.widget<EditableText>(find.byType(EditableText));
    expect(editable.controller.text, isEmpty);
  });

  testWidgets('empty state "Belum ada catatan" saat data kosong', (
    tester,
  ) async {
    await tester.pumpWidget(_app(const []));
    await tester.pumpAndSettle();

    expect(find.text('Belum ada catatan'), findsOneWidget);
  });
}
