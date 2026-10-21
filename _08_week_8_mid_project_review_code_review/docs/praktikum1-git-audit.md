# Praktikum 1 — Audit Riwayat Git

Dijalankan di root repository portfolio pada branch `main`.

## Output perintah audit

### `git log --oneline -15`

```text
13d1eda docs: laporan praktikum 1-3, AI challenge, dan placeholder screenshots
e9bec7c refactor: clean architecture feature-first (notes + settings) with use-case tests
79c6591 chore: snapshot before clean architecture (copy of week5_offline_notes)
f42593b tugas & laporan akhir
1fe4188 ai-challenge
a30c9de praktikum 3
b88ba11 praktikum 1 & 2
c5885a7 fix laporan akhir readme
3dd49fa document complete week 5 practical report
826dc52 fix offline notes build and tests
5718c46 complete week 5 offline notes challenge
942121e refactor offline notes and add detail routing
cd80798 add week 5 storage comparison (ai-challenge)
e6b722d add week 5 praktikum 3 offline sync
a604fc0 add week 5 praktikum 2 sqlite repository
```

### `git branch -a`

```text
* main
  remotes/origin/HEAD -> origin/main
  remotes/origin/main
```

### `git status`

```text
On branch main
nothing to commit, working tree clean
```

## Temuan masalah

| # | Masalah | Bukti |
|---|---------|-------|
| 1 | **Semua commit langsung ke `main`** — tidak ada branch `develop` maupun `feature/*` | `git branch -a` hanya menampilkan `main` |
| 2 | **Pesan commit non-konvensional** — tidak memakai format `tipe(scope): deskripsi` | `tugas & laporan akhir`, `ai-challenge`, `praktikum 3`, `praktikum 1 & 2`, `fix laporan akhir readme` |
| 3 | **Satu commit menggabung banyak perubahan logis** | `e9bec7c refactor: clean architecture feature-first (notes + settings) with use-case tests` memuat refactor seluruh struktur + test sekaligus |
| 4 | File tak terlacak | **NOL** — `git status` bersih, tidak ada file yang seharusnya di-commit/di-ignore |

## Tindak lanjut

1. Buat branch `develop` dari `main` (sekali), jadikan target default semua PR.
2. Kerjakan fitur di branch `feat/notes-validation` dari `develop`.
3. Commit memakai format konvensional `tipe(scope): deskripsi` + `git add -p`.
4. Setelah selesai, `main` hanya disentuh via release (merge dari `develop`), tidak ada commit langsung lagi.
