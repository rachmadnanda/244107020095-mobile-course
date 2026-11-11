# Temuan Profiling — Week 11

Dokumen ini mencatat **apa yang diukur**, **apa yang ditemukan**, dan **bukti**
untuk setiap temuan. Angka berasal dari aplikasi yang benar-benar dijalankan
di emulator, bukan perkiraan.

- Tanggal: 11 November 2026
- Perangkat: emulator `sdk_gphone64_x86_64`, Android 15 (API 35),
  1080×2280, 440 dpi, backend Impeller/OpenGLES
- Build: `--profile`
- Beban uji: 1.000 catatan (di-seed lewat `--dart-define=SEED_NOTES=1000`)
- Baseline: project Week 10 di `/tmp/opencode/week11_baseline` — **kode
  aplikasi tidak diubah**, hanya ditambah alat ukur (`performance_probe.dart`,
  `dev_seed_service.dart`, flag seed) agar beban dan metodenya identik.
- Setelah: folder ini (`_11_week_11_performance_optimization`).

## Metode

### Probe frame

`lib/core/dev/performance_probe.dart` memasang
`SchedulerBinding.instance.addTimingsCallback` dan mengumpulkan `FrameTiming`
dari engine. Setiap 120 frame dicetak:

```text
[PERF] frames=120 build_p50=… build_p90=… raster_p50=… raster_p90=…
       total_p50=… total_p90=… jank16=…% jank32=…%
```

Probe hanya aktif bila dijalankan dengan `--dart-define=PERF_PROBE=true`
(flag compile-time), sehingga tidak membebani build release.

### Skenario

1. Aplikasi dijalankan profile dengan 1.000 catatan, tunggu sampai idle.
2. `adb logcat -c`.
3. 12× `input swipe` ke atas, lalu 12× ke bawah.
   Durasi swipe 400 ms, jeda 400 ms.
4. Ambil 9 jendela × 120 frame; hitung median setiap metrik.

Skenario ini sama persis untuk baseline dan sesudah optimasi. Log mentah:
[`../screenshots/before-scroll-metrics.txt`](../screenshots/before-scroll-metrics.txt)
dan [`../screenshots/after-scroll-metrics.txt`](../screenshots/after-scroll-metrics.txt).

### Batas pengukuran

- Emulator berjalan di atas CPU host dan memakai rasterizer software/GLES;
  **raster thread adalah bottleneck utama** (p50 ≈ 16 ms), sehingga FPS di
  emulator tidak mewakili perangkat flagship.
- Karena itu, kesimpulan tidak boleh hanya bersandar pada FPS. Temuan di bawah
  diverifikasi juga dengan test yang mengukur **kerja yang dikendalikan kode
  aplikasi** (jumlah rebuild, jumlah query, umur provider).

## Ringkasan angka

Median dari 9 jendela pengukuran:

| Metrik | Baseline | Sesudah | Selisih |
| --- | ---: | ---: | ---: |
| Build p50 | 1,34 ms | 1,42 ms | +0,08 ms |
| Build p90 (median) | 4,01 ms | 4,22 ms | +0,21 ms |
| Raster p50 | 16,73 ms | 16,23 ms | −0,50 ms (−3,0%) |
| Total p50 | 24,38 ms | 23,63 ms | −0,75 ms (−3,1%) |
| Jank > 16 ms | 96,0% | 90,0% | −6,0 poin |
| Jank > 32 ms | 18,4% | 16,0% | −2,4 poin |

Angka ini **tidak** menunjukkan lompatan besar, dan itu wajar: pekerjaan
scroll daftar sudah efisien sejak awal. Yang berubah adalah biaya interaksi
dan pembaruan state — diukur pada bagian berikut.

## Temuan

### Temuan 1 — Mengetik pencarian membangun ulang seluruh halaman

