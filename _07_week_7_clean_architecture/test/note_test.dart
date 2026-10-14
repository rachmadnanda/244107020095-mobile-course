import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:_07_week_7_clean_architecture/core/failures.dart';
import 'package:_07_week_7_clean_architecture/features/notes/data/local/note_model.dart';
import 'package:_07_week_7_clean_architecture/features/notes/domain/entities/note.dart';
import 'package:_07_week_7_clean_architecture/features/notes/domain/repositories/note_repository.dart';
import 'package:_07_week_7_clean_architecture/features/notes/domain/usecases/get_notes.dart';
import 'package:_07_week_7_clean_architecture/features/notes/domain/usecases/sync_notes.dart';
import 'package:_07_week_7_clean_architecture/features/notes/presentation/providers/notes_providers.dart';

/// Repository palsu — tanpa SQLite, tanpa Dio, tanpa Firebase.
class FakeNoteRepository implements NoteRepository {
  FakeNoteRepository({this.items = const [], this.fail = false});

  final List<Note> items;
  final bool fail;

  @override
  Future<({List<Note> notes, Failure? failure})> fetchNotes() async {
    if (fail) {
      return (notes: const <Note>[], failure: const LocalFailure('db locked (simulasi)'));
    }
    return (notes: items, failure: null);
  }

  @override
  Future<({Note? note, Failure? failure})> fetchNote(int id) async =>
      (note: items.isEmpty ? null : items.first, failure: null);

  @override
  Future<({Note? note, Failure? failure})> addNote({
    required String title,
    String body = '',
  }) async {
    if (fail) return (note: null, failure: const LocalFailure('gagal simpan'));
    final note = Note(id: items.length + 1, title: title, body: body, updatedAt: DateTime(2026, 9, 27), dirty: true);
    return (note: note, failure: null);
  }

  @override
  Future<({Failure? failure})> deleteNote(int id) async => (failure: null,);

  @override
  Future<({int count, Failure? failure})> countDirty() async {
    if (fail) return (count: 0, failure: const LocalFailure('db locked (simulasi)'));
    return (count: items.where((n) => n.dirty).length, failure: null);
  }

  @override
  Future<({Failure? failure})> markAllSynced() async => (failure: null,);
}

void main() {
  test('NoteModel.fromMap aman terhadap field yang hilang', () {
    final note = NoteModel.fromMap({'title': 'Belanja'});
    expect(note.title, 'Belanja');
    expect(note.body, '');
    expect(note.dirty, isFalse);
  });

  test('flag dirty bertahan pada serialisasi (round-trip)', () {
    final note = NoteModel(
      title: 'a',
      updatedAt: DateTime(2026, 9, 18),
      dirty: true,
    );
    final restored = NoteModel.fromMap(note.toMap());
    expect(restored.dirty, isTrue);
    expect(restored.toEntity().dirty, isTrue);
  });

  test('GetNotes meneruskan daftar dari repository (sukses)', () async {
    final repo = FakeNoteRepository(items: [
      Note(title: 'A', updatedAt: DateTime(2026, 9, 27)),
    ]);
    final result = await GetNotes(repo).call();
    expect(result.failure, isNull);
    expect(result.notes.length, 1);
    expect(result.notes.first.title, 'A');
  });

  test('GetNotes meneruskan failure tanpa melempar (gagal)', () async {
    final repo = FakeNoteRepository(fail: true);
    final result = await GetNotes(repo).call();
    expect(result.failure, isA<LocalFailure>());
    expect(result.notes, isEmpty);
  });

  test('SyncNotes menolak saat offline (failure)', () async {
    final repo = FakeNoteRepository(items: [
      Note(title: 'A', updatedAt: DateTime(2026, 9, 27), dirty: true),
    ]);
    final result = await SyncNotes(repo).call(offline: true);
    expect(result.failure, isA<NetworkFailure>());
    expect(result.synced, 0);
  });

  test('SyncNotes menghitung yang tersinkron (sukses)', () async {
    final repo = FakeNoteRepository(items: [
      Note(title: 'A', updatedAt: DateTime(2026, 9, 27), dirty: true),
      Note(title: 'B', updatedAt: DateTime(2026, 9, 27), dirty: true),
    ]);
    final result = await SyncNotes(repo).call();
    expect(result.failure, isNull);
    expect(result.synced, 2);
  });

  test('notesProvider sukses dengan repository palsu', () async {
    final container = ProviderContainer(overrides: [
      noteRepositoryProvider.overrideWithValue(
        FakeNoteRepository(items: [Note(title: 'Tes', updatedAt: DateTime.now())]),
      ),
    ]);
    addTearDown(container.dispose);
    final notes = await container.read(notesProvider.future);
    expect(notes.length, 1);
    expect(notes.first.title, 'Tes');
  });
}
