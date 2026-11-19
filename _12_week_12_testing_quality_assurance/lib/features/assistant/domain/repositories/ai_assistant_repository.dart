import '../../../../core/failures.dart';

/// Kontrak yang dibutuhkan domain untuk bertanya ke penyedia AI.
///
/// Sama seperti `NoteRepository`: interface tinggal di domain, implementasi
/// (Gemini HTTP) di layer data. Return memakai record `(value, failure)`
/// sehingga presentation tidak perlu menangkap exception.
abstract class AiAssistantRepository {
  Future<({String? answer, Failure? failure})> ask({
    required String systemPrompt,
    required String userPrompt,
  });

  /// True bila API key sudah tersimpan. Dipakai UI untuk memutuskan
  /// menampilkan ajakan mengatur key, bukan memanggil API yang pasti gagal.
  Future<bool> hasApiKey();
}

/// Kontrak penyimpanan API key (implementasi: secure storage).
abstract class ApiKeyRepository {
  Future<String?> read();

  Future<void> save(String key);

  Future<void> delete();
}
