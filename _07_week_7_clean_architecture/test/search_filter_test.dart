import 'package:flutter_test/flutter_test.dart';

import 'package:_07_week_7_clean_architecture/features/notes/domain/entities/note.dart';
import 'package:_07_week_7_clean_architecture/features/notes/domain/usecases/search_notes.dart';

/// Data uji: judul sengaja bervariasi huruf besar/kecil.
List<Note> _sample() => [
  Note(title: 'Belanja Bulanan', updatedAt: DateTime(2026, 10, 21)),
  Note(title: 'belanja sayur', updatedAt: DateTime(2026, 10, 22)),
  Note(title: 'Bumi Manusia', updatedAt: DateTime(2026, 10, 23)),
];

void main() {
  const search = SearchNotes();

  group('SearchNotes — pencarian judul', () {
    test('filter abaikan huruf besar/kecil (sukses)', () {
      expect(search(_sample(), 'belanja'), hasLength(2));
      expect(search(_sample(), 'BELANJA'), hasLength(2));
      expect(search(_sample(), 'BeLaNjA'), hasLength(2));
    });

    test('query tak cocok mengembalikan kosong (gagal/empty state)', () {
      expect(search(_sample(), 'zzz-tak-ada'), isEmpty);
    });

    test('query kosong mengembalikan semua catatan', () {
      expect(search(_sample(), ''), hasLength(3));
    });

    test('query hanya spasi dianggap kosong', () {
      expect(search(_sample(), '    '), hasLength(3));
    });

    test('query dengan spasi di tepi tetap cocok', () {
      expect(search(_sample(), '  bumi  '), hasLength(1));
      expect(search(_sample(), '  bumi  ').first.title, 'Bumi Manusia');
    });

    test('daftar kosong tetap aman (edge case)', () {
      expect(search(const <Note>[], 'apa pun'), isEmpty);
    });
  });
}
