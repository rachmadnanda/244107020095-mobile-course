# Bukti — Week 13

Dua jenis bukti, keduanya diambil 25 November 2026:

- **`gh-*.png`** — tangkapan layar halaman publik GitHub Actions (Chrome
  headless, tanpa login). Yang terlihat adalah halaman run apa adanya.
- **`01-cek-lokal.png`** — tangkapan layar jendela terminal sungguhan (`foot`
  di sesi Wayland, diambil dengan `grim`) yang menjalankan perintah yang sama
  dengan CI memakai **Flutter 3.50.1**.

## Daftar berkas

| Berkas | Isi |
| --- | --- |
| `gh-01-runs.png` | Daftar run: #5, #4, #3, #2 hijau; #1 merah; ci #1 lama merah |
| `gh-02-run-summary.png` | Ringkasan run #2: status Success, 7m 14s, artefak 72,6 MB |
| `gh-03-run-steps.png` | 10 step run #2, semuanya hijau |
| `gh-04-first-failure.png` | Run #1: step "Analisis statis" merah, step build `skipped` |
| `gh-05-run-docs.png` | Run #3 (commit dokumentasi): Success, 5m 12s, artefak 72,6 MB |
| `gh-06-run-4.png` | Run #4 (commit dokumentasi berikutnya): Success, 6m 0s, artefak 72,6 MB |
| `gh-07-run-5.png` | Run #5 (commit dokumentasi terakhir): Success, 4m 29s, artefak 72,6 MB |
| `01-cek-lokal.png` | Format, analyze, dan 95 test lokal dengan Flutter 3.50.1 |
| `02-build-lokal.png` | Build lokal APK (52,1 MB) dan AAB (51,8 MB) dengan Flutter 3.50.1 |

## Fakta yang dibuktikan tiap gambar

| Gambar | Yang terbaca |
| --- | --- |
| `gh-01-runs.png` | `Flutter CI #5` commit `55716ec`, 4m 29s · `#4` `12769ee`, 6m 0s · `#3` `2cec604`, 5m 12s · `#2` `a716bb4`, 7m 14s · `#1` `79284c6`, 1m 9s |
| `gh-02-run-summary.png` | Status **Success**, total 7m 14s, Artifacts **1**, `android-builds` **72.6 MB**, digest `sha256:f0329404…` |
| `gh-03-run-steps.png` | Set up job → Checkout → Siapkan Flutter → Ambil dependensi → Periksa format → Analisis statis → Jalankan test → Build APK → Build App Bundle → Unggah artefak → Complete job, semua ✅ |
| `gh-04-first-failure.png` | Periksa format ✅ lalu **Analisis statis ❌**, Jalankan test sampai Unggah artefak `skipped` |
| `gh-05-run-docs.png` | Status **Success**, total 5m 12s, Artifacts **1**, `android-builds` **72.6 MB**, digest `sha256:39e6c8ad…` |
| `gh-06-run-4.png` | Status **Success**, total 6m 0s, Artifacts **1**, `android-builds` **72.6 MB**, digest `sha256:1732051e…` |
| `gh-07-run-5.png` | Status **Success**, total 4m 29s, Artifacts **1** |
| `01-cek-lokal.png` | `Formatted 52 files (0 changed)`, `No issues found!`, `00:17 +95: All tests passed!` |
| `02-build-lokal.png` | `✓ Built ... app-release.apk (52.1MB)`, `✓ Built ... app-release.aab (51.8MB)`, `Flutter 3.50.1 • channel stable` |

## Yang tidak bisa dibuktikan dari gambar

- **Isi log tiap step** hanya bisa dibaca setelah login GitHub. Karena itu
  penyebab kegagalan run #1 direproduksi lokal dengan Flutter 3.50.1 — hasilnya
  didokumentasikan di
  [`../docs/ci-cd-report.md`](../docs/ci-cd-report.md) bagian 5.
- **Isi artefak** (APK/AAB) tidak diunduh; yang terbukti adalah keberadaan dan
  ukurannya. Unduhan juga butuh login.
- **Masa berlaku artefak 7 hari**, jadi gambar ini adalah arsip tetapnya.

## Catatan kejujuran

Semua angka di tabel diambil dari gambar di folder ini, bukan dari ingatan atau
perkiraan. Durasi 7m 14s adalah durasi total run #2; job `test-and-build`
sendiri 7m 10s, seperti terlihat di `gh-02-run-summary.png`.

## Cara memverifikasi ulang

```bash
# Lokal, dengan Flutter 3.50.1 (versi yang dipakai CI)
cd _13_week_13_ci_cd_automation
dart format --output=none --set-exit-if-changed .
flutter analyze --fatal-infos
flutter test
```

Pipeline di GitHub:

- Semua run: <https://github.com/rachmadnanda/244107020095-mobile-course/actions>
- Run #2 (hijau): <https://github.com/rachmadnanda/244107020095-mobile-course/actions/runs/45553405020>
- Run #1 (gagal): <https://github.com/rachmadnanda/244107020095-mobile-course/actions/runs/45547458858>
