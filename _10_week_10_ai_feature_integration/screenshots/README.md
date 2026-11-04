# Screenshots — Week 10

Bukti berupa **output terminal nyata** (`.txt`) dan **screenshot UI** (`.png`).

## Bukti terminal

| File | Isi | Membuktikan |
| --- | --- | --- |
| `proof-model-deprecation.txt` | Kutipan dokumentasi resmi Gemini (Models & Deprecations, 4 Nov 2026) | `gemini-pro` pensiun; `gemini-2.5-flash` deprecated; `gemini-3.5-flash-lite` Stable |
| `proof-riverpod-conflict.txt` | `flutter pub add riverpod:^2.5.0 --offline` | Konflik versi (exit 65, `version solving failed`) |
| `proof-candidates-crash.txt` | Test replika parsing kode contoh codelab | `NoSuchMethodError: The method '[]' was called on null` saat prompt diblokir |
| `proof-retry-duplicate.txt` | Test retry versi lama | `Expected: <1>, Actual: <2>` — bubble pengguna berlipat |
| `proof-secret-guard.txt` | Test penjaga API key pada kondisi salah | Key tertempel di kode terdeteksi (`Expected: empty`, `Actual: [...]`); key diredaksi |
| `analyze-format-final.txt` | `flutter analyze` + `dart format --set-exit-if-changed .` | Analyze bersih (1 info `package_names`), format exit 0 |
| `flutter-test-final.txt` | `flutter test` | **70/70 test lulus** |
| `greps-sterility.txt` | 5 grep sterilitas | Presentation & domain steril; tidak ada key (`AIza…`/`AQ.…`) di kode; tidak ada `?key=` |

## Screenshot UI

Diambil manual setelah API key Gemini diatur.

| File | Yang ditunjukkan | Membuktikan |
| --- | --- | --- |
| `assistant-empty.png` | Halaman asisten, empty state + contoh pertanyaan | Titik masuk fitur + empty state |
| `assistant-chat.png` | Pertanyaan pengguna + jawaban AI | Alur chat berjalan end-to-end |
| `assistant-error.png` | Error jaringan + banner "Coba lagi" | Fallback error sementara |
| `assistant-no-key.png` | State "API key belum diatur" | Fallback tanpa konfigurasi (API tidak dipanggil) |
| `settings-api-key.png` | Bagian "Asisten AI" di Pengaturan | Pengelolaan API key + status tersimpan |

Cara mengambil:

```bash
cd _10_week_10_ai_feature_integration
flutter run
```

1. Buka **Pengaturan** → bagian **Asisten AI** → tempel API key → **Simpan**
   → ambil `settings-api-key.png`.
2. Hapus key (tombol hapus) → buka ikon ✨ → ambil `assistant-no-key.png`.
3. Simpan key lagi → buka ikon ✨ → ambil `assistant-empty.png`.
4. Kirim "Ringkas semua catatanku" → ambil `assistant-chat.png`.
5. Untuk `assistant-error.png`: aktifkan mode pesawat / matikan Wi-Fi,
   kirim pertanyaan, tunggu pesan error + tombol **Coba lagi**.

> Jangan pernah memotret API key yang terlihat. Field key sudah tersembunyi
> secara default; tetap periksa ulang sebelum menyimpan gambar.
