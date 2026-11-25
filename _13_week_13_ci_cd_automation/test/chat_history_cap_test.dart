import 'package:flutter_test/flutter_test.dart';

import 'package:week_13_ci_cd_automation/features/assistant/domain/entities/chat_message.dart';
import 'package:week_13_ci_cd_automation/features/assistant/presentation/providers/assistant_providers.dart';

List<ChatMessage> _messages(int count) {
  final start = DateTime(2026, 1, 1);
  return List.generate(
    count,
    (index) => ChatMessage(
      role: ChatRole.user,
      text: '$index',
      createdAt: start.add(Duration(seconds: index)),
    ),
  );
}

void main() {
  test('riwayat chat dibatasi ke pesan terbaru', () {
    final capped = ChatNotifier.capHistory(_messages(205));

    expect(capped, hasLength(ChatNotifier.maxMessages));
    expect(capped.first.text, '5');
    expect(capped.last.text, '204');
  });

  test('riwayat pendek tidak diubah', () {
    final messages = _messages(10);

    expect(ChatNotifier.capHistory(messages), same(messages));
  });
}