**Gejala.** Di baseline, `NotesPage` adalah `ConsumerStatefulWidget` yang
melakukan `ref.watch(searchQueryProvider)` di `build`. Setiap ketukan
menyebabkan `Scaffold`, `AppBar` (beserta 5 aksi), `FloatingActionButton`, dan
seluruh body dibangun ulang — padahal hanya teks daftar yang berubah.

**Bukti kode (baseline).** `build` halaman memanggil `ref.watch` untuk query,
daftar, status offline, dan status sinkron dalam satu method.

**Perbaikan.** `lib/features/notes/presentation/pages/notes_page.dart`
dipecah menjadi:

- `NotesPage` — `StatelessWidget`, tanpa `ref.watch`.
- `NotesAppBarActions` — hanya watch `forceOfflineProvider`.
- `NotesSearchField` — hanya watch `searchQueryProvider.select((q) => q.isEmpty)`.
- `NotesBody` — hanya watch daftar hasil filter.

**Bukti otomatis.** `test/rebuild_scope_test.dart` mengambil instance
`FloatingActionButton` dan `IconButton` sinkronisasi sebelum & sesudah
mengetik, lalu memastikan **instance-nya identik** (`identical(...)`). Bila
root ikut rebuild, instance baru akan terbentuk dan test gagal.

### Temuan 2 — Setiap mutasi membaca ulang seluruh tabel

**Gejala.** Di baseline, `addNote`, `deleteNote`, dan `sync` memanggil
`ref.invalidateSelf()` lalu `await future`, artinya seluruh daftar (1.000
baris) dibaca ulang dari SQLite, dipetakan ke entity, diurutkan, dan dikirim
ulang ke UI — untuk perubahan satu baris.

**Perbaikan.** `lib/features/notes/presentation/providers/notes_providers.dart`:

- `addNote` menyisipkan `Note` baru ke state dan mengurutkan ulang di memori.
- `deleteNote` membuang satu id dari state.
- `sync` hanya mengubah flag `dirty` lewat `Note.copyWith(dirty: false)`.

**Bukti otomatis.** `test/notes_state_test.dart` memakai
`FakeNoteRepository` yang menghitung pemanggilan. Test memastikan
`fetchNotesCalls` tetap **1** setelah tambah, hapus, dan sinkron.

### Temuan 3 — Provider detail tidak pernah dilepas

**Gejala.** `noteByIdProvider` adalah `FutureProvider.family<Note?, int>` tanpa
auto-dispose. Setiap id yang pernah dibuka (termasuk setelah pengguna kembali)
tetap disimpan di `ProviderContainer` selama aplikasi hidup. Pada sesi panjang
ini adalah kebocoran memori yang lambat.

**Perbaikan.** Tambah `isAutoDispose: true` pada family tersebut.

**Bukti otomatis.** `test/provider_disposal_test.dart` membuka
`noteByIdProvider(1)`, menutup subscription terakhir, lalu memastikan
`container.exists(noteByIdProvider(1))` menjadi `false`.

### Temuan 4 — Animasi indikator chat memicu repaint berlebihan

**Gejala.** `_TypingIndicator` beranimasi terus-menerus dan berada di dalam
`ListView` yang sama dengan riwayat chat. Tanpa batas repaint, setiap frame
animasi dapat memaksa area daftar ikut dilukis ulang.

**Perbaikan.** `RepaintBoundary` membungkus indikator; setiap `MessageBubble`
diberi `ValueKey` berbasis waktu + peran agar daftar dapat memakai kembali
elemen dengan benar.

**Catatan verifikasi.** Ini optimasi paint/raster yang sulit dibuktikan
dengan test unit; bukti utamanya adalah struktur widget dan screenshot
DevTools [`../screenshots/after-profile.png`](../screenshots/after-profile.png).
Langkah reproduksi ada di [`performance-report.md`](performance-report.md) §9.
Tidak diklaim mengubah angka scroll.

### Temuan 5 — Riwayat chat tumbuh tanpa batas

