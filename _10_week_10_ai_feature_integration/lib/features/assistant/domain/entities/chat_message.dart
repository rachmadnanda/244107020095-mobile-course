/// Entity pesan chat. Murni Dart — tanpa Flutter, JSON, atau HTTP.
///
/// Mapping ke format API (JSON) hanya dilakukan di layer data, sehingga entity
/// tetap bebas dari detail transport.
enum ChatRole { user, assistant }

class ChatMessage {
  const ChatMessage({
    required this.role,
    required this.text,
    required this.createdAt,
    this.isError = false,
  });

  final ChatRole role;
  final String text;
  final DateTime createdAt;

  /// True bila pesan ini menampilkan kegagalan (bukan jawaban model).
  final bool isError;

  bool get isUser => role == ChatRole.user;
}
