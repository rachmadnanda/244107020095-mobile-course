# Laporan Performa — Week 11

**Project:** aplikasi catatan offline (lanjutan Week 7–10)
**Tanggal pengukuran:** 11 November 2026
**Mode:** `--profile` (bukan debug/release)
**Perangkat:** emulator `sdk_gphone64_x86_64`, Android 15 / API 35,
1080×2280 @ 440 dpi, Impeller + OpenGLES
**Beban uji:** 1.000 catatan, di-seed deterministik sebelum `runApp`
**Baseline:** project Week 10 (`/tmp/opencode/week11_baseline`, dibuat ulang
dengan `tool/reproduce_baseline.sh`), kode aplikasi tidak diubah; hanya
ditambah probe dan flag seed agar metodenya identik.

---

## 1. Baseline

### 1.1 Metode

`PerformanceProbe` mengumpulkan `FrameTiming` dari engine dan mencetak
ringkasan setiap 120 frame. Skenario:

1. Aplikasi profile dijalankan, data 1.000 catatan sudah ter-seed.
2. Tunggu sampai idle, lalu `adb logcat -c`.
3. 12× swipe ke atas + 12× swipe ke bawah (400 ms per swipe, jeda 400 ms).
4. Kumpulkan 9 jendela; ambil median tiap metrik.

Metrik yang dicatat:

- `build_p50/p90` — waktu UI thread (build + layout + paint Dart).
- `raster_p50/p90` — waktu raster thread (GPU/komposit).
- `total_p50/p90` — rentang total frame.
- `jank16` / `jank32` — persentase frame melewati 16,67 ms / 33,33 ms.

### 1.2 Hasil baseline

Rentang 9 jendela:

| Metrik | p50 | p90 |
| --- | --- | --- |
| Build | 1,25–1,71 ms | 3,12–6,01 ms |
| Raster | 15,61–18,69 ms | 20,02–42,86 ms |
| Total frame | 23,81–33,27 ms | 30,80–75,60 ms |

Median: build 1,34 ms · raster 16,73 ms · total 24,38 ms ·
jank16 96,0% · jank32 18,4%.

> **Interpretasi.** Raster p50 ≈ 16,7 ms berarti emulator sudah menyentuh
> batas 60 FPS hanya dari sisi GPU. Jank tinggi di emulator bukan bukti kode
> Dart lambat; ini alasan utama laporan tidak mengklaim “scroll naik ke 60
> FPS”.

Log mentah: [`../screenshots/before-scroll-metrics.txt`](../screenshots/before-scroll-metrics.txt).

---

## 2. Temuan profiling

Ringkasan; detail dan bukti kode ada di
[`performance-findings.md`](performance-findings.md).

1. **Rebuild terlalu lebar.** Mengetik pencarian membangun ulang seluruh
   `Scaffold`, AppBar (5 aksi), FAB, dan body.
2. **Query ulang setelah mutasi.** Tambah/hapus/sinkron memanggil
   `invalidateSelf()` lalu membaca ulang 1.000 baris dari SQLite.
3. **Provider detail tidak auto-dispose.** Setiap id yang pernah dibuka
   tersimpan permanen di container.
4. **Animasi indikator chat tanpa batas repaint.**
5. **Riwayat chat tanpa batas** (tumbuh sepanjang sesi).
6. **Toggle tema melewati `AsyncLoading`** → dua rebuild + kedip.
7. **Teks tile tanpa `maxLines`** → layout teks panjang berulang.
8. **Controller dialog** dibuat di pemanggil dan baru di-dispose setelah
   `showDialog` selesai.

Yang diperiksa dan **bukan** masalah: daftar sudah `ListView.builder`; query
1.000 baris < 1 ms; tidak ada gambar/feed jaringan; tidak ada polling API;
tidak ada N+1 query.

---

## 3. Optimasi yang diterapkan

