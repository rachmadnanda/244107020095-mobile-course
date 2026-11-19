import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:week_12_testing_quality_assurance/features/notes/domain/entities/note.dart';
import 'package:week_12_testing_quality_assurance/features/notes/presentation/providers/notes_providers.dart';

import 'helpers/fake_note_repository.dart';

void main() {
  test('addNote memperbarui state tanpa fetch ulang seluruh tabel', () async {
    final repository = FakeNoteRepository(
      notes: [
        Note(id: 1, title: 'Catatan lama', updatedAt: DateTime(2026, 1, 1)),
      ],
    );
    final container = ProviderContainer(
      overrides: [noteRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    await container.read(notesProvider.future);
    expect(repository.fetchNotesCalls, 1);

    final failure = await container
        .read(notesProvider.notifier)
        .addNote('Catatan baru', 'Isi baru');

    expect(failure, isNull);
    expect(repository.addNoteCalls, 1);
    expect(
      repository.fetchNotesCalls,
      1,
      reason: 'addNote tidak boleh membaca ulang seluruh tabel',
    );

    final notes = container.read(notesProvider).value!;
    expect(notes, hasLength(2));
    expect(notes.first.title, 'Catatan baru');
  });

  test('deleteNote membuang item dari state tanpa fetch ulang', () async {
    final repository = FakeNoteRepository(
      notes: [
        Note(id: 1, title: 'Satu', updatedAt: DateTime(2026, 1, 1)),
        Note(id: 2, title: 'Dua', updatedAt: DateTime(2026, 1, 2)),
      ],
    );
    final container = ProviderContainer(
      overrides: [noteRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    await container.read(notesProvider.future);

    final failure = await container.read(notesProvider.notifier).deleteNote(1);

    expect(failure, isNull);
    expect(repository.deleteNoteCalls, 1);
    expect(repository.deletedIds, [1]);
    expect(repository.fetchNotesCalls, 1);
    expect(container.read(notesProvider).value!.map((note) => note.id), [2]);
  });

  test('sync memperbarui flag dirty tanpa fetch ulang', () async {
    final repository = FakeNoteRepository(
      notes: [
        Note(
          id: 1,
          title: 'Belum sinkron',
          updatedAt: DateTime(2026, 1, 1),
          dirty: true,
        ),
        Note(
          id: 2,
          title: 'Belum sinkron juga',
          updatedAt: DateTime(2026, 1, 2),
          dirty: true,
        ),
      ],
      dirtyCount: 2,
    );
    final container = ProviderContainer(
      overrides: [noteRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    await container.read(notesProvider.future);

    final synced = await container
        .read(notesProvider.notifier)
        .sync(offline: false);

    expect(synced, 2);
    expect(repository.markAllSyncedCalls, 1);
    expect(repository.fetchNotesCalls, 1);
    expect(
      container.read(notesProvider).value!.every((note) => !note.dirty),
      isTrue,
    );
  });
}
