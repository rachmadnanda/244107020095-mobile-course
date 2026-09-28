import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:go_router/go_router.dart';

import '../data/local/note.dart';
import '../data/repositories/note_repository.dart';
import '../data/sync.dart';
import '../widgets/note_tile.dart';

final forceOfflineProvider = StateProvider<bool>((ref) => false);

final noteRepositoryProvider = Provider((ref) => NoteRepository());

final notesProvider = AsyncNotifierProvider<NotesNotifier, List<Note>>(
  NotesNotifier.new,
);

class NotesNotifier extends AsyncNotifier<List<Note>> {
  @override
  Future<List<Note>> build() async {
    return await ref.watch(noteRepositoryProvider).fetchNotes();
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catatan'),
        actions: [
          Consumer(
            builder: (context, ref, child) {
              final offline = ref.watch(forceOfflineProvider);

              return Switch(
                value: offline,
                onChanged: (value) {
                  ref.read(forceOfflineProvider.notifier).state = value;
                },
              );
            },
          ),
          const Center(
            child: Padding(
              padding: EdgeInsets.only(right: 8),
              child: Text('Offline'),
            ),
          ),
          IconButton(
            tooltip: 'Pengaturan',
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
          ),
          IconButton(
            tooltip: 'Sinkronisasi',
            icon: const Icon(Icons.sync),
            onPressed: () async {
              try {
                final count = await syncNotes(
                  ref.read(noteRepositoryProvider),
                  offline: ref.read(forceOfflineProvider),
                );

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        count == 0
                            ? 'Tidak ada catatan yang perlu disinkronkan'
                            : '$count catatan berhasil disinkronkan',
                      ),
                    ),
                  );
                }
              } on StateError catch (error) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(error.message)),
                  );
                }
              }

              ref.invalidate(notesProvider);
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

              return NoteTile(
                note: note,
                onTap: () => context.push('/note/${note.id}'),
                onDelete: note.id == null
                    ? () {}
                    : () => ref.read(notesProvider.notifier).deleteNote(note.id!),
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
