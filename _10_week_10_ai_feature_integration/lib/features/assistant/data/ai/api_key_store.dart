import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../domain/repositories/ai_assistant_repository.dart';

/// Implementasi penyimpanan API key di secure storage (Keychain/Keystore).
///
/// Key tidak pernah ditulis ke kode sumber, `shared_preferences`, atau log.
class SecureApiKeyStore implements ApiKeyRepository {
  const SecureApiKeyStore([this._storage = const FlutterSecureStorage()]);

  static const _key = 'gemini_api_key';

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read() => _storage.read(key: _key);

  @override
  Future<void> save(String key) => _storage.write(key: _key, value: key.trim());

  @override
  Future<void> delete() => _storage.delete(key: _key);
}