| # | Optimasi | Alasan dipilih | Berkas utama |
| --- | --- | --- | --- |
| 1 | Pecah halaman menjadi widget kecil (`NotesPage` stateless, actions/search/body terpisah) | Mengurangi jumlah elemen yang dibangun ulang per ketukan; perubahan paling terukur di jalur interaksi | `lib/features/notes/presentation/pages/notes_page.dart` |
| 2 | Update state lokal + `Note.copyWith` | Menghapus I/O dan pemetaan 1.000 baris untuk perubahan satu baris | `lib/features/notes/presentation/providers/notes_providers.dart` |
| 3 | `noteByIdProvider(..., isAutoDispose: true)` | Membatasi umur objek yang hanya dibutuhkan selama halaman detail terbuka | `notes_providers.dart` |
| 4 | `RepaintBoundary` pada indikator chat + key per pesan | Mengisolasi repaint animasi dari daftar chat | `lib/features/assistant/presentation/pages/assistant_page.dart` |
| 5 | Batas riwayat chat 200 pesan | Menjaga memori dan biaya rebuild chat tetap konstan | `lib/features/assistant/presentation/providers/assistant_providers.dart` |
| 6 | Optimistic dark-mode + `select` | Satu rebuild, tanpa kedip, tanpa `AsyncLoading` | `lib/features/settings/presentation/providers/settings_providers.dart`, `lib/main.dart` |
| 7 | `maxLines`/ellipsis, `const`, `ValueKey` pada tile | Tinggi baris konsisten; layout teks dibatasi | `lib/features/notes/presentation/widgets/note_tile.dart` |
| 8 | `SingleChildScrollView` di detail | Mencegah overflow pada catatan panjang | `lib/features/notes/presentation/pages/note_detail_page.dart` |

Tidak diterapkan (dengan alasan):

- **Pagination** — dataset lokal 1.000 baris, query < 1 ms, daftar sudah lazy.
  Akan ditambahkan bila dataset > 10.000 baris atau `fetchNotes` > 16 ms.
- **Cache gambar / `CachedNetworkImage`** — aplikasi tidak menampilkan gambar.
- **Cache HTTP/Dio** — hanya chat Gemini yang dipicu pengguna; jawaban
  bergantung konteks catatan sehingga tidak aman di-cache sembarangan.

---

## 4. Verifikasi

### 4.1 Metrik frame sesudah optimasi

Skenario identik, 9 jendela × 120 frame:

| Metrik | Baseline | Sesudah | Selisih |
| --- | ---: | ---: | ---: |
| Build p50 (median) | 1,34 ms | 1,42 ms | +0,08 ms |
| Build p90 (median) | 4,01 ms | 4,22 ms | +0,21 ms |
| Raster p50 (median) | 16,73 ms | 16,23 ms | −3,0% |
| Total p50 (median) | 24,38 ms | 23,63 ms | −3,1% |
| Jank > 16 ms (median) | 96,0% | 90,0% | −6,0 poin |
| Jank > 32 ms (median) | 18,4% | 16,0% | −2,4 poin |

Rentang sesudah: build 1,35–1,56 ms · raster 13,85–17,16 ms ·
total 22,36–26,66 ms · jank32 5,0–35,0%.

Log mentah: [`../screenshots/after-scroll-metrics.txt`](../screenshots/after-scroll-metrics.txt).

Bukti DevTools: [`../screenshots/before-profile.png`](../screenshots/before-profile.png)
dan [`../screenshots/after-profile.png`](../screenshots/after-profile.png).
Keduanya memilih frame saat scroll di panel **Performance → Frame Analysis**
(DevTools 2.60 memakai panel ini sebagai pengganti Flame Chart lama):

| | Frame | UI | Raster | Status |
| --- | ---: | ---: | ---: | --- |
| Baseline | 645 | 2,0 ms | 23,9 ms | Raster jank |
| Sesudah | 578 | 2,1 ms | 19,6 ms | Raster jank |

Rata-rata FPS pada header rekaman (41 vs 36) **tidak** dipakai sebagai
pembanding karena cakupan transisi halaman berbeda; metrik yang sah adalah
9 jendela terkontrol di atas. Nilai raster 19,6 ms diambil dari tooltip frame;
bilah fase menampilkan 19,7 ms karena pembulatan.

**Cara membaca hasil ini:**

- Perbaikan total p50 (3,1%) dan jank32 (2,4 poin) kecil dan berada di ambang
  derau emulator. Tidak ada klaim peningkatan besar.
- Build p50 sedikit lebih tinggi (+0,08 ms) — perbedaan ini tidak signifikan
  dan bukan tujuan optimasi; halaman yang dipecah justru menambah satu lapis
  widget.
- Manfaat utama tidak terlihat di scroll karena scroll memang raster-bound;
  manfaatnya ada di interaksi (rebuild scope) dan mutasi data (tanpa query
  ulang), yang diverifikasi di §4.2.

### 4.2 Dampak visual dan kepadatan daftar

Meski FPS scroll tidak berubah banyak, `maxLines` + ellipsis mengubah layout
secara nyata:

| | Baseline | Sesudah |
| --- | --- | --- |
| Catatan terlihat per layar | ±4 | ±9 |
| Tinggi tile | Tidak seragam, ikut panjang teks | Seragam (judul 1 baris, isi 2 baris) |
| Overflow teks | Tidak dibatasi | Ellipsis |

