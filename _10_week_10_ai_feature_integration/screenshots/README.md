# Screenshots — Week 10

Bukti berupa **output terminal nyata** (`.txt`) dan **screenshot UI** (`.png`).

## Bukti terminal

| File | Isi | Membuktikan |
| --- | --- | --- |
| `proof-model-deprecation.txt` | Kutipan dokumentasi resmi Gemini (Models & Deprecations, 4 Nov 2026) | `gemini-pro` pensiun; `gemini-2.5-flash` deprecated; `gemini-3.5-flash-lite` Stable |
| `proof-riverpod-conflict.txt` | `flutter pub add riverpod:^2.5.0 --offline` | Konflik versi (exit 65, `version solving failed`) |
| `proof-candidates-crash.txt` | Test replika parsing kode contoh codelab | `NoSuchMethodError: The method '[]' was called on null` saat prompt diblokir |
| `proof-retry-duplicate.txt` | Test retry versi lama | `Expected: <1>, Actual: <2>` — bubble pengguna berlipat |
| `proof-concurrent-send.txt` | Test dua pengiriman tumpang tindih (kode sebelum penjaga) | `Expected: <2>, Actual: <1>` — 2 request dibayar, jawaban pertama hilang |
| `proof-secret-guard.txt` | Test penjaga API key pada kondisi salah | Key tertempel di kode terdeteksi (`Expected: empty`, `Actual: [...]`); key diredaksi |
| `analyze-format-final.txt` | `flutter analyze` + `dart format --set-exit-if-changed .` | Analyze bersih (1 info `package_names`), format exit 0 |
| `flutter-test-final.txt` | `flutter test` | **76/76 test lulus** |
| `greps-sterility.txt` | 5 grep sterilitas | Presentation & domain steril; tidak ada key (`AIza…`/`AQ.…`) di kode; tidak ada `?key=` |

## Screenshot UI

Diambil dari **emulator Android (Pixel_4)** pada 4 November 2026, dengan
catatan uji berisi dua buku (*Madilog*, *Bumi Manusia*). Screenshot memuat
seluruh layar desktop: emulator di kanan, editor kode di kiri — kode yang
terlihat adalah `api_key_store.dart` dan `gemini_assistant_repository_impl.dart`
yang relevan dengan fitur ini.

| File | Yang ditunjukkan | Membuktikan |
| --- | --- | --- |
| `settings-api-key.png` | Bagian "Asisten AI" di Pengaturan: penjelasan penyimpanan, baris status, kolom key tersembunyi yang sudah terisi, tombol **Simpan** | Alur pengisian API key lewat UI (bukan kode). Status masih "Belum diatur" karena gambar diambil **sebelum** Simpan ditekan |
| `assistant-no-key.png` | Halaman asisten: "API key belum diatur" + tombol **Buka Pengaturan** | Fallback tanpa konfigurasi — API tidak dipanggil |
| `assistant-empty.png` | Halaman asisten: "Tanya apa saja tentang catatanmu" + 3 chip contoh | Titik masuk fitur + empty state |
| `assistant-chat.png` | **Uji live**: jawaban nyata model tentang isi catatan | Alur chat berjalan end-to-end dengan API sungguhan |
| `assistant-error.png` | **Uji live** dengan jaringan dimatikan: bubble error + banner "Gagal menghubungi AI." + **Coba lagi** | Fallback error jaringan (`ClientException` → `AiFailure(retryable: true)`) |

### Catatan kejujuran atas isi gambar

1. **`settings-api-key.png`** menampilkan status **"Belum diatur"** karena
   diambil sebelum tombol Simpan ditekan. Yang dibuktikan gambar ini adalah
   *cara memasukkan key*, bukan *hasil penyimpanan*. Setelah disimpan, status
   berubah menjadi "Tersimpan di perangkat" dengan ikon centang hijau —
   perilaku itu dijaga widget test, bukan oleh screenshot ini.
2. **`assistant-chat.png`** memuat **dua** bubble pertanyaan identik dengan
   **satu** jawaban. Itu bukan pengiriman ganda yang disengaja, melainkan
   bukti temuan §7b di [`../docs/ai-log.md`](../docs/ai-log.md): dua
   `send()` tumpang tindih membuat jawaban pertama tertimpa. Bug sudah
   diperbaiki (`_inFlight` di `ChatNotifier`) dan dijaga
   `test/chat_notifier_test.dart`. Gambar sengaja **tidak** diulang agar
   temuan itu tetap punya bukti visual.

Cara mengambil ulang (bila diperlukan):

```bash
cd _10_week_10_ai_feature_integration
flutter run
```

1. Buka **Pengaturan** → bagian **Asisten AI** → tempel API key → **Simpan**.
2. Ambil `settings-api-key.png` **setelah** status menunjukkan "Tersimpan di
   perangkat".
3. Hapus key (tombol hapus) → buka ikon ✨ → ambil `assistant-no-key.png`.
4. Simpan key lagi → buka ikon ✨ → ambil `assistant-empty.png`.
5. Kirim **satu** pertanyaan "Ringkas semua catatanku" → ambil
   `assistant-chat.png`.
6. Matikan Wi-Fi → kirim pertanyaan → tunggu error + tombol **Coba lagi** →
   ambil `assistant-error.png`.

> Jangan pernah memotret API key yang terlihat. Field key sudah tersembunyi
> secara default; tetap periksa ulang sebelum menyimpan gambar.
