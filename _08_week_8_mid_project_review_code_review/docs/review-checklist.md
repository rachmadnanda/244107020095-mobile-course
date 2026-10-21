# Review Checklist — Week 8

## Bagian A: Perbaikan pesan commit (Praktikum 1.3)

Tiga pesan commit lama ditulis ulang ke format konvensional
`tipe(scope): deskripsi singkat` beserta alasannya.

| Sebelum (pesan lama) | Sesudah (format konvensional) | Alasan |
| --- | --- | --- |
| `tugas & laporan akhir` | `docs(week6): laporan tugas auth/FCM + refleksi akhir` | Tipe `docs` jelas (bukan kode), scope `week6` menunjukkan lokasi, deskripsi menyebut apa yang ditulis — bisa di-revert tanpa menebak isi commit. |
| `fix laporan akhir readme` | `docs(week6): perbaiki tautan screenshot di README laporan` | "fix" tanpa scope memaksa reviewer membuka diff; versi baru langsung menjawab *apa* (tautan screenshot), *di mana* (README week 6), dan *jenisnya* (dokumentasi). |
| `praktikum 1 & 2` | `feat(week6): praktikum 1-2 — integrasi Firebase Auth + FCM token` | Pesan lama hanya menyalin nomor tugas tanpa menyebut perubahan; versi baru menyebut fitur yang ditambahkan sehingga `git log` bisa dibaca sebagai changelog. |

## Bagian B: Mesin hijau (Praktikum 3.1)

Tiga perintah dijalankan di `_07_week_7_clean_architecture/` setelah PR #1
digabung ke `develop`:

| Perintah | Hasil |
| --- | --- |
| `flutter analyze` | **0 error, 0 warning.** Sisa 1 info `package_names` di `pubspec.yaml` — bawaan konvensi penamaan folder repo kampus (berawalan digit), sudah terdokumentasi sejak Week 7 dan bukan masalah kode. |
| `dart format --set-exit-if-changed .` | **Bersih** — exit code 0, tidak ada file yang perlu diformat ulang. |
| `flutter test` | **13 test lulus** (8 lama + 5 baru dari PR #1). |

Urutan perbaikan yang dipakai: error → warning → info. Satu info nyata
(`curly_braces_in_flow_control_structures` di `test/note_test.dart`) diperbaiki
dalam PR ini; info `package_names` sengaja dibiarkan dengan alasan di atas.

## Bagian C: CI (Praktikum 3.2)

`.github/workflows/ci.yml` dibuat di root repo: setiap pull request menjalankan
`flutter analyze`, `dart format --set-exit-if-changed`, dan `flutter test` di
folder project Week 7. PR kotor ditolak mesin sebelum dibaca manusia.

## Bagian D: Kesiapan paruh semester (Praktikum 3.3)

| Kriteria | Status | Bukti |
| --- | --- | --- |
| Struktur feature-first terbukti (3 grep sterilitas) | ✅ | Ketiga grep menghasilkan **NOL** (lihat output di bawah) |
| `flutter analyze` bersih | ✅ | 0 error / 0 warning |
| `flutter test` hijau | ✅ | 13/13 lulus |
| PR kecil + commit jelas | ✅ | PR #1: 179 baris, 3 commit konvensional, di-squash saat merge |
| README + screenshot + cara menjalankan | ✅ | `../README.md` + `../screenshots/` |
| Semua komentar review ditindaklanjuti | ✅ | 2 request-changes diperbaiki, re-review approve — [`praktikum2-pr-review.md`](praktikum2-pr-review.md) |

### Output tiga grep sterilitas (dijalankan ulang pada `develop` pasca-merge)

```text
=== GREP 1: presentation steril dari data mentah ===
NOL
=== GREP 2: domain steril dari framework/package ===
NOL
=== GREP 3: widget tidak instansiasi repository ===
NOL
```

## Definisi selesai (dari codelab)

- [x] Aplikasi berjalan identik dengan akhir Minggu 7 (perilaku sama; hanya
      tambah validasi judul kosong sesuai PR #1).
- [x] Tiga pemeriksaan mesin hijau.
- [x] Minimal 1 PR kecil di-merge via review (PR #1, squash, branch dihapus).
- [x] README memuat status paruh semester + peta issue/PR.
