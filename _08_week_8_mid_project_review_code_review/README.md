# Week 8 — Mid Project Review & Code Review

Melanjutkan repository portfolio (project **Week 7 Clean Architecture** —
offline notes di `../_07_week_7_clean_architecture/`), **bukan project baru**.
Minggu ini membuktikan disiplin kolaborasi: Git Flow, commit konvensional,
PR kecil, code review terstruktur, mesin hijau, dan verifikasi saran AI.

## Status paruh semester

**SIAP dilanjutkan ke paruh kedua.** Aplikasi berjalan identik dengan akhir
Minggu 7, tiga pemeriksaan mesin hijau, satu PR kecil sudah di-merge via
review, dan fondasi Clean Architecture terbukti lewat tiga grep sterilitas
(NOL semua). Yang dinilai bukan banyaknya fitur, melainkan fondasi yang bisa
dipercaya — checklist lengkap: [`docs/review-checklist.md`](docs/review-checklist.md).

## Peta issue/PR

| Item | Status | Keterangan |
| --- | --- | --- |
| Issue #1 — catatan tanpa judul tersimpan tanpa umpan balik | ✅ Tertutup | Ditutup otomatis oleh PR #1 (`Closes #1`) |
| PR #1 — `feat(notes): validasi judul kosong + test` | ✅ Merged (squash) | `feat/notes-validation` → `develop`, 179 baris, review: request changes → perbaikan → approve |
| Issue #2 — konsistenkan kontrak error notifier | 📋 Terbuka | Lanjutan dari review AI (F1), sengaja tidak dicampur ke PR #1 agar tetap kecil |

> Alur issue/PR disimulasikan lokal dan terdokumentasi penuh di
> [`docs/praktikum2-pr-review.md`](docs/praktikum2-pr-review.md) karena
> repository belum memiliki akses push/GitHub CLI. Disiplin alurnya sama:
> issue → branch `feature/*` dari `develop` → commit konvensional → PR →
> review checklist → squash merge → branch dihapus.

## Peta branch

```text
main      -> rilis stabil (histori Week 1-7), tidak disentuh langsung
develop   -> integrasi mingguan; PR #1 masuk di sini
```

## Fitur utama (hasil Week 8)

1. **Validasi judul catatan** — judul kosong/hanya spasi ditolak di use case
   `AddNote` dengan `ValidationFailure` berpesan ramah pengguna; normalisasi
   (trim) judul & body dipusatkan di domain, UI mengirim nilai mentah.
2. **Disiplin Git Flow** — `develop` dibuat, fitur dikerjakan di
   `feat/notes-validation`, commit konvensional, squash merge, branch dihapus.
3. **CI penjaga kualitas** — `.github/workflows/ci.yml` menolak PR kotor:
   `flutter analyze` + `dart format --set-exit-if-changed` + `flutter test`.

## Stack teknologi

| Komponen | Paket/Alat |
| --- | --- |
| State management / DI | `flutter_riverpod` |
| Navigasi | `go_router` |
| Database lokal | `sqflite` |
| Preferensi | `shared_preferences` |
| Kualitas kode | `flutter analyze`, `dart format`, GitHub Actions |

## Cara menjalankan

```bash
cd _07_week_7_clean_architecture
flutter pub get
flutter analyze
flutter test        # 13 test
flutter run
```

## Bukti mesin hijau

