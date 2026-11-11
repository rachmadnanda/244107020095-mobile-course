import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:week_11_performance_optimization/core/failures.dart';
import 'package:week_11_performance_optimization/features/assistant/domain/repositories/ai_assistant_repository.dart';
import 'package:week_11_performance_optimization/features/assistant/presentation/providers/assistant_providers.dart';
import 'package:week_11_performance_optimization/features/notes/domain/entities/note.dart';
import 'package:week_11_performance_optimization/features/notes/domain/repositories/note_repository.dart';
import 'package:week_11_performance_optimization/features/notes/presentation/providers/notes_providers.dart';

/// Catatan kosong: test ini fokus pada perilaku pengiriman, bukan isi prompt.
class _FakeNotes implements NoteRepository {
  @override
  Future<({List<Note> notes, Failure? failure})> fetchNotes() async =>
      (notes: const <Note>[], failure: null);

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

/// Repository AI palsu dengan latensi yang bisa diatur per panggilan.
class _FakeAi implements AiAssistantRepository {
  _FakeAi({this.delay = Duration.zero, this.failure});

  final Duration delay;
  final Failure? failure;
  int callCount = 0;

  @override
  Future<({String? answer, Failure? failure})> ask({
    required String systemPrompt,
    required String userPrompt,
  }) async {
    callCount++;
    final mine = callCount;
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    if (failure != null) return (answer: null, failure: failure);
    return (answer: 'jawaban-$mine', failure: null);
  }

  @override
  Future<bool> hasApiKey() async => true;
}

ProviderContainer _container(AiAssistantRepository ai) {
  final container = ProviderContainer(
    overrides: [
      noteRepositoryProvider.overrideWithValue(_FakeNotes()),
      aiAssistantRepositoryProvider.overrideWithValue(ai),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  test(
    'satu pertanyaan menghasilkan satu bubble user dan satu jawaban',
    () async {
      final ai = _FakeAi();
      final container = _container(ai);

      await container.read(chatProvider.notifier).send('Halo');

      final messages = container.read(chatProvider).value!;
      expect(messages.length, 2);
      expect(messages[0].isUser, isTrue);
      expect(messages[1].text, 'jawaban-1');
    },
  );

  // Regresi: dua pengiriman tumpang tindih sempat mengirim dua request
  // (dua kali biaya) tetapi jawaban pertama hilang karena state ditimpa
  // snapshot yang lebih lama.
  test('pengiriman tumpang tindih tidak menggandakan request', () async {
    final ai = _FakeAi(delay: const Duration(milliseconds: 100));
    final container = _container(ai);

    final notifier = container.read(chatProvider.notifier);
    await Future.wait([
      notifier.send('Ringkas semua catatanku'),
      notifier.send('Ringkas semua catatanku'),
    ]);

    final messages = container.read(chatProvider).value!;
    final answers = messages.where((m) => !m.isUser).toList();

    expect(
      ai.callCount,
      1,
      reason: 'satu pertanyaan tidak boleh jadi dua request',
    );
    expect(messages.where((m) => m.isUser).length, 1);
    expect(answers.length, 1);
    expect(answers.single.isError, isFalse);
  });

  test('setelah selesai, pengiriman berikutnya tetap dilayani', () async {
    final ai = _FakeAi();
    final container = _container(ai);

    final notifier = container.read(chatProvider.notifier);
    await notifier.send('Pertanyaan satu');
    await notifier.send('Pertanyaan dua');

    final messages = container.read(chatProvider).value!;
    expect(ai.callCount, 2, reason: 'penjaga tidak boleh mengunci selamanya');
    expect(messages.length, 4);
  });

  test('percakapan bisa dikosongkan', () async {
    final ai = _FakeAi();
    final container = _container(ai);

    final notifier = container.read(chatProvider.notifier);
    await notifier.send('Halo');
    notifier.clear();

    expect(container.read(chatProvider).value, isEmpty);
  });

  test('kegagalan tetap tercatat sebagai bubble error', () async {
    final ai = _FakeAi(failure: const AiFailure('Kuota habis.'));
    final container = _container(ai);

    final failure = await container.read(chatProvider.notifier).send('Halo');

    expect(failure, isA<AiFailure>());
    final messages = container.read(chatProvider).value!;
    expect(messages.last.isError, isTrue);
    expect(messages.last.text, 'Kuota habis.');
  });
}
