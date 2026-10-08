import 'package:flutter_test/flutter_test.dart';

import 'package:_06_week_6_authentication_security_fcm/data/auth_repository.dart';
import 'package:_06_week_6_authentication_security_fcm/messaging/route_parser.dart';

/// Tiruan penyimpanan token (tanpa Firebase / secure storage).
class FakeTokenStore {
  FakeTokenStore({this.access, this.refresh});

  String? access;
  String? refresh;

  bool get isLoggedIn => access != null;

  Future<void> clear() async {
    access = null;
    refresh = null;
  }
}

void main() {
  group('routeFromMessage (parsing deep link FCM)', () {
    test('route kosong -> home', () {
      expect(routeFromMessage({}), '/');
    });

    test('route tanpa slash -> ditambah slash', () {
      expect(routeFromMessage({'route': 'pengumuman/3'}), '/pengumuman/3');
    });

    test('route dengan slash tetap', () {
      expect(routeFromMessage({'route': '/pengumuman/3'}), '/pengumuman/3');
    });

    test('data payload membawa id pengumuman', () {
      const data = {'route': '/pengumuman/3', 'id': '3'};
      expect(data['id'], '3');
      expect(routeFromMessage(data), '/pengumuman/3');
    });
  });

  group('logika sesi & refresh', () {
    test('status login dibaca dari access token', () {
      final store = FakeTokenStore(access: 'mock-access');
      expect(store.isLoggedIn, isTrue);

      store.access = null;
      expect(store.isLoggedIn, isFalse);
    });

    test('refresh mati -> sesi dibersihkan (paksa login ulang)', () async {
      final store = FakeTokenStore(access: 'mock-access', refresh: '');
      final needsLogin = (store.refresh ?? '').isEmpty;
      expect(needsLogin, isTrue);

      await store.clear();
      expect(store.access, isNull);
      expect(store.refresh, isNull);
    });

    test('AuthRepository.refresh menolak refresh token kosong', () async {
      final auth = AuthRepository();
      await expectLater(auth.refresh(''), throwsA(isA<Exception>()));
    });
  });
}
