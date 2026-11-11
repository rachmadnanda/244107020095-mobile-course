import 'package:week_11_performance_optimization/core/failures.dart';
import 'package:week_11_performance_optimization/features/notes/domain/entities/note.dart';
import 'package:week_11_performance_optimization/features/notes/domain/repositories/note_repository.dart';

/// Repository palsu yang bisa menghitung pemanggilan, untuk membuktikan
/// optimasi tidak memicu query ulang.
class FakeNoteRepository implements NoteRepository {
  FakeNoteRepository({List<Note>? notes, this.dirtyCount = 0})
    : notes = notes ?? <Note>[];

  final List<Note> notes;
  int dirtyCount;

  int fetchNotesCalls = 0;
  int fetchNoteCalls = 0;
  int addNoteCalls = 0;
  int deleteNoteCalls = 0;
  int countDirtyCalls = 0;
  int markAllSyncedCalls = 0;

  final List<int> deletedIds = [];

  @override
  Future<({List<Note> notes, Failure? failure})> fetchNotes() async {
    fetchNotesCalls++;
    return (notes: List<Note>.from(notes), failure: null);
  }

  @override
  Future<({Note? note, Failure? failure})> fetchNote(int id) async {
    fetchNoteCalls++;
    for (final note in notes) {
      if (note.id == id) return (note: note, failure: null);
    }
    return (note: null, failure: null);
  }

  @override
  Future<({Note? note, Failure? failure})> addNote({
    required String title,
    String body = '',
  }) async {
    addNoteCalls++;
    final note = Note(
      id: 1000 + notes.length,
      title: title,
      body: body,
      updatedAt: DateTime.now(),
      dirty: true,
    );
    notes.add(note);
    return (note: note, failure: null);
  }

  @override
  Future<({Failure? failure})> deleteNote(int id) async {
    deleteNoteCalls++;
    deletedIds.add(id);
    notes.removeWhere((note) => note.id == id);
    return (failure: null);
  }

  @override
  Future<({int count, Failure? failure})> countDirty() async {
    countDirtyCalls++;
    return (count: dirtyCount, failure: null);
  }

  @override
  Future<({Failure? failure})> markAllSynced() async {
    markAllSyncedCalls++;
    dirtyCount = 0;
    for (var i = 0; i < notes.length; i++) {
      notes[i] = notes[i].copyWith(dirty: false);
    }
    return (failure: null);
  }
}
