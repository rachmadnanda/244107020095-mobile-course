import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Penjaga: **tidak boleh ada API key tertulis di kode sumber**.
///
/// Dua format key Gemini yang dikenal:
/// - lama : `AIza…`
/// - baru : `AQ.<base64url>`
///
/// Test ini menangkap kesalahan yang mudah terjadi dan sulit terlihat:
/// menempelkan key ke konstanta nama slot secure storage, alih-alih
/// mengisinya lewat halaman Pengaturan.
void main() {
  final keyPatterns = [
    RegExp(r'AIza[0-9A-Za-z_-]{20,}'),
    RegExp(r'AQ\.[A-Za-z0-9_-]{20,}'),
  ];

  test('tidak ada API key Gemini di lib/', () {
    final offenders = <String>[];

    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final content = entity.readAsStringSync();
      for (final pattern in keyPatterns) {
        if (pattern.hasMatch(content)) {
          offenders.add(entity.path);
          break;
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'API key tidak boleh ada di kode sumber. Simpan lewat halaman '
          'Pengaturan (flutter_secure_storage), bukan sebagai konstanta.',
    );
  });

  test('nama slot secure storage bukan API key', () {
    final content = File('lib/features/assistant/data/ai/api_key_store.dart')
        .readAsStringSync();

    final slot = RegExp(r"static const _key = '([^']*)';").firstMatch(content);
    expect(slot, isNotNull, reason: 'konstanta _key harus tetap ada');

    final name = slot!.group(1)!;
    for (final pattern in keyPatterns) {
      expect(
        pattern.hasMatch(name),
        isFalse,
        reason:
            'Nama slot "$name" terlihat seperti API key. Slot adalah label '
            'penyimpanan, isinya diisi lewat UI.',
      );
    }
    expect(
      RegExp(r'^[a-z0-9_]+$').hasMatch(name),
      isTrue,
      reason: 'Nama slot harus identifier biasa, mis. gemini_api_key',
    );
  });
}
