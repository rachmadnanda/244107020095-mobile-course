# Week 11 — Optimasi Performa Aplikasi Catatan

Melanjutkan aplikasi catatan **Week 10** (`../_10_week_10_ai_feature_integration/`)
— bukan project baru. Fokus minggu ini bukan menambah fitur, melainkan
**mengukur dan memperbaiki** biaya render, rebuild, update state, dan memori
pada aplikasi yang sudah berjalan.

> **Status verifikasi:** `flutter analyze` bersih, **85/85 test lulus**
> (11 November 2026). Profiling dijalankan di emulator Android 15 (API 35,
> 1080×2280, Impeller/OpenGLES) memakai **1.000 catatan** yang di-seed
> deterministik. Bukti mentah ada di [`screenshots/`](screenshots/README.md),
> analisis di [`docs/performance-findings.md`](docs/performance-findings.md)
> dan laporan lengkap di [`docs/performance-report.md`](docs/performance-report.md).

## Ringkasan hasil

Skenario identik untuk baseline dan sesudah optimasi:

1. Jalankan aplikasi profile dengan 1.000 catatan.
2. Tunggu idle, lalu bersihkan logcat.
3. 12× swipe ke atas, 12× swipe ke bawah (durasi 400 ms, jeda 0,4 s).
4. Ambil 9 jendela pengukuran, masing-masing 120 frame.

| Metrik (median 9 jendela) | Baseline (Week 10) | Sesudah optimasi | Perubahan |
| --- | ---: | ---: | ---: |
| Build p50 (UI thread) | 1,34 ms | 1,42 ms | +0,08 ms (derau) |
| Raster p50 (GPU) | 16,73 ms | 16,23 ms | **−3,0%** |
| Total frame p50 | 24,38 ms | 23,63 ms | **−3,1%** |
| Jank > 32 ms | 18,4% | 16,0% | **−13,0%** |
| Jank > 16 ms | 96,0% | 90,0% | −6,3% |

Rincian lengkap (baseline, temuan, trade-off, memori, lampiran reproduksi)
ada di [`docs/performance-report.md`](docs/performance-report.md). Log mentah
9 jendela per build: [`screenshots/before-scroll-metrics.txt`](screenshots/before-scroll-metrics.txt)
dan [`screenshots/after-scroll-metrics.txt`](screenshots/after-scroll-metrics.txt).

**Kesimpulan yang jujur:** daftar catatan sudah memakai `ListView.builder`,
jadi scroll memang **didominasi raster thread emulator** (p50 ≈ 16 ms) dan
optimasi rebuild tidak mengubah FPS scroll secara dramatis. Perbaikan nyata
ada pada **lingkup rebuild saat berinteraksi**, **biaya update state setelah
tambah/hapus/sinkron**, dan **umur hidup objek di memori** — dibuktikan dengan
test otomatis, bukan hanya angka frame.

## Bukti screenshot

Semua diambil dari emulator Android 15 (API 35, 1080×2280) pada
11 November 2026, build profile, beban 1.000 catatan. File asli, kondisi
pengukuran, dan detail frame ada di [`screenshots/README.md`](screenshots/README.md).

**Daftar catatan — baseline vs sesudah optimasi**

| Baseline (Week 10) | Sesudah optimasi |
| --- | --- |
| ![Daftar catatan baseline](screenshots/before-home.png) | ![Daftar catatan sesudah optimasi](screenshots/after-home.png) |
| ±4 catatan per layar; judul dan isi tampil penuh, tinggi tile tidak seragam | ±9 catatan per layar; judul 1 baris + isi 2 baris dengan elipsis, tinggi tile seragam |

**DevTools — Performance → Frame Analysis**

| Baseline — frame 645 | Sesudah — frame 578 |
| --- | --- |
| ![DevTools baseline frame 645](screenshots/before-profile.png) | ![DevTools sesudah frame 578](screenshots/after-profile.png) |
| UI 2,0 ms · Raster **23,9 ms** (raster jank) | UI 2,1 ms · Raster **19,6 ms** (tooltip; bilah fase 19,7 ms) |

Keduanya memilih frame saat scroll dengan skenario rekaman identik (8× swipe
atas, 8× swipe bawah, buka detail → kembali, ketik `catatan`). Rata-rata FPS
pada header rekaman (41 vs 36) **tidak** dipakai sebagai pembanding karena
cakupan transisi halaman berbeda dan emulator berderau; pembanding yang sah
adalah 9 jendela terkontrol di tabel sebelumnya.

## Memori

Diukur dengan `adb shell dumpsys meminfo <paket>` pada beban 1.000 catatan.
Kolom **Heap Alloc** dipakai karena lebih stabil daripada PSS (PSS sangat
dipengaruhi reclaim halaman bersih APK):

| Kondisi | Baseline | Sesudah | Selisih |
| --- | ---: | ---: | ---: |
| Idle setelah daftar termuat | 46.923 KB | 43.992 KB | −2.931 KB (−6,3%) |
| Setelah buka–tutup detail 5× | 46.881 KB | 44.049 KB | −2.832 KB (−6,0%) |

