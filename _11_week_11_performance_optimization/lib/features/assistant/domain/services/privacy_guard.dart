/// Penjaga privasi: meredaksi data pribadi sebelum teks dikirim ke AI API.
///
/// Murni Dart dan deterministik supaya bisa diuji tanpa jaringan. Dipakai
/// use case `AskAssistant` — bukan widget — sehingga aturan privasi tidak bisa
/// dilewati oleh pemanggil baru.
class PrivacyGuard {
  const PrivacyGuard();

  /// Batas panjang konteks catatan yang dikirim (kendali biaya token).
  static const maxContextChars = 1500;

  static final _email = RegExp(r'[\w.+-]+@[\w-]+\.[\w.]+');

  /// NIK Indonesia: 16 digit, boleh dipisah spasi/titik/strip
  /// (format lazim 4-4-4-4 atau tanpa pemisah sama sekali).
  ///
  /// Sengaja dibuat longgar: salah meredaksi angka biasa jauh lebih aman
  /// daripada meloloskan NIK ke layanan AI.
  static final _nik = RegExp(r'\b\d{4}[\s.-]?\d{4}[\s.-]?\d{4}[\s.-]?\d{4}\b');

  /// Nomor telepon Indonesia: 08xx / +628xx, 9-13 digit.
  static final _phone = RegExp(r'(\+62|62|0)8\d{7,11}');

  /// Mengganti email, NIK, dan nomor telepon dengan penanda.
  String redact(String input) {
    var result = input
        .replaceAll(_email, '[email]')
        .replaceAll(_nik, '[nik]')
        .replaceAll(_phone, '[telepon]');
    return result;
  }

  /// Merapikan dan memotong konteks agar biaya per request terkendali.
  ///
  /// Dipotong pada batas kata agar model tidak menerima kalimat terputus.
  String trimContext(String input) {
    final normalized = input.trim();
    if (normalized.length <= maxContextChars) return normalized;
    final cut = normalized.substring(0, maxContextChars);
    final lastSpace = cut.lastIndexOf(' ');
    final safeCut = lastSpace > 0 ? cut.substring(0, lastSpace) : cut;
    return '$safeCut… (dipotong)';
  }

  /// Membersihkan pertanyaan pengguna: redaksi + rapikan spasi.
  String sanitize(String input) => redact(input).trim();
}
