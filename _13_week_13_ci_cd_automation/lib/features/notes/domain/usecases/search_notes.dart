import '../entities/note.dart';

/// Use case: menyaring catatan berdasarkan judul (pencarian).
///
/// Aturan bisnis pencarian — murni Dart, tanpa Flutter/SQLite/Dio:
/// - query di-trim (spasi di tepi diabaikan);
/// - pencocokan **case-insensitive** pada judul;
/// - query kosong mengembalikan seluruh catatan (tanpa filter).
///
/// Sengaja berupa fungsi murni `call` agar bisa diuji tanpa widget.
class SearchNotes {
  const SearchNotes();

  List<Note> call(List<Note> notes, String query) {
    final keyword = query.trim().toLowerCase();
    if (keyword.isEmpty) return notes;
    return notes
        .where((note) => note.title.toLowerCase().contains(keyword))
        .toList();
  }
}