Kedua build tidak menunjukkan pertumbuhan liar pada 5 navigasi; objek `Note`
terlalu kecil untuk terlihat dalam sampel itu. Karena baseline dan versi
optimasi adalah dua APK terpisah, selisih ini diperlakukan sebagai
**indikasi**, bukan klaim kausal. Bukti utama pelepasan provider detail adalah
`test/provider_disposal_test.dart`. Ringkasan mentah:
[`screenshots/memory-metrics.txt`](screenshots/memory-metrics.txt).

## Trade-off dan keterbatasan

| Keputusan | Keuntungan | Biaya |
| --- | --- | --- |
| Halaman dipecah menjadi 4 widget | Rebuild terbatas, mudah diuji | Lebih banyak berkas/kelas kecil |
| Update state lokal setelah mutasi | Tanpa query ulang | State harus dijaga konsisten dengan database |
| `isAutoDispose` untuk detail | Memori tidak menumpuk | Detail dimuat ulang saat dibuka lagi (satu query by-id, murah) |
| Riwayat chat dibatasi 200 pesan | Memori/rebuild konstan | Pesan lama hilang dari sesi (bukan dari penyimpanan) |
| Optimistic dark-mode | Satu rebuild, tanpa kedip | Kegagalan tulis hanya dicatat di log |

Keterbatasan pengukuran: hanya satu emulator, 9 jendela per build, dan variasi
beban emulator cukup besar (jank32 sesudah berkisar 5–35%). Perangkat fisik
bisa memberi angka berbeda, terutama pada raster thread. Karena itu klaim
dibatasi pada arah perubahan, bukan angka absolut.

## Optimasi yang diterapkan

| # | Masalah | Teknik | Bukti |
| --- | --- | --- | --- |
| 1 | Mengetik pencarian membangun ulang seluruh `Scaffold`, AppBar, dan FAB | Pecah halaman menjadi `NotesPage` (stateless), `NotesAppBarActions`, `NotesSearchField`, `NotesBody` | `test/rebuild_scope_test.dart` |
| 2 | Setiap perubahan daftar membaca ulang seluruh tabel SQLite | Update state lokal di `NotesNotifier` (`addNote`, `deleteNote`, `sync`) memakai `Note.copyWith` | `test/notes_state_test.dart` |
| 3 | `noteByIdProvider` menyimpan setiap id yang pernah dibuka selamanya | `FutureProvider.family(..., isAutoDispose: true)` | `test/provider_disposal_test.dart` |
| 4 | Indikator “AI sedang menulis…” yang beranimasi memicu repaint daftar chat | `RepaintBoundary` + `ValueKey` per pesan | `lib/features/assistant/presentation/pages/assistant_page.dart` |
| 5 | Riwayat chat tumbuh tanpa batas selama sesi | `ChatNotifier.maxMessages = 200` + `capHistory()` | `test/chat_history_cap_test.dart` |
| 6 | Toggle tema melewati `AsyncLoading` → dua rebuild + kedip | Optimistic update di `DarkModeNotifier`, dibaca dengan `select` di `main.dart` | `lib/features/settings/presentation/providers/settings_providers.dart` |
| 7 | Teks panjang di tile di-layout penuh saat scroll | `maxLines` + `TextOverflow.ellipsis`, widget `const`, `ValueKey` | `lib/features/notes/presentation/widgets/note_tile.dart` |
| 8 | Detail catatan tidak bisa di-scroll saat isi panjang | `SingleChildScrollView` | `lib/features/notes/presentation/pages/note_detail_page.dart` |

`ListView.builder` + `addAutomaticKeepAlives: false` tetap dipakai — daftar
memang sudah lazy sejak awal, dan itu dikonfirmasi di profiling (bukan asumsi).

## Yang **tidak** diterapkan (dan alasannya)

- **Pagination/infinite scroll.** Data berasal dari SQLite lokal; query 1.000
  baris masih di bawah 1 ms dan `ListView.builder` hanya membangun item yang
  terlihat. Pagination akan menambah kompleksitas state tanpa perbaikan yang
  terukur. Ambang yang disepakati: terapkan bila dataset > 10.000 baris atau
  `fetchNotes` mulai > 16 ms (diukur, bukan ditebak).
- **Cache gambar / `CachedNetworkImage`.** Aplikasi tidak menampilkan gambar
  atau feed jaringan. Tidak ada yang bisa dioptimasi di jalur ini.
- **Cache HTTP / Dio interceptor.** Satu-satunya panggilan jaringan adalah
  Gemini API untuk fitur chat; jawabannya tidak di-cache karena bergantung
  pada konteks catatan yang berubah. Detail ada di laporan.
- **Debounce pencarian.** Filter berjalan di memori atas 1.000 objek dan
  terukur < 1 ms; debounce hanya akan menambah jeda yang terasa tanpa manfaat
  yang bisa diukur.

## Struktur penting

