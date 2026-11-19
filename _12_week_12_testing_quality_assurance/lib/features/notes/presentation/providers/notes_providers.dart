import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../../core/failures.dart';
import '../../data/repositories/note_repository_impl.dart';
import '../../domain/entities/note.dart';
import '../../domain/repositories/note_repository.dart';
import '../../domain/usecases/add_note.dart';
import '../../domain/usecases/get_notes.dart';
import '../../domain/usecases/search_notes.dart';
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

/// Use case pencarian: murni, tidak butuh repository.
final searchNotesProvider = Provider<SearchNotes>((ref) => const SearchNotes());

/// State query pencarian (dipakai UI + filteredNotesProvider).
final searchQueryProvider = StateProvider<String>((ref) => '');

/// Daftar catatan setelah difilter use case `SearchNotes`.
final filteredNotesProvider = Provider<AsyncValue<List<Note>>>((ref) {
  final notes = ref.watch(notesProvider);
  final query = ref.watch(searchQueryProvider);
  final search = ref.watch(searchNotesProvider);
  return notes.whenData((items) => search(items, query));
});

/// Bernilai true bila database punya catatan — dipakai membedakan empty state
/// "belum ada catatan" dari "tidak ada hasil pencarian".
///
/// Nilainya `bool`, jadi listener hanya dibangun ulang saat status berubah,
/// bukan setiap daftar catatan berubah.
final hasAnyNotesProvider = Provider<bool>((ref) {
  return ref.watch(notesProvider).value?.isNotEmpty ?? false;
});

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
    final note = result.note;
    if (result.failure == null && note != null) {
      // Perbarui state di memori; tidak perlu membaca ulang seluruh tabel.
      final current = state.value ?? const <Note>[];
      final next = [note, ...current]
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      state = AsyncData(next);
    }
    return result.failure;
  }

  Future<Failure?> deleteNote(int id) async {
    final result = await ref.read(noteRepositoryProvider).deleteNote(id);
    if (result.failure == null) {
      final current = state.value ?? const <Note>[];
      state = AsyncData(
        current.where((note) => note.id != id).toList(growable: false),
      );
    }
    return result.failure;
  }

  /// Sinkronisasi; mengembalikan jumlah tersinkron atau melempar message.
  Future<int> sync({required bool offline}) async {
    final result = await ref.read(syncNotesProvider).call(offline: offline);
    if (result.failure != null) throw Exception(result.failure!.message);

    final current = state.value;
    if (current != null && result.synced > 0) {
      state = AsyncData([
        for (final note in current)
          note.dirty ? note.copyWith(dirty: false) : note,
      ]);
    }
    return result.synced;
  }
}

/// Detail satu catatan berdasarkan id.
///
/// `isAutoDispose: true` penting untuk memori: tanpa itu, setiap id yang
/// pernah dibuka akan tersimpan selamanya di container provider.
final noteByIdProvider = FutureProvider.family<Note?, int>((ref, id) async {
  final result = await ref.watch(noteRepositoryProvider).fetchNote(id);
  if (result.failure != null) throw Exception(result.failure!.message);
  return result.note;
}, isAutoDispose: true);
