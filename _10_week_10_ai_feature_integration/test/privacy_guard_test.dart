import 'package:flutter_test/flutter_test.dart';

import 'package:_10_week_10_ai_feature_integration/features/assistant/domain/services/privacy_guard.dart';

void main() {
  const guard = PrivacyGuard();

  group('PrivacyGuard.redact', () {
    test('meredaksi email', () {
      final result = guard.redact('Hubungi saya di budi.santoso@gmail.com ya');
      expect(result, contains('[email]'));
      expect(result, isNot(contains('gmail.com')));
    });

    test('meredaksi NIK 16 digit tanpa pemisah', () {
      final result = guard.redact('NIK saya 3573012504950001');
      expect(result, contains('[nik]'));
      expect(result, isNot(contains('3573012504950001')));
    });

    test('meredaksi NIK 16 digit dengan pemisah', () {
      final result = guard.redact('NIK: 3573-0125-0495-0001');
      expect(result, contains('[nik]'));
      expect(result, isNot(contains('3573-0125-0495-0001')));
    });

    test('meredaksi nomor telepon 08xx', () {
      final result = guard.redact('Telp 081234567890');
      expect(result, contains('[telepon]'));
      expect(result, isNot(contains('081234567890')));
    });

    test('meredaksi nomor telepon +62', () {
      final result = guard.redact('WA +6281234567890');
      expect(result, contains('[telepon]'));
      expect(result, isNot(contains('6281234567890')));
    });

    test('tidak merusak teks biasa', () {
      const input = 'Belanja sayur dan buah besok pagi';
      expect(guard.redact(input), input);
    });

    test('meredaksi beberapa data pribadi sekaligus', () {
      final result = guard.redact(
        'NIK 3573012504950001, email a@b.co, telp 081234567890',
      );
      expect(result, contains('[nik]'));
      expect(result, contains('[email]'));
      expect(result, contains('[telepon]'));
    });
  });

  group('PrivacyGuard.trimContext', () {
    test('teks pendek tidak diubah', () {
      expect(guard.trimContext('  halo  '), 'halo');
    });

    test('teks panjang dipotong pada batas kata', () {
      final long = List.filled(400, 'kata').join(' ');
      final result = guard.trimContext(long);
      expect(
        result.length,
        lessThanOrEqualTo(PrivacyGuard.maxContextChars + 20),
      );
      expect(result, endsWith('… (dipotong)'));
      // Tidak memotong di tengah kata: karakter sebelum penanda adalah huruf.
      final body = result.replaceAll('… (dipotong)', '').trimRight();
      expect(body.endsWith('kata'), isTrue);
    });
  });

  group('PrivacyGuard.sanitize', () {
    test('menggabungkan redaksi dan trim', () {
      final result = guard.sanitize('  email saya a@b.co  ');
      expect(result, 'email saya [email]');
    });
  });
}