Bukti: `screenshots/before-home.png` vs `screenshots/after-home.png`. Ini
bukan klaim peningkatan FPS, melainkan pengurangan pekerjaan layout per item
dan kepadatan informasi yang lebih wajar untuk daftar catatan.

### 4.3 Bukti berorientasi perilaku (di luar FPS)

| Test | Bukti |
| --- | --- |
| `test/rebuild_scope_test.dart` | Instance `FloatingActionButton` dan tombol sinkronisasi **identik** sebelum/sesudah mengetik — root tidak rebuild |
| `test/notes_state_test.dart` | `fetchNotesCalls` tetap **1** setelah tambah, hapus, dan sinkron |
| `test/provider_disposal_test.dart` | `container.exists(noteByIdProvider(1))` menjadi `false` setelah listener terakhir ditutup |
| `test/chat_history_cap_test.dart` | 205 pesan → 200 pesan terbaru; daftar pendek tidak disalin |
| `test/search_widget_test.dart`, dll. | Perilaku pencarian/empty state tidak berubah (regresi dicegah) |

Test ini penting karena angka frame emulator terlalu berderau untuk
membuktikan optimasi kecil. Test akan **gagal** bila optimasi dicabut.

### 4.4 Memori

Diukur dengan `adb shell dumpsys meminfo <package>` pada beban 1.000 catatan.
Kolom **Heap Alloc** dipakai karena lebih stabil daripada PSS (PSS sangat
dipengaruhi halaman bersih APK dan reclaim sistem).

| Kondisi | Baseline | Sesudah |
| --- | ---: | ---: |
| Heap Alloc saat idle | 46.923 KB | 43.992 KB |
| Heap Alloc setelah buka–tutup detail 5× | 46.881 KB | 44.049 KB |
| Perubahan | −42 KB | +57 KB |

Ringkasan mentah: [`../screenshots/memory-metrics.txt`](../screenshots/memory-metrics.txt).

Kedua aplikasi **tidak menunjukkan pertumbuhan tanpa batas** pada 5 navigasi;
`Note` terlalu kecil untuk terlihat dalam 5 sampel. Perbedaan utama adalah
provider detail sekarang dilepas setelah halaman ditutup — dibuktikan test
disposal, bukan dari selisih PSS. Angka Heap Alloc berbeda ~2,9 MB (6,3%)
tetapi berasal dari dua APK yang dibangun terpisah, jadi diperlakukan sebagai
**indikasi**, bukan klaim kausal.

Catatan: PSS total bergerak 129,1 → 137,9 MB (baseline) dan
137,8 → 130,6 MB (sesudah) karena reclaim halaman bersih; angka ini tidak
dipakai sebagai kesimpulan.

### 4.5 `flutter analyze` & `flutter test`

```bash
dart format --set-exit-if-changed .
flutter analyze
flutter test
```

Hasil 11 November 2026:

- format — bersih
- analyze — **No issues found!**
- test — **85/85 lulus**

---

## 5. Trade-off

| Keputusan | Keuntungan | Biaya |
| --- | --- | --- |
| Memecah halaman menjadi 4 widget | Rebuild terbatas; mudah diuji | Lebih banyak berkas/kelas kecil |
| Update state lokal setelah mutasi | Tanpa query ulang | State harus dijaga konsisten dengan DB; bila repository melakukan transformasi tersembunyi, state lokal bisa menyimpang |
| `isAutoDispose` pada detail | Memori tidak menumpuk | Detail dimuat ulang saat dibuka lagi (satu query by-id, murah) |
| Batas chat 200 pesan | Memori/rebuild konstan | Pesan sangat lama hilang dari sesi (bukan dari penyimpanan) |
| Optimistic dark-mode | Satu rebuild, tanpa kedip | Kegagalan tulis hanya dicatat di log, tidak ditampilkan ke pengguna |

---

## 6. Refleksi

**Optimasi mana yang paling berdampak?**
Pemecahan lingkup rebuild dan penghapusan query ulang setelah mutasi. Keduanya
mengurangi pekerjaan yang sepenuhnya dikendalikan kode aplikasi. Dampaknya
paling jelas pada interaksi (mengetik, tambah/hapus, sinkron), bukan pada FPS
scroll yang sudah dibatasi raster emulator.

**Bagaimana verifikasi bahwa optimasi bekerja, bukan placebo?**
Setiap optimasi dipasangkan dengan test yang bisa gagal: identitas instance
widget, jumlah pemanggilan `fetchNotes`, keberadaan provider setelah dispose,
dan panjang riwayat chat. Angka frame berasal dari `FrameTiming` engine.
Screenshot DevTools before/after diambil dengan skenario yang sama
(lihat §4.1, §9, dan [`../screenshots/README.md`](../screenshots/README.md));
tidak ada screenshot yang dibuat-buat.

