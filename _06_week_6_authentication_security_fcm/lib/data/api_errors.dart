import 'package:dio/dio.dart';

String friendlyError(Object error) {
  if (error is DioException) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Koneksi timeout. Coba lagi.';
      case DioExceptionType.connectionError:
        return 'Tidak ada koneksi internet.';
      case DioExceptionType.badResponse:
        final code = error.response?.statusCode;
        if (code == 401) return 'Sesi berakhir. Silakan login ulang.';
        if (code == 403) return 'Akses ditolak.';
        if (code == 404) return 'Data tidak ditemukan.';
        if (code != null && code >= 500) return 'Server sedang bermasalah.';
        return 'Terjadi kesalahan (${code ?? '?'}).';
      default:
        return 'Terjadi kesalahan. Coba lagi.';
    }
  }
  return error.toString();
}
