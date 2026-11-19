import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dev_seed_service.dart';

/// Wiring untuk alat bantu profiling. Hanya dipakai di debug/profile.
final devSeedServiceProvider = Provider<DevSeedService>(
  (ref) => const DevSeedService(),
);