**Trade-off yang dihadapi?**
Kode lebih terpecah dan state lokal menambah tanggung jawab konsistensi.
Auto-dispose menukar sedikit waktu muat ulang dengan memori yang lebih
terkendali. Semua trade-off dinilai sepadan karena biayanya satu kali,
sedangkan manfaatnya berulang.

**Kapan optimasi prematur harus dihindari?**
Saat belum ada bukti. Pagination, indeks tambahan, dan cache jaringan sengaja
tidak ditambahkan karena pengukuran menunjukkan bottleneck ada di raster
emulator dan volume data masih kecil. Menambahkannya sekarang hanya akan
menambah kompleksitas tanpa perbaikan yang bisa diukur.

---

## 7. Penggunaan AI dan verifikasi

AI dipakai untuk membantu membaca hasil profiling, mengusulkan kandidat
optimasi, dan menyusun dokumentasi. Semua usulan diverifikasi dengan:
`flutter analyze`, 85 test, profiling nyata di emulator, dan pembacaan ulang
kode. Klaim yang tidak didukung data (mis. “FPS naik 2×”) tidak dimasukkan.
Screenshot DevTools before/after tersedia di
[`../screenshots/before-profile.png`](../screenshots/before-profile.png) dan
[`../screenshots/after-profile.png`](../screenshots/after-profile.png);
detail frame yang dipilih ada di [`../screenshots/README.md`](../screenshots/README.md).

## 8. Keterbatasan

- Pengukuran hanya di satu emulator; perangkat fisik bisa berbeda,
  terutama pada raster thread.
- Jumlah sampel 9 jendela per build; variasi antar-jendela cukup besar
  (jank32 5–35%), sehingga selisih kecil tidak boleh ditafsirkan berlebihan.
- Profiling memori memakai `dumpsys meminfo`, bukan Heap Snapshot DevTools;
  keduanya menjawab pertanyaan berbeda. Snapshot manual tetap disarankan untuk
  melihat objek spesifik.
---

## 9. Lampiran: cara mereproduksi

### 9.1 Baseline (Week 10 + alat ukur)

```bash
./tool/reproduce_baseline.sh /tmp/opencode/week11_baseline
cd /tmp/opencode/week11_baseline
flutter pub get
flutter run -d emulator-5554 --profile \
  --dart-define=SEED_NOTES=1000 \
  --dart-define=PERF_PROBE=true
```

Skrip hanya menyalin project Week 10, menambahkan `performance_probe.dart` dan
`dev_seed_service.dart`, serta flag `SEED_NOTES`; kode aplikasi tidak diubah.

### 9.2 Versi optimasi

```bash
flutter run -d emulator-5554 --profile \
  --dart-define=SEED_NOTES=1000 \
  --dart-define=PERF_PROBE=true
```

### 9.3 Skenario metrik 9 jendela

```bash
adb -s emulator-5554 logcat -c
for i in $(seq 1 12); do
  adb -s emulator-5554 shell input swipe 540 1800 540 400 400
  sleep 0.4
done
for i in $(seq 1 12); do
  adb -s emulator-5554 shell input swipe 540 400 540 1800 400
  sleep 0.4
done
adb -s emulator-5554 logcat -d -s flutter:I | grep '\[PERF\]'
```

### 9.4 Rekaman DevTools

1. Buka DevTools (tekan `v` pada terminal `flutter run`, atau buka URL yang
   tercetak).
2. Tab **Performance** → **Clear all**.
3. Rekam skenario: 8× swipe atas, 8× swipe bawah, buka detail → kembali, ketik
   `catatan` pada pencarian.
4. Tekan tombol pause, lalu pilih satu frame scroll di **Frame Analysis**.
5. Screenshot panel yang menampilkan Frame Chart, UI phases, dan Raster phase.

Catatan: DevTools 2.60 menampilkan **Frame Analysis** (bukan Flame Chart lama);
panel ini tetap menunjukkan fase `Build`, `Layout`, `Paint`, dan `Raster` per
frame sehingga akar bottleneck bisa dibaca.

### 9.5 Animasi sistem

Matikan selama pengukuran, lalu kembalikan setelah selesai:

```bash
adb -s emulator-5554 shell settings put global window_animation_scale 0
adb -s emulator-5554 shell settings put global transition_animation_scale 0
adb -s emulator-5554 shell settings put global animator_duration_scale 0
# ... setelah selesai ...
adb -s emulator-5554 shell settings put global window_animation_scale 1
adb -s emulator-5554 shell settings put global transition_animation_scale 1
adb -s emulator-5554 shell settings put global animator_duration_scale 1
```
