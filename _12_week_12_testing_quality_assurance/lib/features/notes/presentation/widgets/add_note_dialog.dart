import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/notes_providers.dart';

/// Membuka dialog tambah catatan.
Future<void> showAddNoteDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (context) => const AddNoteDialog(),
  );
}

/// Dialog tambah catatan.
///
/// Controller hidup selama dialog, lalu di-dispose saat dialog ditutup —
/// bukan menunggu `showDialog` selesai di halaman pemanggil.
class AddNoteDialog extends ConsumerStatefulWidget {
  const AddNoteDialog({super.key});

  @override
  ConsumerState<AddNoteDialog> createState() => _AddNoteDialogState();
}

class _AddNoteDialogState extends ConsumerState<AddNoteDialog> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    // Validasi & normalisasi input dilakukan di use case AddNote; UI mengirim
    // nilai mentah dari controller.
    final failure = await ref
        .read(notesProvider.notifier)
        .addNote(_titleController.text, _bodyController.text);

    if (!mounted) return;
    if (failure != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(failure.message)));
      return;
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tambah Catatan'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            key: const Key('note-title-field'),
            controller: _titleController,
            decoration: const InputDecoration(labelText: 'Judul'),
          ),
          TextField(
            key: const Key('note-body-field'),
            controller: _bodyController,
            decoration: const InputDecoration(labelText: 'Isi'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        FilledButton(
          key: const Key('save-note-button'),
          onPressed: _save,
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}
