# AI Challenge — Review AI vs Keputusan Final

AI boleh menjadi reviewer awal; keputusan final tetap milik author. Dokumen
ini menyimpan prompt, output awal AI (mentah), verifikasi tiap temuan, dan
tabel usulan-vs-keputusan.

## 1. Prompt yang diberikan

```text
Review PR Flutter ini sebagai senior Flutter dev.
Konteks: feature-first Clean Architecture (presentation -> domain <- data),
Riverpod, GoRouter, SQLite + Dio.
Fokus: kebenaran, arsitektur, dan test. Abaikan style.
Berikan 5 temuan teratas + level (blocker/saran)
+ alasan + usulan potongan kode perbaikan.

[diff PR #1: feat(notes) validasi judul kosong + test, 179 baris]
```

## 2. Output awal AI (mentah)

> **F1 — (saran, kebenaran/kekonsistenan kontrak):** `NotesNotifier.build()`
> dan `sync()` melempar `Exception(result.failure!.message)`, sementara
> `addNote`/`deleteNote` mengembalikan `Failure?`. Kontrak error tidak
> konsisten, dan UI harus membersihkan string dengan
> `'$error'.replaceFirst('Exception: ', '')` yang rapuh — sekali format
> `toString()` berubah, pesan yang tampil ikut berubah.
> Usul: seragamkan — kembalikan `Failure`/record dari notifier, atau bungkus
> state error lewat `AsyncValue` tanpa parsing string.
>
> **F2 — (saran, test):** `SpyNoteRepository` di `validate_note_test.dart`
> menduplikasi `FakeNoteRepository` di `note_test.dart` untuk kontrak yang
> sama. Perubahan interface `NoteRepository` harus disunting di dua tempat.
> Usul: ekstrak satu fake bersama di `test/helpers/fake_note_repository.dart`.
>
> **F3 — (blocker, kebenaran):** `titleController` dan `bodyController`
> berpotensi bocor memori: jika dialog ditutup lewat tap di luar
> (barrier dismiss), `dispose()` tidak terpanggil.
> Usul: bungkus dengan `try/finally` atau gunakan `StatefulBuilder`.
>
> **F4 — (saran, style):** Tambahkan `const` pada `SnackBar` dan pertimbangkan
> `FilledButton.tonal` untuk aksi batal.
>
> **F5 — (saran, arsitektur):** `ValidationFailure` berada di `core/`
> padahal hanya dipakai fitur notes; pindahkan ke
> `features/notes/domain/` agar `core` tetap minimal.

## 3. Verifikasi tiap temuan

| # | Klaim AI | Verifikasi | Terbukti? |
| --- | --- | --- | --- |
| F1 | Notifier melempar `Exception`, UI mem-parsing string | `grep -n "throw Exception" notes_providers.dart` → baris 48, 75, 85; `grep -n "replaceFirst" notes_page.dart` → baris 87 (`'$error'.replaceFirst('Exception: ', '')`) | **BENAR** |
| F2 | Dua fake repository untuk kontrak sama | `grep -l "implements NoteRepository" test/*.dart` → `note_test.dart` + `validate_note_test.dart` | **BENAR** |
| F3 | Controller bocor saat barrier dismiss | Baca `notes_page.dart`: `await showDialog(...)` (baris 17) **selalu dilanjutkan** ke `titleController.dispose()` (64) dan `bodyController.dispose()` (65) setelah route pop — apapun cara dialog ditutup. Reproduksi manual: dismiss via barrier, tidak ada leak | **SALAH** — tuduhan tidak terbukti |
| F4 | `const`/varian tombol | Nitpick style murni; ranah `dart format`/linter, bukan review manusia (prompt pun sudah bilang "abaikan style") | **DITOLAK** sebagai nitpick |
| F5 | `ValidationFailure` harus pindah ke domain notes | `core/failures.dart` adalah layer paling dalam — dipakai domain **dan** data (`LocalFailure`, `NetworkFailure`). Memindah satu subtipe ke satu fitur memecah hierarki `sealed class Failure` dan menduplikasi pola | **DITOLAK** — tidak melanggar dependency rule, justru menjaga konsistensi |

Cek dependency rule untuk usulan AI: tidak ada usulan yang membuat domain
mengimpor Flutter/Dio/SQLite — namun F5 justru **salah arah** (memecah tipe
bersama di layer dalam), sehingga ditolak dengan argumen arsitektur.

## 4. Tabel usulan AI vs keputusan final

| Usulan AI | Keputusan final | Alasan teknis |
| --- | --- | --- |
| F1: konsistenkan kontrak error notifier | **Diterima sebagai issue lanjutan (#2)** | Terbukti benar, tetapi refactor kontrak error menyentuh `build`/`sync`/`noteByIdProvider` + UI — di luar cakupan PR validasi 179 baris. Dicatat, bukan dicampur ke PR kecil. |
| F2: ekstrak fake bersama | **Diterima, ditunda** | Terbukti benar; dieksekusi saat fake ketiga muncul agar PR tetap < 300 baris. |
| F3: memory leak controller | **Ditolak** | Tuduhan tidak terbukti: `dispose()` selalu berjalan setelah `await showDialog` selesai, termasuk barrier dismiss. Tidak ada perubahan kode. |
| F4: const & varian tombol | **Ditolak** | Nitpick style; sudah ditangani formatter/linter/CI. |
| F5: pindah `ValidationFailure` ke domain notes | **Ditolak** | `core/` adalah layer dalam yang sah; memindah subtipe memecah `sealed class` dan menduplikasi pola antar-fitur. |

**Ringkasan:** 2 temuan AI terbukti benar (dengan bukti grep), 3 ditolak
dengan alasan tertulis. Keputusan final berbeda dari output mentah AI pada
3 dari 5 temuan — review AI diverifikasi dulu, tidak diterima mentah.

## 5. Bukti mesin pasca-keputusan

```text
flutter analyze  → 0 error, 0 warning (sisa info package_names bawaan repo)
dart format --set-exit-if-changed . → exit 0
flutter test     → 13/13 lulus
```