**Gejala.** Setiap pertanyaan + jawaban menambah dua `ChatMessage` ke state
tanpa batas. Sesi panjang membuat daftar, memori, dan biaya rebuild terus
naik.

**Perbaikan.** `ChatNotifier.maxMessages = 200` dan `capHistory()` yang
mempertahankan 200 pesan terbaru, dipanggil pada semua jalur yang menambah
pesan (sukses, gagal, error).

**Bukti otomatis.** `test/chat_history_cap_test.dart` memastikan 205 pesan
menjadi 200 dengan pesan terlama terbuang, dan daftar pendek tidak disalin
(`same(...)`).

### Temuan 6 — Toggle tema menghasilkan dua rebuild dan kedip

**Gejala.** `DarkModeNotifier.toggle()` melakukan `state = AsyncLoading()`
lalu menunggu tulis ke `SharedPreferences`, kemudian `AsyncData`. `MyApp`
membangun ulang dua kali dan sempat kehilangan nilai tema.

**Perbaikan.** Optimistic update: set `AsyncData(next)` segera, tulis di
belakang; bila gagal, kembalikan nilai sebelumnya. `main.dart` membaca dengan
`darkModeProvider.select((value) => value.value ?? false)` agar hanya
perubahan boolean yang memicu rebuild.

**Bukti.** Perilaku dibaca langsung dari kode; tidak ada test khusus karena
`PrefsRepository` membutuhkan platform channel. Trade-off: kegagalan tulis
hanya dicatat lewat `debugPrint`, bukan dialog (disengaja — preferensi tema
bukan operasi kritis).

### Temuan 7 — Layout teks panjang di setiap tile

`NoteTile` di baseline merender judul dan isi tanpa `maxLines`. Setiap tile
harus mengukur teks panjang, dan tinggi baris bisa berbeda-beda. Perbaikan:
`maxLines: 1` untuk judul, `maxLines: 2` + ellipsis untuk isi, `Chip` status
dipisah menjadi widget `const`, dan tile diberi `ValueKey(note.id)`.

**Dampak terukur.** Tidak ada perubahan FPS yang bisa diklaim dari emulator;
manfaatnya adalah tinggi baris yang konsisten dan biaya layout per item yang
lebih kecil. Bukti visual: `screenshots/before-home.png` hanya memuat ±4
catatan per layar (judul dan isi penuh, tinggi tidak seragam), sedangkan
`screenshots/after-home.png` memuat ±9 catatan dengan tinggi seragam. Ini
bukan klaim FPS, melainkan kepadatan informasi dan konsistensi layout.

## Yang diperiksa tetapi **tidak** menjadi masalah

| Kandidat | Hasil pemeriksaan | Keputusan |
| --- | --- | --- |
| `ListView` non-builder | Sejak Week 10 sudah `ListView.builder`; hanya item terlihat yang dibangun | Tidak diubah |
| Query SQLite | `fetchNotes` 1.000 baris < 1 ms di emulator; tidak ada N+1 | Tidak perlu indeks/pagination |
| Gambar besar / decode | Aplikasi tidak menampilkan gambar | Tidak berlaku |
| Request API berulang | Hanya chat Gemini, dipicu pengguna, tidak ada polling | Tidak perlu cache HTTP |
| Memory leak controller | `AddNoteDialog` memindahkan controller ke `State` dan men-dispose-nya | Diperbaiki sekalian (sebelumnya controller dibuat di pemanggil) |

## Kesimpulan temuan

1. Bottleneck scroll adalah **raster emulator**, bukan kode Dart. Klaim
   “optimasi membuat scroll 60 FPS” akan menyesatkan dan karena itu tidak
   dibuat.
2. Perbaikan yang paling berdampak adalah **mengurangi pekerjaan yang
   dikendalikan aplikasi**: lingkup rebuild, query ulang setelah mutasi, dan
   objek yang tidak pernah dilepas.
3. Setiap perbaikan diverifikasi dengan test yang bisa gagal, sehingga hasilnya
   bukan placebo.