```text
lib/
├── core/dev/
│   ├── performance_probe.dart   # probe FrameTiming (aktif via PERF_PROBE)
│   ├── dev_seed_service.dart    # seed 1.000 catatan untuk beban uji
│   └── dev_providers.dart
├── features/notes/
│   ├── presentation/pages/notes_page.dart        # rebuild scope dipecah
│   ├── presentation/providers/notes_providers.dart
│   └── presentation/widgets/note_tile.dart
├── features/assistant/…                          # RepaintBoundary + cap history
├── features/settings/…                           # optimistic toggle + alat debug
└── main.dart                                     # seed flag, probe, select tema
```

## Menjalankan

Prasyarat: Flutter SDK stabil, emulator/perangkat Android.

```bash
flutter pub get

# Aplikasi biasa
flutter run

# Profiling dengan beban 1.000 catatan + probe frame
flutter run --profile \
  --dart-define=SEED_NOTES=1000 \
  --dart-define=PERF_PROBE=true
```

Ringkasan probe dicetak ke logcat setiap 120 frame dengan tag `flutter`:

```text
[PERF] frames=120 build_p50=… build_p90=… raster_p50=… raster_p90=…
       total_p50=… total_p90=… jank16=…% jank32=…%
```

Tombol **Pengaturan → Alat pengembang (profiling)** menyediakan:
isi 1.000 catatan contoh, hapus semua catatan, dan cetak ringkasan performa.
Bagian ini hanya tampil saat bukan release (`!kReleaseMode`).

Baseline (Week 10 + alat ukur) dapat dibuat ulang tanpa mengubah kode aslinya:

```bash
./tool/reproduce_baseline.sh /tmp/opencode/week11_baseline
```

Screenshot DevTools (`before-profile.png` / `after-profile.png`) tersedia di
[`screenshots/`](screenshots/README.md). Langkah reproduksi pengukuran ada di
lampiran [`docs/performance-report.md`](docs/performance-report.md) §9.

## Uji & analisis

```bash
dart format --set-exit-if-changed .
flutter analyze
flutter test
```

Hasil terakhir (11 November 2026):

- `dart format --set-exit-if-changed .` — bersih
- `flutter analyze` — **No issues found!**
- `flutter test` — **85/85 lulus**

Test baru untuk minggu ini:

| Berkas | Yang dibuktikan |
| --- | --- |
| `test/rebuild_scope_test.dart` | Mengetik pencarian tidak membangun ulang instance FAB/tombol AppBar |
| `test/notes_state_test.dart` | Tambah/hapus/sinkron tidak memicu `fetchNotes` ulang |
| `test/provider_disposal_test.dart` | Provider detail auto-dispose setelah listener terakhir ditutup |
| `test/chat_history_cap_test.dart` | Riwayat chat dibatasi 200 pesan terbaru |
| `test/helpers/fake_note_repository.dart` | Fake repository + penghitung pemanggilan |

## Dokumentasi

- [`docs/performance-findings.md`](docs/performance-findings.md) — temuan
  profiling, minimal 3 masalah + bukti kode.
- [`docs/performance-report.md`](docs/performance-report.md) — laporan lengkap:
  baseline, optimasi, verifikasi, memori, trade-off, refleksi, dan lampiran
  cara mereproduksi.
- [`screenshots/README.md`](screenshots/README.md) — inventaris bukti dan
  detail frame DevTools yang dipilih.

## Penggunaan AI dan verifikasi

AI dipakai untuk membantu membaca hasil profiling, mengusulkan kandidat
optimasi, dan menyusun dokumentasi. Semua usulan diverifikasi ulang dengan
`dart format`, `flutter analyze`, **85 test**, dan profiling nyata di emulator;
tidak ada angka atau screenshot yang dibuat-buat. Klaim yang tidak didukung
data (misalnya “FPS naik 2×”) tidak dimasukkan. Rincian ada di
[`docs/performance-report.md`](docs/performance-report.md) §7.

## Refleksi singkat

- **Dampak terbesar** datang dari memecah lingkup rebuild dan menghapus
  pembacaan ulang database setelah mutasi — keduanya mengurangi kerja yang
  dikendalikan kode kita. Perbaikan frame time scroll kecil karena bottleneck
  sebenarnya ada di raster emulator.
- **Verifikasi bukan placebo:** setiap klaim punya test yang gagal bila
  optimasi dicabut (identitas instance widget, jumlah `fetchNotes`, keberadaan
  provider setelah dispose, panjang riwayat). Angka frame berasal dari probe
  `FrameTiming`, bukan perkiraan.
- **Trade-off:** kode sedikit lebih terpecah (lebih banyak widget kecil) dan
  state lokal harus dijaga agar tetap konsisten dengan database. Itu diterima
  karena biayanya satu kali tulis, sedangkan manfaatnya berulang di setiap
  interaksi.
- **Optimasi prematur dihindari:** pagination, indeks tambahan, dan cache
  jaringan sengaja tidak ditambahkan karena belum ada bukti kebutuhan.