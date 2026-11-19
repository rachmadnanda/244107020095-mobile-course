import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:week_12_testing_quality_assurance/core/failures.dart';
import 'package:week_12_testing_quality_assurance/features/notes/domain/entities/note.dart';
import 'package:week_12_testing_quality_assurance/features/notes/presentation/providers/notes_providers.dart';

import 'helpers/fake_note_repository.dart';

void main() {
  group('NotesNotifier — jalur gagal', () {
    test('fetch gagal menghasilkan state error, bukan daftar kosong', () async {
      final repository = FakeNoteRepository(
        fetchFailure: const LocalFailure('Gagal membaca catatan: db rusak'),
      );
      final container = ProviderContainer(
        overrides: [noteRepositoryProvider.overrideWithValue(repository)],
        // Riverpod 3 mencoba ulang provider yang gagal; matikan agar state
        // error bisa diperiksa langsung di test.
        retry: (_, _) => null,
      );
      addTearDown(container.dispose);

      await expectLater(
        container.read(notesProvider.future),
        throwsA(isA<Exception>()),
      );

      final state = container.read(notesProvider);
      expect(state.hasError, isTrue);
      expect(state.value, isNull);
      expect(repository.fetchNotesCalls, 1);
    });

    test('addNote gagal tidak mengubah daftar di memori', () async {
      final repository = FakeNoteRepository(
        notes: [
          Note(id: 1, title: 'Catatan lama', updatedAt: DateTime(2026, 1, 1)),
        ],
        addFailure: const LocalFailure('Gagal menyimpan catatan: db penuh'),
      );
      final container = ProviderContainer(
        overrides: [noteRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      await container.read(notesProvider.future);

      final failure = await container
          .read(notesProvider.notifier)
          .addNote('Catatan baru', 'Isi');

      expect(failure, isA<LocalFailure>());
      expect(failure?.message, 'Gagal menyimpan catatan: db penuh');
      expect(repository.addNoteCalls, 1);
      expect(container.read(notesProvider).value, hasLength(1));
      expect(container.read(notesProvider).value!.single.title, 'Catatan lama');
    });

    test('deleteNote gagal tidak membuang item dari daftar', () async {
      final repository = FakeNoteRepository(
        notes: [
          Note(id: 1, title: 'Tetap ada', updatedAt: DateTime(2026, 1, 1)),
        ],
        deleteFailure: const LocalFailure('Gagal menghapus catatan: db sibuk'),
      );
      final container = ProviderContainer(
        overrides: [noteRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      await container.read(notesProvider.future);

      final failure = await container
          .read(notesProvider.notifier)
          .deleteNote(1);

      expect(failure, isA<LocalFailure>());
      expect(repository.deleteNoteCalls, 1);
      expect(repository.deletedIds, isEmpty);
      expect(container.read(notesProvider).value, hasLength(1));
      expect(container.read(notesProvider).value!.single.id, 1);
    });
  });
}
