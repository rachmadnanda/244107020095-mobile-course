import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/prefs_repository.dart';

// Satu-satunya tempat wiring DI untuk fitur settings.

final prefsRepositoryProvider = Provider<PrefsRepository>(
  (ref) => PrefsRepository(),
);

final darkModeProvider = AsyncNotifierProvider<DarkModeNotifier, bool>(
  DarkModeNotifier.new,
);

class DarkModeNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() => ref.watch(prefsRepositoryProvider).getDarkMode();

  /// Optimistic update: tema berubah segera, tanpa melewati `AsyncLoading`.
  ///
  /// Efeknya satu rebuild saja (bukan loading + data) dan tidak ada kedipan
  /// tema. Bila penyimpanan gagal, nilai sebelumnya dikembalikan.
  Future<void> toggle() async {
    final previous = state.value ?? false;
    final next = !previous;
    state = AsyncData(next);
    try {
      await ref.read(prefsRepositoryProvider).setDarkMode(next);
    } catch (error) {
      state = AsyncData(previous);
      debugPrint('Gagal menyimpan preferensi tema: $error');
    }
  }
}
