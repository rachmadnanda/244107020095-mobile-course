import 'package:flutter_test/flutter_test.dart';

import 'package:_07_week_7_clean_architecture/core/failures.dart';
import 'package:_07_week_7_clean_architecture/features/notes/domain/entities/note.dart';
import 'package:_07_week_7_clean_architecture/features/notes/domain/repositories/note_repository.dart';
import 'package:_07_week_7_clean_architecture/features/notes/domain/usecases/add_note.dart';

/// Repository palsu yang mencatat apakah addNote pernah dipanggil.
class SpyNoteRepository implements NoteRepository {
  SpyNoteRepository({this.fail = false});

  final bool fail;
  int addCallCount = 0;

  @override
  Future<({Note? note, Failure? failure})> addNote({
    required String title,
    String body = '',
  }) async {
    addCallCount++;
    if (fail) {
      return (note: null, failure: const LocalFailure('db locked (simulasi)'));
    }
    return (
      note: Note(
        id: 1,
        title: title,
        body: body,
        updatedAt: DateTime(2026, 10, 21),
        dirty: true,
      ),
      failure: null,
    );
  }

  @override
  Future<({List<Note> notes, Failure? failure})> fetchNotes() async =>
      (notes: const <Note>[], failure: null);

  @override
  Future<({Note? note, Failure? failure})> fetchNote(int id) async =>
      (note: null, failure: null);

  @override
  Future<({Failure? failure})> deleteNote(int id) async => (failure: null);

  @override
  Future<({int count, Failure? failure})> countDirty() async =>
      (count: 0, failure: null);

  @override
  Future<({Failure? failure})> markAllSynced() async => (failure: null);
}

void main() {
  group('AddNote — validasi judul', () {
    test('judul kosong ditolak dengan ValidationFailure (gagal)', () async {
      final repo = SpyNoteRepository();
      final result = await AddNote(repo).call(title: '');
      expect(result.failure, isA<ValidationFailure>());
      expect(result.note, isNull);
      expect(repo.addCallCount, 0, reason: 'repository tidak boleh dipanggil');
    });

    test(
      'judul hanya spasi ditolak dengan ValidationFailure (gagal)',
      () async {
        final repo = SpyNoteRepository();
        final result = await AddNote(repo).call(title: '   ');
        expect(result.failure, isA<ValidationFailure>());
        expect(repo.addCallCount, 0);
      },
    );

    test(
      'judul valid diteruskan ke repository dalam keadaan ter-trim (sukses)',
      () async {
        final repo = SpyNoteRepository();
        final result = await AddNote(repo).call(title: '  Belanja  ');
        expect(result.failure, isNull);
        expect(result.note?.title, 'Belanja');
        expect(repo.addCallCount, 1);
      },
    );

    test('body ikut dinormalisasi (trim) di use case', () async {
      final repo = SpyNoteRepository();
      final result = await AddNote(repo).call(title: 'A', body: '  isi  ');
      expect(result.failure, isNull);
      expect(result.note?.body, 'isi');
    });

    test('failure dari repository diteruskan tanpa dilempar (gagal)', () async {
      final repo = SpyNoteRepository(fail: true);
      final result = await AddNote(repo).call(title: 'A');
      expect(result.failure, isA<LocalFailure>());
      expect(result.note, isNull);
    });
  });
}
