import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/failures.dart';
import '../../domain/entities/chat_message.dart';
import '../providers/assistant_providers.dart';
import '../widgets/message_bubble.dart';

/// Halaman chat "Asisten Catatan".
///
/// Hanya membaca state dan memanggil notifier — tanpa HTTP, tanpa API key,
/// tanpa penyusunan prompt. Semua itu ada di layer data/domain.
class AssistantPage extends ConsumerStatefulWidget {
  const AssistantPage({super.key});

  @override
  ConsumerState<AssistantPage> createState() => _AssistantPageState();
}

class _AssistantPageState extends ConsumerState<AssistantPage> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  bool _isSending = false;
  String? _lastQuestion;
  bool _canRetry = false;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send(String question, {bool isRetry = false}) async {
    if (_isSending) return;
    final trimmed = question.trim();
    if (trimmed.isEmpty) return;

    setState(() {
      _isSending = true;
      _lastQuestion = trimmed;
      _canRetry = false;
    });
    _controller.clear();

    final failure = await ref
        .read(chatProvider.notifier)
        .send(trimmed, isRetry: isRetry);

    if (!mounted) return;
    setState(() {
      _isSending = false;
      _canRetry = failure != null && failure is AiFailure && failure.retryable;
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final keyConfigured = ref.watch(apiKeyConfiguredProvider);
    final messages = ref.watch(chatProvider).value ?? const [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Asisten Catatan'),
        actions: [
          IconButton(
            tooltip: 'Hapus percakapan',
            icon: const Icon(Icons.delete_sweep_outlined),
            onPressed: messages.isEmpty
                ? null
                : () => ref.read(chatProvider.notifier).clear(),
          ),
          IconButton(
            tooltip: 'Pengaturan',
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: keyConfigured.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _MessageState(
          icon: Icons.error_outline,
          title: 'Gagal membaca pengaturan',
          subtitle: '$error',
        ),
        data: (configured) =>
            configured ? _buildChat(messages) : _buildNoKeyState(context),
      ),
    );
  }

  /// Fallback utama: tanpa API key, jangan panggil API yang pasti gagal.
  Widget _buildNoKeyState(BuildContext context) {
    return _MessageState(
      icon: Icons.key_off_outlined,
      title: 'API key belum diatur',
      subtitle:
          'Asisten ini memakai Gemini API. Tambahkan API key di Pengaturan — '
          'key disimpan di secure storage perangkat, tidak di dalam aplikasi.',
      action: FilledButton.icon(
        onPressed: () => context.push('/settings'),
        icon: const Icon(Icons.settings),
        label: const Text('Buka Pengaturan'),
      ),
    );
  }

  Widget _buildChat(List<ChatMessage> messages) {
    return Column(
      children: [
        Expanded(
          child: messages.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(12),
                  itemCount: messages.length + (_isSending ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == messages.length) {
                      return const _TypingIndicator();
                    }
                    return MessageBubble(message: messages[index]);
                  },
                ),
        ),
        if (_canRetry && _lastQuestion != null)
          Material(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                children: [
                  const Icon(Icons.wifi_off, size: 18),
                  const SizedBox(width: 8),
                  const Expanded(child: Text('Gagal menghubungi AI.')),
                  TextButton(
                    onPressed: _isSending
                        ? null
                        : () => _send(_lastQuestion!, isRetry: true),
                    child: const Text('Coba lagi'),
                  ),
                ],
              ),
            ),
          ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    enabled: !_isSending,
                    textInputAction: TextInputAction.send,
                    onSubmitted: _send,
                    decoration: const InputDecoration(
                      hintText: 'Tanya tentang catatanmu…',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  tooltip: 'Kirim',
                  onPressed: _isSending ? null : () => _send(_controller.text),
                  icon: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    const examples = [
      'Ringkas semua catatanku',
      'Catatan mana yang perlu disinkronkan?',
      'Apa isi catatan tentang belanja?',
    ];

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 24),
        Icon(
          Icons.auto_awesome,
          size: 48,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 12),
        Text(
          'Tanya apa saja tentang catatanmu',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'Asisten membaca judul dan isi catatan yang tersimpan di perangkat, '
          'lalu menjawab berdasarkan catatan itu saja.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 20),
        for (final example in examples)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: ActionChip(
              label: Text(example),
              onPressed: _isSending ? null : () => _send(example),
            ),
          ),
      ],
    );
  }
}

/// Indikator "AI sedang menulis…".
class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 10),
            Text(
              'AI sedang menulis…',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

/// Tampilan status penuh layar (empty/error/no-key).
class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.action,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(subtitle, textAlign: TextAlign.center),
            if (action != null) ...[const SizedBox(height: 16), action!],
          ],
        ),
      ),
    );
  }
}
