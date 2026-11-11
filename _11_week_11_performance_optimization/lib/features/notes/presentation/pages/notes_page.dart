import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/notes_providers.dart';
import '../widgets/add_note_dialog.dart';
import '../widgets/note_tile.dart';

/// Halaman daftar catatan.
///
/// Halaman ini sengaja dibuat **stateless dan tanpa `ref.watch`**. Bagian yang
/// berubah (search field, daftar, aksi AppBar) adalah widget terpisah, sehingga
/// mengetik di pencarian tidak membangun ulang seluruh Scaffold/AppBar/FAB.
class NotesPage extends StatelessWidget {
  const NotesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catatan'),
        actions: const [NotesAppBarActions()],
      ),
      body: const Column(
        children: [
          NotesSearchField(),
          Expanded(child: NotesBody()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showAddNoteDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}

/// Aksi AppBar: mode offline, asisten, pengaturan, dan sinkronisasi.
///
/// Hanya widget ini yang ikut rebuild saat status offline berubah.
class NotesAppBarActions extends ConsumerWidget {
  const NotesAppBarActions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offline = ref.watch(forceOfflineProvider);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Switch(
          value: offline,
          onChanged: (value) =>
              ref.read(forceOfflineProvider.notifier).state = value,
        ),
        const Center(
          child: Padding(
            padding: EdgeInsets.only(right: 8),
            child: Text('Offline'),
          ),
        ),
        IconButton(
          tooltip: 'Asisten AI',
          icon: const Icon(Icons.auto_awesome),
          onPressed: () => context.push('/assistant'),
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
    );
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
}

/// Field pencarian. Hanya bergantung pada status kosong/terisi query, bukan
/// seluruh isi query — sehingga tidak rebuild tiap ketukan.
class NotesSearchField extends ConsumerStatefulWidget {
  const NotesSearchField({super.key});

  @override
  ConsumerState<NotesSearchField> createState() => _NotesSearchFieldState();
}

class _NotesSearchFieldState extends ConsumerState<NotesSearchField> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEmpty = ref.watch(
      searchQueryProvider.select((query) => query.isEmpty),
    );

    return Padding(
      padding: const EdgeInsets.all(8),
      child: TextField(
        controller: _controller,
        decoration: InputDecoration(
          hintText: 'Cari judul catatan',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: isEmpty
              ? null
              : IconButton(
                  tooltip: 'Hapus pencarian',
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    // Kosongkan teks yang tampil DAN state query.
                    _controller.clear();
                    ref.read(searchQueryProvider.notifier).state = '';
                  },
                ),
        ),
        onChanged: (value) =>
            ref.read(searchQueryProvider.notifier).state = value,
      ),
    );
  }
}

/// Bagian daftar: loading, error, empty state, dan `ListView.builder`.
class NotesBody extends ConsumerWidget {
  const NotesBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filtered = ref.watch(filteredNotesProvider);
    final hasAnyNote = ref.watch(hasAnyNotesProvider);
    final query = ref.watch(searchQueryProvider);

    return filtered.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Terjadi kesalahan: $error')),
      data: (items) {
        if (items.isEmpty) {
          return _EmptyNotesState(hasAnyNote: hasAnyNote, query: query);
        }
        return ListView.builder(
          itemCount: items.length,
          addAutomaticKeepAlives: false,
          itemBuilder: (context, index) {
            final note = items[index];
            return NoteTile(
              key: ValueKey(note.id ?? index),
              note: note,
              onTap: () {
                if (note.id != null) context.push('/note/${note.id}');
              },
              onDelete: note.id == null
                  ? () {}
                  : () => ref.read(notesProvider.notifier).deleteNote(note.id!),
            );
          },
        );
      },
    );
  }
}

class _EmptyNotesState extends StatelessWidget {
  const _EmptyNotesState({required this.hasAnyNote, required this.query});

  final bool hasAnyNote;
  final String query;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasAnyNote ? Icons.search_off : Icons.note_alt_outlined,
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
}
