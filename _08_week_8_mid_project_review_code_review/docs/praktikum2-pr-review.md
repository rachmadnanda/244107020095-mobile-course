# Praktikum 2 — Pull Request & Code Review

> Catatan: repository ini belum memiliki akses push/GitHub CLI, sehingga alur
> issue → PR → review → merge **disimulasikan secara lokal** dengan disiplin
> yang sama: teks issue dan PR ditulis lengkap, review memakai checklist
> codelab, dan merge dilakukan via `git merge --squash` ke `develop`.

## 1. Issue

```text
Issue #1 — Catatan tanpa judul bisa "disimpan" tanpa umpan balik

Langkah reproduksi:
1. Jalankan aplikasi (_07_week_7_clean_architecture).
2. Tekan FAB (+), kosongkan field Judul, tekan Simpan.
3. Tidak terjadi apa-apa: dialog tetap terbuka, tidak ada pesan error,
   pengguna mengira aplikasi macet.

Penyebab: notes_page.dart memiliki `if (title.isEmpty) return;` — diam-diam
keluar tanpa feedback, dan use case AddNote tidak punya validasi sama sekali.

Ekspektasi: judul kosong ditolak dengan pesan error yang jelas.
```

## 2. Pull Request

```text
Judul: feat(notes): validasi judul kosong + test

Masalah: pengguna bisa menekan Simpan dengan judul kosong dan tidak
mendapat umpan balik apa pun (dialog tetap terbuka, tidak ada error).

Solusi:
- Validasi di use case AddNote: judul kosong/hanya spasi → ValidationFailure
  dengan pesan ramah pengguna (aturan bisnis tinggal di domain, bukan UI).
- Normalisasi (trim) judul & body dipusatkan di use case.
- UI mengirim nilai mentah controller; failure ditampilkan sebagai SnackBar
  melalui alur yang sudah ada.

Cara uji:
1. Tambah catatan dengan judul kosong → SnackBar "Judul catatan tidak
   boleh kosong" muncul, catatan tidak tersimpan.
2. flutter test test/validate_note_test.dart → 5 test hijau.
3. flutter analyze → bersih; dart format --set-exit-if-changed . → exit 0.

Ukuran: 179 baris perubahan, 3 commit konvensional (< 300 baris, < 3 hari).

Closes #1
```

Commit pada branch `feat/notes-validation`:

```text
b7fc97a fix(notes): normalisasi body di use case + test failure repository
0b3a3b9 feat(notes): validasi judul kosong + test
7b51802 style: rapikan dart format pada project week 7
```

## 3. Hasil review (reviewer: AI, checklist codelab)

Keputusan awal: **Request changes** — 2 item wajib, 3 item saran.

### Temuan kebenaran (2)

**K1 — Normalisasi input tersebar di dua layer** *(wajib)*
> Observasi: `title` di-trim di use case `AddNote`, tetapi `body` masih di-trim
> di `notes_page.dart` (`bodyController.text.trim()`).
> Dampak: dua aturan yang sama tersebar di dua layer; pemanggil `AddNote` lain
> di masa depan (mis. quick-add) tidak mendapat normalisasi body.
> Usulan konkret: pindahkan `body.trim()` ke use case; UI mengirim nilai mentah.

**K2 — Umpan balik error berisiko tertutup dialog** *(saran)*
> Observasi: saat validasi gagal, dialog tetap terbuka dan SnackBar dirender
> pada Scaffold di balik route dialog.
> Dampak: pada sebagian konfigurasi tema, pesan bisa kurang terlihat.
> Usulan konkret: idealnya error tampil sebagai `errorText` pada field Judul.
> Catatan author: diverifikasi manual — SnackBar tetap terlihat di bagian
> bawah layar di atas barrier dialog; perbaikan `errorText` membutuhkan
> `StatefulBuilder` dan di luar cakupan PR kecil ini. **Ditunda** (dicatat
> sebagai kandidat issue lanjutan), bukan diabaikan tanpa alasan.

### Temuan arsitektur (1)

**A1 — Aturan bisnis (trim) bocor ke presentation** *(wajib, akar masalah sama dengan K1)*
> Observasi: `notes_page.dart` masih menjalankan `.trim()` — normalisasi input
> adalah aturan bisnis, seharusnya steril dari widget.
> Dampak: presentation tidak lagi "hanya ref.watch + render"; dependency rule
> tidak dilanggar, tetapi sterilitas presentation menurun.
> Usulan konkret: hapus semua `.trim()` dari halaman; pusatkan di `AddNote`.

### Temuan test (1)

**T1 — Jalur failure repository belum ter-cover** *(wajib)*
> Observasi: test baru meng-cover judul kosong/spasi/valid, tetapi tidak ada
> kasus ketika repository mengembalikan failure (mis. `LocalFailure`).
> Dampak: regresi pada jalur error (failure tertelan/dilempar) tidak terdeteksi.
> Usulan konkret: tambah spy dengan flag `fail` dan assert failure diteruskan.

### Temuan keterbacaan (1)

**R1 — Duplikasi fake repository antar file test** *(saran)*
> Observasi: `FakeNoteRepository` (note_test.dart) dan `SpyNoteRepository`
> (validate_note_test.dart) mengimplementasikan kontrak yang sama.
> Dampak: perubahan kontrak `NoteRepository` harus diubah di dua tempat.
> Usulan konkret: ekstrak ke `test/helpers/` — **ditunda** hingga fake ketiga
> muncul, demi menjaga PR tetap < 300 baris.

## 4. Tindak lanjut dan merge

| Item | Status | Bukti |
| --- | --- | --- |
| K1/A1: trim dipusatkan di use case | ✅ Diperbaiki | commit `b7fc97a`; `notes_page.dart` bebas `.trim()` |
| T1: test failure repository | ✅ Diperbaiki | commit `b7fc97a`; test "failure dari repository diteruskan tanpa dilempar" hijau |
| K2: errorText di dialog | ⏸️ Ditunda beralasan | SnackBar terverifikasi terlihat; butuh StatefulBuilder, di luar cakupan PR |
| R1: ekstrak fake bersama | ⏸️ Ditunda beralasan | Menjaga PR < 300 baris; diekstrak saat fake ketiga muncul |

**Re-review:** approve — semua item wajib selesai, `flutter analyze` bersih,
`flutter test` 13/13 hijau.

**Merge:** squash ke `develop` (commit perantara `style`+`feat`+`fix`
digabung agar histori bersih), issue #1 tertutup via `Closes #1`, branch
`feat/notes-validation` dihapus.

```text
2c8e2e7 feat(notes): validasi judul kosong + test (#1)   <- squash merge di develop
```
