import 'package:material_ui/material_ui.dart';

import '../../domain/entities/chat_message.dart';

/// Balon pesan chat. Murni presentasi: menerima entity, tanpa logika AI.
class MessageBubble extends StatelessWidget {
  const MessageBubble({required this.message, super.key});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isUser = message.isUser;

    final Color background;
    if (message.isError) {
      background = scheme.errorContainer;
    } else if (isUser) {
      background = scheme.primaryContainer;
    } else {
      background = scheme.surfaceContainerHighest;
    }

    final textColor = message.isError
        ? scheme.onErrorContainer
        : (isUser ? scheme.onPrimaryContainer : scheme.onSurface);

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: const BoxConstraints(maxWidth: 320),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.isError) ...[
              Icon(Icons.error_outline, size: 18, color: textColor),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text(message.text, style: TextStyle(color: textColor)),
            ),
          ],
        ),
      ),
    );
  }
}
