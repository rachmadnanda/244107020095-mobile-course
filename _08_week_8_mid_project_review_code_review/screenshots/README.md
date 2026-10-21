# Screenshots — Week 8

Bukti mesin disimpan sebagai **output terminal nyata** (file `.txt`), bukan
gambar rekayasa. Untuk bukti UI, jalankan `flutter run` di folder
`../_07_week_7_clean_architecture/` lalu ambil screenshot sesuai tabel.

## Bukti terminal (sudah ada)

| File | Isi | Membuktikan |
| --- | --- | --- |
| `analyze-format-output.txt` | Output `flutter analyze` + `dart format --set-exit-if-changed .` | Analyze bersih (0 error/warning), format exit 0 |
| `flutter-test-output.txt` | Output `flutter test` | 13/13 test lulus |
| `git-log-output.txt` | `git log --oneline --graph --all` + `git branch` | Struktur branch `main`/`develop`, squash merge PR #1 |

## Placeholder screenshot UI (jalankan aplikasi lalu ambil)

| File | Yang ditunjukkan | Membuktikan |
| --- | --- | --- |
| `validation-error.png` | Dialog tambah catatan + SnackBar "Judul catatan tidak boleh kosong" | PR #1: validasi judul kosong bekerja di UI |
| `notes-list-unchanged.png` | Daftar catatan seperti akhir Week 7 | Aplikasi berjalan identik pasca-review |
| `branch-structure.png` | `git branch` menampilkan `main` + `develop` | Git Flow diterapkan |
