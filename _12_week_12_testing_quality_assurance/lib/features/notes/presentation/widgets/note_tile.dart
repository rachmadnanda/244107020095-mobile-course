import 'package:flutter/material.dart';

import '../../domain/entities/note.dart';

/// Widget kartu catatan. Murni presentasi — hanya menerima entity `Note`.
///
/// `maxLines` dipakai agar layout teks panjang tidak dihitung untuk seluruh
/// isi catatan pada setiap item daftar.
class NoteTile extends StatelessWidget {
  const NoteTile({
    required this.note,
    required this.onTap,
    required this.onDelete,
    super.key,
  });

  final Note note;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      title: Text(note.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(note.body, maxLines: 2, overflow: TextOverflow.ellipsis),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (note.dirty) const _DirtyBadge(),
          IconButton(
            tooltip: 'Hapus catatan',
            icon: const Icon(Icons.delete_outline),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

class _DirtyBadge extends StatelessWidget {
  const _DirtyBadge();

  @override
  Widget build(BuildContext context) {
    return const Chip(
      label: Text('Belum tersinkron'),
      visualDensity: VisualDensity.compact,
    );
  }
}
