import '../../../../core/failures.dart';
import '../repositories/note_repository.dart';

/// Use case: sinkronisasi catatan yang `dirty` ke backend.
///
/// Menggabungkan aturan bisnis (tolak saat offline + hitung yang tersinkron)
/// dengan >1 operasi repository — inilah alasan operasi ini menjadi use case,
/// bukan repository langsung ke notifier.
class SyncNotes {
  const SyncNotes(this._repository);

  final NoteRepository _repository;

  /// Mengembalikan jumlah catatan yang disinkronkan, atau `failure`.
  Future<({int synced, Failure? failure})> call({bool offline = false}) async {
    if (offline) {
      return (
        synced: 0,
        failure: const NetworkFailure(
          'Sinkronisasi tidak tersedia saat mode offline aktif',
        ),
      );
    }

    final dirty = await _repository.countDirty();
    if (dirty.failure != null) return (synced: 0, failure: dirty.failure);

    if (dirty.count == 0) return (synced: 0, failure: null);

    final mark = await _repository.markAllSynced();
    if (mark.failure != null) return (synced: 0, failure: mark.failure);

    return (synced: dirty.count, failure: null);
  }
}
