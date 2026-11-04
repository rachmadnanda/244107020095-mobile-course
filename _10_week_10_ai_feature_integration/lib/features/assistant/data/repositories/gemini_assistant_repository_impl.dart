import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/failures.dart';
import '../../domain/repositories/ai_assistant_repository.dart';

/// Implementasi `AiAssistantRepository` memakai Gemini API (REST).
///
/// Keputusan penting (lihat `docs/ai-log.md`):
/// - API key dikirim lewat header `x-goog-api-key`, **bukan** `?key=` di URL
///   agar tidak tercatat di access log/proxy.
/// - Model memakai `gemini-3.5-flash-lite` (stabil). `gemini-pro` sudah
///   dipensiunkan sehingga selalu gagal.
/// - `candidates` bisa kosong (prompt diblokir safety). Parsing dibuat defensif
///   supaya tidak melempar `RangeError` ke presentation.
/// - Semua kegagalan dipetakan ke `AiFailure`, tidak pernah `throw` ke atas.
class GeminiAssistantRepository implements AiAssistantRepository {
  GeminiAssistantRepository({
    required this.keyRepository,
    http.Client? client,
    this.model = 'gemini-3.5-flash-lite',
    this.timeout = const Duration(seconds: 20),
  }) : _client = client ?? http.Client();

  static const _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';

  final ApiKeyRepository keyRepository;
  final http.Client _client;
  final String model;
  final Duration timeout;

  @override
  Future<bool> hasApiKey() async {
    final key = await keyRepository.read();
    return key != null && key.trim().isNotEmpty;
  }

  @override
  Future<({String? answer, Failure? failure})> ask({
    required String systemPrompt,
    required String userPrompt,
  }) async {
    final apiKey = await keyRepository.read();
    if (apiKey == null || apiKey.trim().isEmpty) {
      return (
        answer: null,
        failure: const AiFailure(
          'API key belum diatur. Buka Pengaturan untuk menambahkannya.',
        ),
      );
    }

    final uri = Uri.parse('$_baseUrl/$model:generateContent');

    try {
      final response = await _client
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'x-goog-api-key': apiKey.trim(),
            },
            body: jsonEncode({
              'system_instruction': {
                'parts': [
                  {'text': systemPrompt},
                ],
              },
              'contents': [
                {
                  'role': 'user',
                  'parts': [
                    {'text': userPrompt},
                  ],
                },
              ],
            }),
          )
          .timeout(timeout);

      return _handleResponse(response);
    } on TimeoutException {
      return (
        answer: null,
        failure: AiFailure(
          'Layanan AI tidak merespons dalam ${timeout.inSeconds} detik. '
          'Coba lagi.',
          retryable: true,
        ),
      );
    } on http.ClientException {
      return (
        answer: null,
        failure: const AiFailure(
          'Tidak dapat terhubung ke layanan AI. Periksa koneksi internet.',
          retryable: true,
        ),
      );
    } catch (_) {
      return (
        answer: null,
        failure: const AiFailure(
          'Terjadi kesalahan saat menghubungi layanan AI.',
          retryable: true,
        ),
      );
    }
  }

  /// Memetakan status HTTP dan isi body menjadi jawaban atau `AiFailure`.
  ({String? answer, Failure? failure}) _handleResponse(http.Response response) {
    switch (response.statusCode) {
      case 200:
        return _parseBody(response.body);
      case 400:
        return (
          answer: null,
          failure: const AiFailure(
            'Permintaan ditolak layanan AI. Coba ubah pertanyaan.',
          ),
        );
      case 401:
      case 403:
        return (
          answer: null,
          failure: const AiFailure(
            'API key tidak valid atau tidak punya akses. Periksa di Pengaturan.',
          ),
        );
      case 429:
        return (
          answer: null,
          failure: const AiFailure(
            'Kuota AI habis atau terlalu banyak permintaan. Coba lagi nanti.',
          ),
        );
      default:
        if (response.statusCode >= 500) {
          return (
            answer: null,
            failure: const AiFailure(
              'Layanan AI sedang bermasalah. Coba lagi beberapa saat.',
              retryable: true,
            ),
          );
        }
        return (
          answer: null,
          failure: AiFailure(
            'Gagal memanggil layanan AI (kode ${response.statusCode}).',
          ),
        );
    }
  }

  /// Parsing defensif: tidak mengasumsikan `candidates[0]` selalu ada.
  ({String? answer, Failure? failure}) _parseBody(String body) {
    Object? decoded;
    try {
      decoded = jsonDecode(body);
    } on FormatException {
      return (
        answer: null,
        failure: const AiFailure('Respons AI tidak dapat dibaca.'),
      );
    }

    if (decoded is! Map<String, dynamic>) {
      return (
        answer: null,
        failure: const AiFailure('Respons AI tidak dapat dibaca.'),
      );
    }

    // Prompt diblokir filter keamanan: candidates tidak ada sama sekali.
    final blockReason =
        (decoded['promptFeedback'] as Map<String, dynamic>?)?['blockReason'];
    if (blockReason != null) {
      return (
        answer: null,
        failure: const AiFailure(
          'Pertanyaan diblokir filter keamanan layanan AI. Ubah pertanyaan.',
        ),
      );
    }

    final candidates = decoded['candidates'];
    if (candidates is! List || candidates.isEmpty) {
      return (
        answer: null,
        failure: const AiFailure('AI tidak memberikan jawaban. Coba lagi.'),
      );
    }

    final parts =
        ((candidates.first as Map<String, dynamic>)['content']
            as Map<String, dynamic>?)?['parts'];
    if (parts is! List || parts.isEmpty) {
      return (
        answer: null,
        failure: const AiFailure('Jawaban AI kosong. Coba lagi.'),
      );
    }

    final text = (parts.first as Map<String, dynamic>)['text'];
    if (text is! String || text.trim().isEmpty) {
      return (
        answer: null,
        failure: const AiFailure('Jawaban AI kosong. Coba lagi.'),
      );
    }

    return (answer: text.trim(), failure: null);
  }
}
