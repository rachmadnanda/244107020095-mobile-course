import '../../../../core/failures.dart';
import '../entities/note.dart';

/// Kontrak yang dibutuhkan domain untuk fitur catatan.
///
/// Interface tinggal di domain (bukan di data): domain menentukan kebutuhannya,
/// dan data menyediakan implementasinya. Presentation/use case bergantung pada
/// abstraksi ini — sehingga mudah diganti fake saat test, atau diimplementasi
/// ulang dengan sumber data lain.
///
/// Return memakai record `(value, failure)` agar sukses/gagal eksplisit tanpa
/// melempar exception ke presentation.
abstract class NoteRepository {
  Future<({List<Note> notes, Failure? failure})> fetchNotes();

  Future<({Note? note, Failure? failure})> fetchNote(int id);

  Future<({Note? note, Failure? failure})> addNote({
    required String title,
    String body = '',
  });

  Future<({Failure? failure})> deleteNote(int id);

  Future<({int count, Failure? failure})> countDirty();

  Future<({Failure? failure})> markAllSynced();
}
