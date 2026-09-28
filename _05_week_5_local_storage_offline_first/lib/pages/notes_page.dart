import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local/note.dart';
import '../data/repositories/note_repository.dart';

final noteRepositoryProvider = Provider((ref) => NoteRepository());

final notesProvider = AsyncNotifierProvider<NotesNotifier, List<Note>>(
  NotesNotifier.new,
);

class NotesNotifier extends AsyncNotifier<List<Note>> {
  @override
  Future<List<Note>> build() {
    return ref.watch(noteRepositoryProvider).fetchNotes();
  }

  Future<void> addNote(String title, String body) async {
    await ref.read(noteRepositoryProvider).addNote(title: title, body: body);

    ref.invalidateSelf();
    await future;
  }

  Future<void> deleteNote(int id) async {
    await ref.read(noteRepositoryProvider).deleteNote(id);

    ref.invalidateSelf();
    await future;
  }
}

class NotesPage extends ConsumerWidget {
  const NotesPage({super.key});

  Future<void> _showAddNoteDialog(BuildContext context, WidgetRef ref) async {
    final titleController = TextEditingController();
    final bodyController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Tambah Catatan'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Judul'),
              ),
              TextField(
                controller: bodyController,
                decoration: const InputDecoration(labelText: 'Isi'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () async {
                final title = titleController.text.trim();
                final body = bodyController.text.trim();

                if (title.isEmpty) return;

                await ref.read(notesProvider.notifier).addNote(title, body);

                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );

    titleController.dispose();
    bodyController.dispose();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notes = ref.watch(notesProvider);
    final repository = ref.watch(noteRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Catatan'),
        actions: [
          FutureBuilder<int>(
            future: repository.countDirty(),
            builder: (context, snapshot) {
              final count = snapshot.data ?? 0;

              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(child: Text('Belum sinkron: $count')),
              );
            },
          ),
        ],
      ),
      body: notes.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Terjadi kesalahan: $error')),
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('Belum ada catatan'));
          }

          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final note = items[index];

              return ListTile(
                title: Text(note.title),
                subtitle: Text(note.body),
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    if (note.id != null) {
                      ref.read(notesProvider.notifier).deleteNote(note.id!);
                    }
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddNoteDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }
}
