# Screenshots — Week 9

Bukti berupa **output terminal nyata** (`.txt`) dan **screenshot UI** (`.png`).

## Bukti terminal

| File | Isi | Membuktikan |
| --- | --- | --- |
| `analyze-draft-v1.txt` | `flutter analyze` pada DRAFT v1 AI | Halusinasi `containsIgnoreCase` (`undefined_method`) + import `sqflite` di presentation |
| `test-red-before-fix.txt` | `flutter test test/search_filter_test.dart` sebelum refactor | Bug case-sensitive & tanpa trim terbukti (2 test merah) |
| `test-red-clear-button.txt` | Test widget tombol clear sebelum perbaikan | Bug "field tidak kosong" (`Expected: empty, Actual: 'bumi'`) |
| `analyze-format-final.txt` | `flutter analyze` + `dart format --set-exit-if-changed .` | Analyze bersih, format exit 0 |
| `flutter-test-final.txt` | `flutter test` | 23/23 test lulus |
| `greps-sterility.txt` | 4 grep sterilitas | Presentation & domain steril; filter tidak di presentation |

## Screenshot UI

| File | Yang ditunjukkan | Membuktikan |
| --- | --- | --- |
| `search-results.png` | Query "bumi" → 1 hasil (Bumi Manusia) | Pencarian berjalan |
| `search-case-insensitive.png` | Query "BUMI" → hasil sama | Case-insensitive (bug AI v2 sudah diperbaiki) |
| `search-empty.png` | Query "zzz" → empty state | Empty state + pesan query |
| `search-clear.png` | Setelah tombol clear → semua catatan, field kosong | Temuan AI #1 diperbaiki |

Cara mengambil: jalankan `flutter run` di `../../_07_week_7_clean_architecture/`,
lalu ikuti query di tabel.
