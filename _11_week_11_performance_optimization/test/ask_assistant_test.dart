import 'package:flutter_test/flutter_test.dart';

import 'package:week_11_performance_optimization/core/failures.dart';
import 'package:week_11_performance_optimization/features/assistant/domain/repositories/ai_assistant_repository.dart';
import 'package:week_11_performance_optimization/features/assistant/domain/usecases/ask_assistant.dart';
import 'package:week_11_performance_optimization/features/notes/domain/entities/note.dart';

/// Repository AI palsu yang merekam prompt yang diterimanya.
class _SpyAiRepository implements AiAssistantRepository {
  _SpyAiRepository({this.fail = false});

  final bool fail;
  String? lastSystemPrompt;
  String? lastUserPrompt;
  int callCount = 0;

  @override
  Future<({String? answer, Failure? failure})> ask({
    required String systemPrompt,
    required String userPrompt,
  }) async {
    callCount++;
    lastSystemPrompt = systemPrompt;
    lastUserPrompt = userPrompt;
    if (fail) {
      return (answer: null, failure: const AiFailure('kuota habis'));
    }
    return (answer: 'Jawaban palsu', failure: null);
  }

  @override
  Future<bool> hasApiKey() async => true;
}

Note _note(String title, String body) =>
    Note(title: title, body: body, updatedAt: DateTime(2026, 11, 4));

void main() {
  group('AskAssistant — validasi', () {
    test('pertanyaan kosong ditolak tanpa memanggil API', () async {
      final repo = _SpyAiRepository();
      final result = await AskAssistant(repo).call(question: '   ', notes: []);

      expect(result.failure, isA<ValidationFailure>());
      expect(result.answer, isNull);
      expect(repo.callCount, 0, reason: 'API tidak boleh dipanggil');
    });
  });

  group('AskAssistant — penyusunan prompt', () {
    test('system prompt berisi batas bahasa dan larangan mengarang', () async {
      final repo = _SpyAiRepository();
      await AskAssistant(repo).call(question: 'Apa catatanku?', notes: []);

      expect(repo.lastSystemPrompt, contains('Bahasa Indonesia'));
      expect(repo.lastSystemPrompt, contains('hanya berdasarkan catatan'));
      expect(repo.lastSystemPrompt, contains('Jangan mengarang'));
    });

    test('konteks catatan ikut dikirim ke prompt', () async {
      final repo = _SpyAiRepository();
      await AskAssistant(repo).call(
        question: 'Apa isi belanja?',
        notes: [_note('Belanja', 'susu dan telur')],
      );

      expect(repo.lastUserPrompt, contains('Belanja: susu dan telur'));
      expect(repo.lastUserPrompt, contains('Pertanyaan: Apa isi belanja?'));
    });

    test('tanpa catatan, prompt menyatakan belum ada catatan', () async {
      final repo = _SpyAiRepository();
      await AskAssistant(repo).call(question: 'Ringkas', notes: []);

      expect(repo.lastUserPrompt, contains('belum ada catatan'));
    });

    test('hanya mengirim maksimal 5 catatan (kendali biaya)', () async {
      final repo = _SpyAiRepository();
      await AskAssistant(repo).call(
        question: 'Ringkas',
        notes: List.generate(8, (i) => _note('Catatan $i', 'isi $i')),
      );

      expect(repo.lastUserPrompt, contains('Catatan 4'));
      expect(repo.lastUserPrompt, isNot(contains('Catatan 5')));
    });

    test('konteks catatan dipotong bila terlalu panjang', () async {
      final repo = _SpyAiRepository();
      await AskAssistant(repo)
          .call(question: 'Ringkas', notes: [_note('Panjang', 'kata ' * 1000)]);

      expect(repo.lastUserPrompt, contains('… (dipotong)'));
    });
  });

  group('AskAssistant — privasi', () {
    test('data pribadi di pertanyaan diredaksi sebelum dikirim', () async {
      final repo = _SpyAiRepository();
      await AskAssistant(
        repo,
      ).call(question: 'Email saya budi@gmail.com, apa catatanku?', notes: []);

      expect(repo.lastUserPrompt, isNot(contains('budi@gmail.com')));
      expect(repo.lastUserPrompt, contains('[email]'));
    });

    test('data pribadi di isi catatan juga diredaksi', () async {
      final repo = _SpyAiRepository();
      await AskAssistant(repo).call(
        question: 'Ringkas',
        notes: [_note('Kontak', 'NIK 3573012504950001')],
      );

      expect(repo.lastUserPrompt, isNot(contains('3573012504950001')));
      expect(repo.lastUserPrompt, contains('[nik]'));
    });
  });

  group('AskAssistant — hasil', () {
    test('meneruskan jawaban repository (sukses)', () async {
      final repo = _SpyAiRepository();
      final result = await AskAssistant(repo).call(question: 'Halo', notes: []);

      expect(result.failure, isNull);
      expect(result.answer, 'Jawaban palsu');
    });

    test('meneruskan failure tanpa melempar (gagal)', () async {
      final repo = _SpyAiRepository(fail: true);
      final result = await AskAssistant(repo).call(question: 'Halo', notes: []);

      expect(result.failure, isA<AiFailure>());
      expect(result.answer, isNull);
    });
  });
}
