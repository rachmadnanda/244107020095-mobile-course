import 'package:dio/dio.dart';

/// Mendaftarkan FCM registration token ke backend (`POST /devices`).
///
/// Ganti base URL pada `buildApiClient` dengan API kampus. Endpoint ini
/// dipanggil setiap kali token tersedia atau berubah (`onTokenRefresh`),
/// sehingga backend tidak menyimpan token basi.
class DeviceRepository {
  DeviceRepository(this._dio);

  final Dio _dio;

  Future<void> registerToken({
    required String token,
    required String platform,
  }) async {
    await _dio.post(
      '/devices',
      data: {'fcm_token': token, 'platform': platform},
    );
  }
}
