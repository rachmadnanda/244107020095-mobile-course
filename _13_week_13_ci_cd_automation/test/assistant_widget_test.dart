import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:week_13_ci_cd_automation/core/failures.dart';
import 'package:week_13_ci_cd_automation/features/assistant/domain/repositories/ai_assistant_repository.dart';
import 'package:week_13_ci_cd_automation/features/assistant/presentation/pages/assistant_page.dart';
import 'package:week_13_ci_cd_automation/features/assistant/presentation/providers/assistant_providers.dart';
import 'package:week_13_ci_cd_automation/features/notes/domain/entities/note.dart';
import 'package:week_13_ci_cd_automation/features/notes/domain/repositories/note_repository.dart';
import 'package:week_13_ci_cd_automation/features/notes/presentation/providers/notes_providers.dart';

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

class _FakeAi implements AiAssistantRepository {
  _FakeAi({this.answer = 'Ini jawaban AI', this.failure, this.delay});

  final String answer;
  final Failure? failure;
  final Duration? delay;
  int callCount = 0;

  @override
  Future<({String? answer, Failure? failure})> ask({
    required String systemPrompt,
    required String userPrompt,
  }) async {
    callCount++;
    if (delay != null) await Future<void>.delayed(delay!);
    if (failure != null) return (answer: null, failure: failure);
    return (answer: answer, failure: null);
  }

  @override
  Future<bool> hasApiKey() async => true;
}

/// Gagal pada panggilan pertama, sukses pada panggilan berikutnya —
/// dipakai untuk menguji tombol "Coba lagi".
class _FlakyAi implements AiAssistantRepository {
  int callCount = 0;

  @override
  Future<({String? answer, Failure? failure})> ask({
    required String systemPrompt,
    required String userPrompt,
  }) async {
    callCount++;
    if (callCount == 1) {
      return (
        answer: null,
        failure: const AiFailure(
          'Layanan AI sedang bermasalah.',
          retryable: true,
        ),
      );
    }
    return (answer: 'Jawaban setelah retry', failure: null);
  }

  @override
  Future<bool> hasApiKey() async => true;
}

Widget _app({required bool keyConfigured, AiAssistantRepository? ai}) =>
    ProviderScope(
      overrides: [
        noteRepositoryProvider.overrideWithValue(_FakeNotes()),
        apiKeyConfiguredProvider.overrideWith((ref) async => keyConfigured),
        if (ai != null) aiAssistantRepositoryProvider.overrideWithValue(ai),
      ],
      child: const MaterialApp(home: AssistantPage()),
    );

void main() {
  testWidgets('tanpa API key menampilkan ajakan ke Pengaturan', (tester) async {
    await tester.pumpWidget(_app(keyConfigured: false));
    await tester.pumpAndSettle();

    expect(find.text('API key belum diatur'), findsOneWidget);
    expect(find.text('Buka Pengaturan'), findsOneWidget);
  });

  testWidgets('empty state menampilkan contoh pertanyaan', (tester) async {
    await tester.pumpWidget(_app(keyConfigured: true, ai: _FakeAi()));
    await tester.pumpAndSettle();

    expect(find.text('Tanya apa saja tentang catatanmu'), findsOneWidget);
    expect(find.text('Ringkas semua catatanku'), findsOneWidget);
  });

  testWidgets('mengirim pertanyaan menampilkan bubble user dan jawaban AI', (
    tester,
  ) async {
    await tester.pumpWidget(_app(keyConfigured: true, ai: _FakeAi()));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Apa catatanku?');
    await tester.tap(find.byTooltip('Kirim'));
    await tester.pumpAndSettle();

    expect(find.text('Apa catatanku?'), findsOneWidget);
    expect(find.text('Ini jawaban AI'), findsOneWidget);
  });

  testWidgets('menampilkan indikator "AI sedang menulis…" saat menunggu', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        keyConfigured: true,
        ai: _FakeAi(delay: const Duration(milliseconds: 300)),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Halo');
    await tester.tap(find.byTooltip('Kirim'));
    await tester.pump(); // mulai request, belum selesai

    expect(find.text('AI sedang menulis…'), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.text('AI sedang menulis…'), findsNothing);
  });

  testWidgets('kegagalan retryable menampilkan tombol Coba lagi', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        keyConfigured: true,
        ai: _FakeAi(
          failure: const AiFailure(
            'Layanan AI sedang bermasalah.',
            retryable: true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Halo');
    await tester.tap(find.byTooltip('Kirim'));
    await tester.pumpAndSettle();

    expect(find.text('Layanan AI sedang bermasalah.'), findsOneWidget);
    expect(find.text('Coba lagi'), findsOneWidget);
  });

  testWidgets('kegagalan tidak retryable tidak menampilkan Coba lagi', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        keyConfigured: true,
        ai: _FakeAi(failure: const AiFailure('API key tidak valid.')),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Halo');
    await tester.tap(find.byTooltip('Kirim'));
    await tester.pumpAndSettle();

    expect(find.text('API key tidak valid.'), findsOneWidget);
    expect(find.text('Coba lagi'), findsNothing);
  });

  testWidgets('chip contoh pertanyaan langsung mengirim', (tester) async {
    final ai = _FakeAi(answer: 'Ringkasan catatan');
    await tester.pumpWidget(_app(keyConfigured: true, ai: ai));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ringkas semua catatanku'));
    await tester.pumpAndSettle();

    expect(ai.callCount, 1);
    expect(find.text('Ringkasan catatan'), findsOneWidget);
  });

  testWidgets('ketuk ganda cepat hanya mengirim satu request', (tester) async {
    // Menjaga agar ketukan tidak sengaja (atau pengguna yang mengira aplikasi
    // macet) tidak menggandakan request — dan menggandakan biaya token.
    final ai = _FakeAi(delay: const Duration(milliseconds: 200));
    await tester.pumpWidget(_app(keyConfigured: true, ai: ai));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ringkas semua catatanku'));
    await tester.tap(find.text('Ringkas semua catatanku'));
    await tester.pumpAndSettle();

    expect(ai.callCount, 1, reason: 'satu pertanyaan = satu request');
    expect(find.text('Ringkas semua catatanku'), findsOneWidget);
  });

  testWidgets('tombol Coba lagi tidak menggandakan pesan pengguna', (
    tester,
  ) async {
    final ai = _FlakyAi();
    await tester.pumpWidget(_app(keyConfigured: true, ai: ai));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Halo');
    await tester.tap(find.byTooltip('Kirim'));
    await tester.pumpAndSettle();

    expect(find.text('Halo'), findsOneWidget);
    expect(find.text('Coba lagi'), findsOneWidget);

    await tester.tap(find.text('Coba lagi'));
    await tester.pumpAndSettle();

    expect(
      find.text('Halo'),
      findsOneWidget,
      reason: 'pesan pengguna tidak boleh diduplikasi saat retry',
    );
    expect(find.text('Jawaban setelah retry'), findsOneWidget);
    expect(find.text('Coba lagi'), findsNothing);
    expect(ai.callCount, 2);
  });
}
