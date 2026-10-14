import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../../core/failures.dart';
import '../../data/repositories/note_repository_impl.dart';
import '../../domain/entities/note.dart';
import '../../domain/repositories/note_repository.dart';
import '../../domain/usecases/add_note.dart';
import '../../domain/usecases/get_notes.dart';
import '../../domain/usecases/sync_notes.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SATU-SATUNYA tempat wiring DI untuk fitur notes. Widget tidak pernah
// new Repository() sendiri — semua lewat provider di sini.
// ─────────────────────────────────────────────────────────────────────────────

/// Mode offline (dipakai UI + SyncNotes).
final forceOfflineProvider = StateProvider<bool>((ref) => false);

/// Data layer: repository konkret, disuntikkan db opener (mudah diganti fake
/// saat test).
final noteRepositoryProvider = Provider<NoteRepository>(
  (ref) => NoteRepositoryImpl(),
);

/// Domain layer: use case menerima abstraksi, bukan implementasi.
final getNotesProvider = Provider<GetNotes>(
  (ref) => GetNotes(ref.watch(noteRepositoryProvider)),
);

final addNoteProvider = Provider<AddNote>(
  (ref) => AddNote(ref.watch(noteRepositoryProvider)),
);

final syncNotesProvider = Provider<SyncNotes>(
  (ref) => SyncNotes(ref.watch(noteRepositoryProvider)),
);

/// Presentation layer: state untuk UI.
final notesProvider = AsyncNotifierProvider<NotesNotifier, List<Note>>(
  NotesNotifier.new,
);

class NotesNotifier extends AsyncNotifier<List<Note>> {
  @override
  Future<List<Note>> build() async {
    final result = await ref.watch(getNotesProvider).call();
    if (result.failure != null) throw Exception(result.failure!.message);
    return result.notes;
  }

  Future<Failure?> addNote(String title, String body) async {
    final result = await ref
        .read(addNoteProvider)
        .call(title: title, body: body);
    if (result.failure == null) {
      ref.invalidateSelf();
      await future;
    }
    return result.failure;
  }

  Future<Failure?> deleteNote(int id) async {
    final result = await ref.read(noteRepositoryProvider).deleteNote(id);
    if (result.failure == null) {
      ref.invalidateSelf();
      await future;
    }
    return result.failure;
  }

  /// Sinkronisasi; mengembalikan jumlah tersinkron atau melempar message.
  Future<int> sync({required bool offline}) async {
    final result = await ref.read(syncNotesProvider).call(offline: offline);
    if (result.failure != null) throw Exception(result.failure!.message);
    ref.invalidateSelf();
    await future;
    return result.synced;
  }
}

/// Detail satu catatan berdasarkan id.
final noteByIdProvider = FutureProvider.family<Note?, int>((ref, id) async {
  final result = await ref.watch(noteRepositoryProvider).fetchNote(id);
  if (result.failure != null) throw Exception(result.failure!.message);
  return result.note;
});
