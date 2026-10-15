# Screenshots — Bukti Week 7 Clean Architecture

Tempatkan gambar hasil `flutter run` di folder ini dengan nama sesuai tabel.
Inti bukti: **UI sama seperti sebelum refactor, struktur folder berbeda.**

## A. UI setelah refactor (behavior identik)

Jalankan `flutter run` di folder `_07_week_7_clean_architecture`, lalu tangkap:

| File | Yang ditunjukkan | Membuktikan |
| --- | --- | --- |
| `after-notes-list.png` | Daftar catatan berisi beberapa item + badge "Belum tersinkron" | `GetNotes` tetap jalan |
| `after-add-note.png` | Dialog "Tambah Catatan" + hasil setelah disimpan | `AddNote` use case + repo berfungsi |
| `after-note-detail.png` | Halaman detail satu catatan (rute `/note/:id`) | `fetchNote` + routing tetap jalan |
| `after-sync.png` | SnackBar hasil sinkronisasi | `SyncNotes` + offline toggle berfungsi |
| `after-settings.png` | Halaman pengaturan (mode gelap + "Waktu terakhir dibuka") | Fitur settings (prefs) tetap jalan |

## B. Bukti "before" (pembanding UI)

| File | Yang ditunjukkan | Membuktikan |
| --- | --- | --- |
| `before-notes-list.png` | Daftar catatan dari project `_05_week_5_local_storage_offline_first` | Tampilan sama sebelum refactor |

> Boleh reuse screenshot lama di `_05_.../screenshots/` bila ada yang cocok.

## C. Bukti struktur (bukan UI)

Screenshot struktur folder `lib/` di IDE / file explorer:

| File | Yang ditunjukkan | Membuktikan |
| --- | --- | --- |
| `structure-before.png` | `lib/{data, pages, widgets}` (project `_05_...`) | Struktur sebelum refactor |
| `structure-after.png` | `lib/core/` + `lib/features/{notes,settings}/{domain,data,presentation}` | Inti Clean Architecture |

## D. Bukti verifikasi (terminal)

| File | Yang ditunjukkan | Membuktikan |
| --- | --- | --- |
| `tests-pass.png` | Output `flutter test` (8 hijau) | Semua test lulus |
| `greps-zero.png` | Output 3 grep sterilitas (NOL) | Dependency rule terbukti |

> `greps-zero.png` sekaligus menjadi bukti visual checklist AI Challenge
> (lihat `docs/ai-challenge.md` §4).

## Cara cepat menangkap semuanya

```bash
# Dari folder _07_week_7_clean_architecture
flutter test            # -> tangkap untuk tests-pass.png
# 3 grep sterilitas    # -> tangkap untuk greps-zero.png
flutter run             # -> tangkap layar A (after-*.png)
```
