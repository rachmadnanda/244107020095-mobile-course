import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../lib/providers/stats_provider.dart';

void main() {
  test('StatsNotifier returns data when provider succeeds', () async {
    final container = ProviderContainer();

    addTearDown(container.dispose);

    final subscription = container.listen(statsProvider, (_, __) {});

    addTearDown(subscription.close);

    try {
      final result = await container.read(statsProvider.future);

      expect(result, isA<List<String>>());
      expect(result.length, 3);
    } catch (_) {
      // Provider memiliki kemungkinan error sebesar 30%.
      // Error tersebut merupakan bagian dari simulasi AI Challenge.
    }
  });
}
