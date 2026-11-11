import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:week_11_performance_optimization/core/failures.dart';
import 'package:week_11_performance_optimization/features/assistant/data/repositories/gemini_assistant_repository_impl.dart';
import 'package:week_11_performance_optimization/features/assistant/domain/repositories/ai_assistant_repository.dart';

class _FakeKeyRepository implements ApiKeyRepository {
  _FakeKeyRepository(this.key);

  String? key;

  @override
  Future<String?> read() async => key;

  @override
  Future<void> save(String value) async => key = value;

  @override
  Future<void> delete() async => key = null;
}

/// JSON respons sukses minimal.
String _successBody(String text) => jsonEncode({
  'candidates': [
    {
      'content': {
        'parts': [
          {'text': text},
        ],
      },
      'finishReason': 'STOP',
    },
  ],
});

GeminiAssistantRepository _repo(
  MockClient client, {
  String? key = 'AIza-test-key',
  Duration timeout = const Duration(seconds: 20),
}) => GeminiAssistantRepository(
  keyRepository: _FakeKeyRepository(key),
  client: client,
  timeout: timeout,
);

void main() {
  group('GeminiAssistantRepository — tanpa API key', () {
    test('mengembalikan AiFailure tanpa memanggil HTTP', () async {
      var called = false;
      final repo = _repo(
        MockClient((request) async {
          called = true;
          return http.Response(_successBody('tidak terpakai'), 200);
        }),
        key: null,
      );

      final result = await repo.ask(systemPrompt: 's', userPrompt: 'u');

      expect(result.failure, isA<AiFailure>());
      expect(result.failure!.message, contains('API key belum diatur'));
      expect(called, isFalse);
    });

    test('hasApiKey false bila key kosong', () async {
      final repo = _repo(
        MockClient((_) async => http.Response('', 200)),
        key: '   ',
      );
      expect(await repo.hasApiKey(), isFalse);
    });
  });

  group('GeminiAssistantRepository — keamanan request', () {
    test('API key dikirim lewat header, bukan query string', () async {
      late http.Request captured;
      final repo = _repo(
        MockClient((request) async {
          captured = request;
          return http.Response(_successBody('ok'), 200);
        }),
      );

      await repo.ask(systemPrompt: 's', userPrompt: 'u');

      expect(captured.headers['x-goog-api-key'], 'AIza-test-key');
      expect(captured.url.queryParameters.containsKey('key'), isFalse);
      expect(captured.url.toString(), isNot(contains('AIza-test-key')));
    });

    test('model yang dipakai bukan gemini-pro (sudah pensiun)', () async {
      late http.Request captured;
      final repo = _repo(
        MockClient((request) async {
          captured = request;
          return http.Response(_successBody('ok'), 200);
        }),
      );

      await repo.ask(systemPrompt: 's', userPrompt: 'u');

      expect(captured.url.path, contains('gemini-3.5-flash-lite'));
      expect(captured.url.path, isNot(contains('gemini-pro')));
      expect(captured.url.path, endsWith(':generateContent'));
    });

    test('system_instruction dan contents dikirim sesuai skema', () async {
      late http.Request captured;
      final repo = _repo(
        MockClient((request) async {
          captured = request;
          return http.Response(_successBody('ok'), 200);
        }),
      );

      await repo.ask(systemPrompt: 'SYSTEM', userPrompt: 'USER');

      final body = jsonDecode(captured.body) as Map<String, dynamic>;
      expect(
        ((body['system_instruction'] as Map)['parts'] as List).first['text'],
        'SYSTEM',
      );
      expect(
        ((body['contents'] as List).first['parts'] as List).first['text'],
        'USER',
      );
    });
  });

  group('GeminiAssistantRepository — parsing respons', () {
    test('respons 200 normal mengembalikan teks', () async {
      final repo = _repo(
        MockClient((_) async => http.Response(_successBody('Halo!'), 200)),
      );

      final result = await repo.ask(systemPrompt: 's', userPrompt: 'u');

      expect(result.failure, isNull);
      expect(result.answer, 'Halo!');
    });

    test('teks di-trim', () async {
      final repo = _repo(
        MockClient((_) async => http.Response(_successBody('  Halo  '), 200)),
      );

      final result = await repo.ask(systemPrompt: 's', userPrompt: 'u');

      expect(result.answer, 'Halo');
    });

    // Temuan AI #4: kode contoh codelab melakukan `candidates[0]` sehingga
    // crash (RangeError) ketika prompt diblokir filter keamanan.
    test('prompt diblokir safety → AiFailure, bukan crash', () async {
      final blocked = jsonEncode({
        'promptFeedback': {'blockReason': 'SAFETY'},
      });
      final repo = _repo(MockClient((_) async => http.Response(blocked, 200)));

      final result = await repo.ask(systemPrompt: 's', userPrompt: 'u');

      expect(result.failure, isA<AiFailure>());
      expect(result.failure!.message, contains('diblokir'));
      expect(result.answer, isNull);
    });

    test('candidates kosong tanpa blockReason → AiFailure', () async {
      final repo = _repo(
        MockClient(
          (_) async => http.Response(jsonEncode({'candidates': []}), 200),
        ),
      );

      final result = await repo.ask(systemPrompt: 's', userPrompt: 'u');

      expect(result.failure, isA<AiFailure>());
    });

    test('parts kosong → AiFailure', () async {
      final empty = jsonEncode({
        'candidates': [
          {
            'content': {'parts': []},
          },
        ],
      });
      final repo = _repo(MockClient((_) async => http.Response(empty, 200)));

      final result = await repo.ask(systemPrompt: 's', userPrompt: 'u');

      expect(result.failure, isA<AiFailure>());
      expect(result.failure!.message, contains('kosong'));
    });

    test('body bukan JSON → AiFailure', () async {
      final repo = _repo(
        MockClient((_) async => http.Response('<html>error</html>', 200)),
      );

      final result = await repo.ask(systemPrompt: 's', userPrompt: 'u');

      expect(result.failure, isA<AiFailure>());
      expect(result.failure!.message, contains('tidak dapat dibaca'));
    });
  });

  group('GeminiAssistantRepository — status HTTP', () {
    test('401 → pesan API key tidak valid', () async {
      final repo = _repo(MockClient((_) async => http.Response('{}', 401)));
      final result = await repo.ask(systemPrompt: 's', userPrompt: 'u');

      expect(result.failure, isA<AiFailure>());
      expect(result.failure!.message, contains('API key tidak valid'));
    });

    test('429 → pesan kuota habis', () async {
      final repo = _repo(MockClient((_) async => http.Response('{}', 429)));
      final result = await repo.ask(systemPrompt: 's', userPrompt: 'u');

      expect(result.failure, isA<AiFailure>());
      expect(result.failure!.message, contains('Kuota'));
    });

    test('500 → failure yang bisa di-retry', () async {
      final repo = _repo(MockClient((_) async => http.Response('{}', 500)));
      final result = await repo.ask(systemPrompt: 's', userPrompt: 'u');

      expect(result.failure, isA<AiFailure>());
      expect((result.failure! as AiFailure).retryable, isTrue);
    });

    test('400 → failure tanpa retry', () async {
      final repo = _repo(MockClient((_) async => http.Response('{}', 400)));
      final result = await repo.ask(systemPrompt: 's', userPrompt: 'u');

      expect(result.failure, isA<AiFailure>());
      expect((result.failure! as AiFailure).retryable, isFalse);
    });
  });

  group('GeminiAssistantRepository — kegagalan jaringan', () {
    test('timeout → AiFailure yang bisa di-retry', () async {
      final repo = _repo(
        MockClient((_) async {
          await Future<void>.delayed(const Duration(milliseconds: 200));
          return http.Response(_successBody('terlambat'), 200);
        }),
        timeout: const Duration(milliseconds: 50),
      );

      final result = await repo.ask(systemPrompt: 's', userPrompt: 'u');

      expect(result.failure, isA<AiFailure>());
      expect(result.failure!.message, contains('tidak merespons'));
      expect((result.failure! as AiFailure).retryable, isTrue);
    });

    test('ClientException → pesan koneksi', () async {
      final repo = _repo(
        MockClient((_) async => throw http.ClientException('gagal konek')),
      );

      final result = await repo.ask(systemPrompt: 's', userPrompt: 'u');

      expect(result.failure, isA<AiFailure>());
      expect(result.failure!.message, contains('koneksi'));
    });
  });
}
