import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/failures.dart';
import '../../../notes/domain/entities/note.dart';
import '../../../notes/presentation/providers/notes_providers.dart';
import '../../data/ai/api_key_store.dart';
import '../../data/repositories/gemini_assistant_repository_impl.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/ai_assistant_repository.dart';
import '../../domain/usecases/ask_assistant.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SATU-SATUNYA tempat wiring DI untuk fitur assistant.
// ─────────────────────────────────────────────────────────────────────────────

/// Penyimpanan API key (secure storage).
final apiKeyRepositoryProvider = Provider<ApiKeyRepository>(
  (ref) => const SecureApiKeyStore(),
);

/// Repository AI. Client HTTP dibuat sekali dan dipakai ulang.
final aiAssistantRepositoryProvider = Provider<AiAssistantRepository>(
  (ref) => GeminiAssistantRepository(
    keyRepository: ref.watch(apiKeyRepositoryProvider),
  ),
);

/// Use case: menyusun prompt + memanggil AI.
final askAssistantProvider = Provider<AskAssistant>(
  (ref) => AskAssistant(ref.watch(aiAssistantRepositoryProvider)),
);

/// Status "apakah API key sudah diatur" untuk UI.
final apiKeyConfiguredProvider = FutureProvider<bool>(
  (ref) => ref.watch(aiAssistantRepositoryProvider).hasApiKey(),
);

/// State percakapan.
final chatProvider = AsyncNotifierProvider<ChatNotifier, List<ChatMessage>>(
  ChatNotifier.new,
);

class ChatNotifier extends AsyncNotifier<List<ChatMessage>> {
  /// Penjaga di level state, bukan hanya di widget.
  ///
  /// Bila dua `send()` tumpang tindih, masing-masing memegang snapshot state
  /// sendiri; yang selesai terakhir menimpa yang lebih dulu sehingga jawaban
  /// pertama **hilang diam-diam** padahal requestnya sudah dibayar.
  bool _inFlight = false;

  @override
  Future<List<ChatMessage>> build() async => const <ChatMessage>[];

  /// Menambahkan pesan pengguna lalu meminta jawaban AI.
  ///
  /// Mengembalikan `Failure` (bukan melempar) agar UI bisa menampilkan pesan
  /// ramah dan tombol "Coba lagi".
  ///
  /// [isRetry] dipakai tombol "Coba lagi": pesan pengguna **tidak** ditambahkan
  /// lagi (tidak menggandakan bubble) dan bubble error terakhir dibuang sebelum
  /// jawaban baru ditampilkan.
  Future<Failure?> send(String question, {bool isRetry = false}) async {
    // Request sebelumnya belum selesai: tolak yang baru agar tidak ada
    // pembayaran ganda dan jawaban yang tertimpa.
    if (_inFlight) return null;

    final current = state.value ?? const <ChatMessage>[];
    final trimmed = question.trim();
    if (trimmed.isEmpty) return null;

    _inFlight = true;
    try {
      final base = isRetry
          ? current.where((message) => !message.isError).toList()
          : current;
      final withUser = isRetry
          ? base
          : [
              ...base,
              ChatMessage(
                role: ChatRole.user,
                text: trimmed,
                createdAt: DateTime.now(),
              ),
            ];
      state = AsyncData(withUser);

      final notes = ref.read(notesProvider).value ?? const <Note>[];
      final result = await ref
          .read(askAssistantProvider)
          .call(question: trimmed, notes: notes);

      // Bila percakapan dibersihkan saat menunggu, jangan hidupkan lagi
      // jawaban untuk pertanyaan yang sudah tidak ada di layar.
      if (!ref.mounted) return null;

      if (result.failure != null) {
        final failure = result.failure!;
        state = AsyncData([
          ...withUser,
          ChatMessage(
            role: ChatRole.assistant,
            text: failure.message,
            createdAt: DateTime.now(),
            isError: true,
          ),
        ]);
        return failure;
      }

      state = AsyncData([
        ...withUser,
        ChatMessage(
          role: ChatRole.assistant,
          text: result.answer!,
          createdAt: DateTime.now(),
        ),
      ]);
      return null;
    } finally {
      _inFlight = false;
    }
  }

  void clear() {
    state = const AsyncData(<ChatMessage>[]);
  }
}
