import '../../../../core/failures.dart';
import '../../../notes/domain/entities/note.dart';
import '../repositories/ai_assistant_repository.dart';
import '../services/privacy_guard.dart';

/// Use case: menyusun prompt dan meminta jawaban AI berdasarkan catatan
/// pengguna.
///
/// Catatan diterima sebagai parameter (bukan lewat `NoteRepository`) supaya
/// use case ini murni: hasilnya hanya bergantung pada (catatan, pertanyaan).
/// Efek sampingnya mudah diuji tanpa SQLite dan tanpa jaringan.
class AskAssistant {
  const AskAssistant(this._repository, {this._guard = const PrivacyGuard()});

  final AiAssistantRepository _repository;
  final PrivacyGuard _guard;

  /// System prompt: persona + batas. Diminta singkat dan berbahasa Indonesia
  /// agar jawaban hemat token dan konsisten.
  static const systemPrompt =
      'Kamu asisten catatan pribadi yang ramah. Jawab dalam Bahasa Indonesia, '
      'maksimal 3 kalimat, hanya berdasarkan catatan yang diberikan. '
      'Jika jawabannya tidak ada di catatan, katakan bahwa datanya tidak ada. '
      'Jangan mengarang isi catatan dan jangan meminta data pribadi.';

  /// Batas jumlah catatan yang dikirim (kendali biaya).
  static const maxNotes = 5;

  Future<({String? answer, Failure? failure})> call({
    required String question,
    required List<Note> notes,
  }) async {
    final cleanQuestion = _guard.sanitize(question);
    if (cleanQuestion.isEmpty) {
      return (
        answer: null,
        failure: const ValidationFailure('Pertanyaan tidak boleh kosong'),
      );
    }

    final userPrompt = _buildUserPrompt(cleanQuestion, notes);
    return _repository.ask(systemPrompt: systemPrompt, userPrompt: userPrompt);
  }

  /// Menggabungkan konteks catatan + pertanyaan pengguna menjadi satu prompt.
  String _buildUserPrompt(String question, List<Note> notes) {
    final buffer = StringBuffer();

    if (notes.isEmpty) {
      buffer.writeln('Catatan pengguna: (belum ada catatan)');
    } else {
      buffer.writeln('Catatan pengguna:');
      for (final note in notes.take(maxNotes)) {
        final title = _guard.sanitize(note.title);
        final body = _guard.trimContext(_guard.sanitize(note.body));
        buffer.writeln('- $title: $body');
      }
    }

    buffer.writeln();
    buffer.writeln('Pertanyaan: $question');
    return buffer.toString().trim();
  }
}
