/// Entity bisnis `Note`. Objek murni — TANPA toMap/fromMap/toJson.
///
/// Mapping ke representasi luar (SQLite/JSON) hanya dilakukan oleh `NoteModel`
/// di layer data, sehingga entity tetap bebas framework.
class Note {
  const Note({
    this.id,
    required this.title,
    this.body = '',
    required this.updatedAt,
    this.dirty = false,
  });

  final int? id;
  final String title;
  final String body;
  final DateTime updatedAt;
  final bool dirty;

  /// Salinan entity dengan sebagian field diganti.
  ///
  /// Dipakai presentation untuk memperbarui state lokal setelah sinkronisasi
  /// tanpa membaca ulang seluruh tabel.
  Note copyWith({
    int? id,
    String? title,
    String? body,
    DateTime? updatedAt,
    bool? dirty,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      updatedAt: updatedAt ?? this.updatedAt,
      dirty: dirty ?? this.dirty,
    );
  }
}