| Perintah | Hasil |
| --- | --- |
| `flutter analyze` | 0 error, 0 warning (sisa 1 info `package_names` bawaan penamaan folder repo, terdokumentasi sejak Week 7) |
| `dart format --set-exit-if-changed .` | exit 0 — tidak ada yang perlu diformat |
| `flutter test` | **13/13 lulus** (8 lama + 5 baru dari PR #1) |
| 3 grep sterilitas | **NOL** semua (presentation steril, domain steril, tanpa DI bocor) |

Output terminal nyata: [`screenshots/`](screenshots/README.md).

## Laporan Praktikum 1 — Git Flow & commit berkualitas

Audit penuh: [`docs/praktikum1-git-audit.md`](docs/praktikum1-git-audit.md). Ringkasan:

- **Temuan audit**: semua commit historis langsung ke `main` (tanpa
  `develop`/`feature/*`), 5+ pesan commit non-konvensional (`tugas & laporan
  akhir`, `ai-challenge`, `praktikum 1 & 2`, ...), satu commit raksasa
  menggabung banyak perubahan logis.
- **Tindak lanjut**: `develop` dibuat dari `main`; fitur validasi dikerjakan
  di `feat/notes-validation` dengan 3 commit konvensional
  (`style:` → `feat(notes):` → `fix(notes):`).
- **Tabel perbaikan 3 pesan commit lama** → format konvensional + alasan:
  [`docs/review-checklist.md`](docs/review-checklist.md) bagian A.

## Laporan Praktikum 2 — Pull Request & code review

Dokumentasi lengkap: [`docs/praktikum2-pr-review.md`](docs/praktikum2-pr-review.md). Ringkasan:

- **Issue #1** ditulis dengan langkah reproduksi; **PR #1** memakai template
  lengkap (masalah → solusi → cara uji → ukuran), 179 baris (< 300), 3 commit.
- **Review** menghasilkan 2 temuan kebenaran, 1 arsitektur, 1 test, 1
  keterbacaan — pola observasi → dampak → usulan konkret. Keputusan awal:
  **request changes** (2 item wajib).
- **Tindak lanjut**: kedua item wajib diperbaiki (trim dipusatkan di use case,
  test failure repository ditambah), re-review **approve**, squash merge ke
  `develop`, issue tertutup, branch dihapus.

## Laporan Praktikum 3 — Static analysis & CI

Checklist lengkap: [`docs/review-checklist.md`](docs/review-checklist.md) bagian B–D. Ringkasan:

- Tiga perintah mesin hijau (tabel di atas); satu info nyata
  (`curly_braces_in_flow_control_structures`) diperbaiki dalam PR #1.
- `.github/workflows/ci.yml` aktif di root repo — PR kotor ditolak mesin
  sebelum dibaca manusia.
- Penilaian kesiapan paruh semester: semua kriteria ✅.

## AI Challenge

Proses lengkap (prompt, output mentah, verifikasi, bukti):
[`docs/ai-review-vs-keputusan.md`](docs/ai-review-vs-keputusan.md). Ringkasan:

- AI reviewer diminta menilai PR #1 sebagai senior Flutter dev → 5 temuan.
- **2 temuan terbukti benar dengan bukti grep** (kontrak error notifier tak
  konsisten; duplikasi fake repository) → diterima sebagai issue lanjutan /
  ditunda beralasan, tidak dicampur ke PR kecil.
- **3 temuan ditolak dengan alasan tertulis**: tuduhan memory leak controller
  yang tidak terbukti (`dispose()` selalu berjalan setelah `await showDialog`),
  nitpick style (ranah formatter), dan usulan memindah `ValidationFailure`
  yang justru memecah `sealed class` di layer `core`.
- Prinsip yang dipakai: review AI diverifikasi dulu (grep/test/reproduksi),
  tidak pernah diterima mentah.

## Refleksi

**1. Apa beda LGTM buta dengan approve yang bertanggung jawab? Apa risikonya bagi tim?**

LGTM buta = approve tanpa menarik branch, menjalankan test, atau membaca diff
dengan checklist. Approve bertanggung jawab berarti reviewer ikut memiliki
konsekuensi kode: ia checkout, menjalankan mesin, dan menguji manual. Risiko
LGTM buta bagi tim: bug lolos ke `develop`, kepercayaan antar-anggota turun,
dan review kehilangan fungsi sebagai gerbang kualitas — tinggal menunggu
insiden produksi untuk membuktikannya.

**2. Kapan komentar wajib berstatus request changes, dan kapan cukup saran?**

Request changes bila temuan menyangkut **kebenaran atau kontrak** (bug,
jalur error tak ter-cover, aturan bisnis bocor layer) — kode tidak boleh
masuk sebelum diperbaiki. Cukup saran bila soal preferensi, keterbacaan
minor, atau perbaikan yang lebih mahal dari manfaatnya pada PR kecil —
dicatat dan diputuskan author dengan alasan.

**3. Bagian mana dari review AI yang Anda tolak atau sederhanakan, dan mengapa?**

Detail di [`docs/ai-review-vs-keputusan.md`](docs/ai-review-vs-keputusan.md):
tuduhan memory leak yang tidak terbukti (dibantah dengan membaca alur
`await showDialog` → `dispose()`), nitpick style (sudah ranah CI), dan
pemindahan `ValidationFailure` yang memecah `sealed class`. Dua temuan benar
juga **disederhanakan cakupannya**: diterima sebagai issue lanjutan, bukan
dicampur ke PR 179 baris — menjaga PR tetap reviewable lebih penting daripada
"sekalian membereskan semuanya".

**4. Satu hal konkret yang Anda perbaiki setelah review sejawat — apa dampaknya?**

Memindahkan `.trim()` body dari `notes_page.dart` ke use case `AddNote`.
Dampaknya: presentation kembali steril dari aturan bisnis, semua pemanggil
`AddNote` di masa depan otomatis mendapat normalisasi yang sama, dan ada test
("body ikut dinormalisasi di use case") yang mengunci perilaku itu.

## Struktur folder

```text
08-week-8-mid-project-review-code-review/  (folder ini)
├── README.md                      # laporan utama (file ini)
├── docs/
│   ├── praktikum1-git-audit.md    # audit git + temuan
│   ├── praktikum2-pr-review.md    # issue #1, PR #1, review, tindak lanjut
│   ├── review-checklist.md        # perbaikan commit, mesin, CI, kesiapan mid
│   └── ai-review-vs-keputusan.md  # prompt, output AI, verifikasi, keputusan
└── screenshots/                   # output terminal nyata + placeholder UI
```
