import '../../../../core/failures.dart';
import '../entities/note.dart';
import '../repositories/note_repository.dart';

/// Use case: menambah catatan baru.
class AddNote {
  const AddNote(this._repository);

  final NoteRepository _repository;

  Future<({Note? note, Failure? failure})> call({
    required String title,
    String body = '',
  }) {
    return _repository.addNote(title: title, body: body);
  }
}
