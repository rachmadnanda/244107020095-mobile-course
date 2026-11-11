import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:week_11_performance_optimization/features/notes/domain/entities/note.dart';
import 'package:week_11_performance_optimization/features/notes/presentation/providers/notes_providers.dart';

import 'helpers/fake_note_repository.dart';

void main() {
  test('provider detail ditandai auto-dispose', () {
    expect(noteByIdProvider(1).isAutoDispose, isTrue);
  });

  test('provider detail dilepas setelah listener terakhir ditutup', () async {
    final repository = FakeNoteRepository(
      notes: [Note(id: 1, title: 'Detail', updatedAt: DateTime(2026, 1, 1))],
    );
    final container = ProviderContainer(
      overrides: [noteRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    final subscription = container.listen(
      noteByIdProvider(1),
      (previous, next) {},
    );
    await container.read(noteByIdProvider(1).future);

    expect(container.exists(noteByIdProvider(1)), isTrue);

    subscription.close();
    await Future<void>.delayed(Duration.zero);

    expect(container.exists(noteByIdProvider(1)), isFalse);
  });
}
