/// Kumpulan kegagalan domain. Murni Dart — tanpa Flutter, Dio, SQLite, atau
/// Firebase — sehingga bisa dipakai oleh domain dan diuji tanpa framework.
///
/// Presentation hanya menerima `message` yang ramah pengguna, bukan exception
/// mentah dari sumber data.
sealed class Failure {
  const Failure(this.message);

  final String message;
}

/// Kegagalan sumber data lokal (SQLite, SharedPreferences, dsb).
class LocalFailure extends Failure {
  const LocalFailure(super.message);
}

/// Kegagalan jaringan / backend.
class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}
