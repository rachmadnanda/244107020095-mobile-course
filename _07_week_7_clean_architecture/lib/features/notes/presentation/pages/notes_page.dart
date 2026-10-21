import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/notes_providers.dart';
import '../widgets/note_tile.dart';

/// Halaman daftar catatan. Hanya membaca state — tanpa SQL, Dio, JSON, atau
/// formatting tanggal mentah. Semua logika melalui provider.
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
                // Validasi & normalisasi input dilakukan di use case
                // AddNote; UI mengirim nilai mentah dari controller.
                final failure = await ref
                    .read(notesProvider.notifier)
                    .addNote(titleController.text, bodyController.text);

                if (context.mounted) {
                  if (failure != null) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text(failure.message)));
                  } else {
                    Navigator.pop(context);
                  }
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

  Future<void> _onSync(BuildContext context, WidgetRef ref) async {
    final offline = ref.read(forceOfflineProvider);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final count = await ref
          .read(notesProvider.notifier)
          .sync(offline: offline);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            count == 0
                ? 'Tidak ada catatan yang perlu disinkronkan'
                : '$count catatan berhasil disinkronkan',
          ),
        ),
      );
    } catch (error) {
      // Failure sudah berupa pesan ramah pengguna (Exception(message)).
      messenger.showSnackBar(
        SnackBar(content: Text('$error'.replaceFirst('Exception: ', ''))),
      );
    }
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
                onChanged: (value) =>
                    ref.read(forceOfflineProvider.notifier).state = value,
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
            onPressed: () => _onSync(context, ref),
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
                    : () =>
                          ref.read(notesProvider.notifier).deleteNote(note.id!),
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
