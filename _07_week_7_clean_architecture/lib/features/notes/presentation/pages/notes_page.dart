import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/notes_providers.dart';
import '../widgets/note_tile.dart';

/// Halaman daftar catatan. Hanya membaca state — tanpa SQL, Dio, JSON, atau
/// aturan pencarian. Filter dijalankan use case `SearchNotes` lewat provider.
class NotesPage extends ConsumerStatefulWidget {
  const NotesPage({super.key});

  @override
  ConsumerState<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends ConsumerState<NotesPage> {
  /// Controller hanya mengurus teks yang tampil di field; nilai query tetap
  /// hidup di `searchQueryProvider`.
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _showAddNoteDialog(BuildContext context) async {
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

  Future<void> _onSync(BuildContext context) async {
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
  Widget build(BuildContext context) {
    final notes = ref.watch(notesProvider);
    final filtered = ref.watch(filteredNotesProvider);
    final query = ref.watch(searchQueryProvider);

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
            onPressed: () => _onSync(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari judul catatan',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Hapus pencarian',
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          // Kosongkan teks yang tampil DAN state query.
                          _searchController.clear();
                          ref.read(searchQueryProvider.notifier).state = '';
                        },
                      ),
              ),
              onChanged: (value) =>
                  ref.read(searchQueryProvider.notifier).state = value,
            ),
          ),
          Expanded(
            child: filtered.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) =>
                  Center(child: Text('Terjadi kesalahan: $error')),
              data: (items) {
                if (items.isEmpty) {
                  final hasAnyNote = notes.value?.isNotEmpty ?? false;
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            hasAnyNote
                                ? Icons.search_off
                                : Icons.note_alt_outlined,
                            size: 48,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            hasAnyNote
                                ? 'Tidak ada catatan yang cocok dengan "$query"'
                                : 'Belum ada catatan',
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
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
                          : () => ref
                                .read(notesProvider.notifier)
                                .deleteNote(note.id!),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddNoteDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
