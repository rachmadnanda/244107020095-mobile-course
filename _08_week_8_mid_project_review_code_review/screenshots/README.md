# Screenshots — Week 8

Bukti mesin disimpan sebagai **output terminal nyata** (file `.txt`) dan
**screenshot UI** (file `.png`). Keduanya diambil dari project
`../../_07_week_7_clean_architecture/` pasca-merge PR #1.

## Bukti visual (UI)

| File | Yang ditunjukkan | Membuktikan |
| --- | --- | --- |
| `validation-error.png` | Dialog "Tambah Catatan" dengan Judul kosong + SnackBar "Judul catatan tidak boleh kosong" di bagian bawah | PR #1: validasi judul kosong bekerja di UI |
| `notes-list-unchanged.png` | Daftar catatan berisi item (Madilog, Bumi Manusia) + toggle Offline + tombol pengaturan/sinkron | Aplikasi berjalan identik dengan akhir Week 7 pasca-review |
| `branch-structure.png` | Output `git log --oneline --graph --all` + `git branch` menampilkan `main` dan `develop` | Git Flow diterapkan (release merge dari develop ke main) |

## Bukti terminal (teks)

| File | Isi | Membuktikan |
| --- | --- | --- |
| `analyze-format-output.txt` | Output `flutter analyze` + `dart format --set-exit-if-changed .` | Analyze bersih (0 error/warning), format exit 0 |
| `flutter-test-output.txt` | Output `flutter test` | 13/13 test lulus |
| `git-log-output.txt` | `git log --oneline --graph --all` + `git branch` | Struktur branch `main`/`develop`, squash merge PR #1 |
