# Bukti — Week 11

Semua bukti berasal dari aplikasi yang dijalankan di emulator Android 15
(API 35, 1080×2280), mode `--profile`, beban **1.000 catatan** yang di-seed
lewat `--dart-define=SEED_NOTES=1000`.

## Daftar berkas

| Berkas | Isi |
| --- | --- |
| `before-home.png` | Baseline (Week 10) setelah seed 1.000 catatan |
| `after-home.png` | Versi optimasi setelah seed 1.000 catatan |
| `before-profile.png` | DevTools **Performance → Frame Analysis**, baseline |
| `after-profile.png` | DevTools **Performance → Frame Analysis**, versi optimasi |
| `before-scroll-metrics.txt` | 9 jendela `[PERF]` baseline (logcat mentah) |
| `after-scroll-metrics.txt` | 9 jendela `[PERF]` versi optimasi |
| `memory-metrics.txt` | Ringkasan `dumpsys meminfo` sebelum/sesudah |

## Kondisi pengukuran

- Perangkat: emulator `sdk_gphone64_x86_64`, Android 15 / API 35,
  1080×2280 @ 440 dpi, Impeller + OpenGLES.
- Build: profile (`flutter run --profile`).
- Data: 1.000 catatan dengan judul/isi seragam.
- Animasi sistem: skala 0 selama pengukuran.
- Skenario rekaman: 8× swipe ke atas + 8× ke bawah (350 ms, jeda 250 ms),
  buka detail → kembali, lalu ketik `catatan` di kolom pencarian.
- DevTools: versi 2.60.0, tab **Performance**, panel **Frame Analysis**.
- Probe: `lib/core/dev/performance_probe.dart` (`PERF_PROBE=true`).

## Detail screenshot DevTools

Keduanya memilih frame saat scroll, bukan frame transisi halaman, agar
setara:

| | Berkas | Frame | UI | Raster | Status |
| --- | --- | ---: | ---: | ---: | --- |
| Baseline | `before-profile.png` | 645 | 2,0 ms | 23,9 ms | Raster jank |
| Sesudah | `after-profile.png` | 578 | 2,1 ms | 19,6 ms | Raster jank |

Nilai raster sesudah diambil dari tooltip frame (19,6 ms); bilah fase di
bawahnya menampilkan 19,7 ms karena pembulatan. Keduanya frame yang sama.

Angka pada header DevTools (41 FPS vs 36 FPS) **bukan** metrik pembanding:
rekaman mencakup transisi halaman dengan durasi yang berbeda dan emulator
mengalami variasi beban. Perbandingan yang sah adalah 9 jendela terkontrol di
`before-scroll-metrics.txt` / `after-scroll-metrics.txt`, yang diringkas di
[`../docs/performance-report.md`](../docs/performance-report.md).

## Cara memverifikasi file metrik

```bash
grep '\[PERF\]' screenshots/before-scroll-metrics.txt
grep '\[PERF\]' screenshots/after-scroll-metrics.txt
```

Setiap baris berisi `frames`, `build_p50/p90`, `raster_p50/p90`,
`total_p50/p90`, `jank16`, dan `jank32`. Tidak ada nilai yang diubah setelah
pengambilan.

## Skenario ulang

Perintah lengkap ada di lampiran
[`../docs/performance-report.md`](../docs/performance-report.md) §9.
Baseline dibuat ulang tanpa mengubah kode Week 10:

```bash
./tool/reproduce_baseline.sh /tmp/opencode/week11_baseline
```

## Catatan tentang screenshot aplikasi

`before-home.png` dan `after-home.png` diambil dengan:

```bash
adb -s emulator-5554 exec-out screencap -p > screenshots/after-home.png
```

Keduanya menampilkan daftar hasil seed. Perbedaan yang terlihat (tinggi baris,
badge “Belum tersinkron”, elipsis, kepadatan ±4 vs ±9 catatan per layar)
adalah efek langsung dari optimasi `NoteTile`, bukan hasil edit gambar.