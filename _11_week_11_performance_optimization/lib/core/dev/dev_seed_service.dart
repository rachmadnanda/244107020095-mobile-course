import 'package:sqflite/sqflite.dart';

import '../../features/notes/data/local/db.dart';

/// Alat bantu **khusus pengembangan/profiling**.
///
/// Tidak dipakai oleh alur produksi. Tujuannya membuat beban uji yang sama
/// setiap kali baseline/after diukur, sehingga perbandingan frame time sah.
class DevSeedService {
  const DevSeedService();

  /// Mengganti seluruh isi tabel `notes` dengan [count] catatan contoh.
  ///
  /// Dipakai lewat `--dart-define=SEED_NOTES=1000` atau tombol di Pengaturan
  /// (hanya tersedia saat bukan release).
  Future<void> replaceWithSample(int count) async {
    final db = await openNotesDb();
    await db.delete('notes');
    await _insertSample(db, count);
  }

  /// Menambahkan catatan contoh tanpa menghapus data yang sudah ada.
  Future<void> appendSample(int count) async {
    final db = await openNotesDb();
    await _insertSample(db, count);
  }

  Future<void> clearNotes() async {
    final db = await openNotesDb();
    await db.delete('notes');
  }

  Future<void> _insertSample(Database db, int count) async {
    final now = DateTime.now();
    final batch = db.batch();
    for (var i = 0; i < count; i++) {
      batch.insert('notes', {
        'title': 'Catatan contoh ${(i + 1).toString().padLeft(4, '0')}',
        'body':
            'Ini adalah isi catatan contoh nomor ${i + 1}. '
            'Data ini dipakai untuk mengukur performa daftar, pencarian, '
            'dan navigasi. Isinya sengaja cukup panjang agar biaya layout '
            'teks ikut terukur saat daftar di-scroll.',
        'updated_at': now.subtract(Duration(minutes: i)).toIso8601String(),
        'dirty': i % 7 == 0 ? 1 : 0,
      });
    }
    await batch.commit(noResult: true);
  }
}
