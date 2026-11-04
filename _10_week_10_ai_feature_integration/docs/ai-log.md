# AI Log — Week 10 (Chat Asisten Catatan)

Dokumen ini menyimpan **prompt**, **output awal AI**, **verifikasi**, dan
**keputusan terima/tolak**. Nilai ada pada kualitas verifikasi, bukan pada
banyaknya kode AI.

## 0. Ringkasan & ruang lingkup

| Item | Isi |
| --- | --- |
| Fitur yang dipilih | **Chat asisten catatan** (bukan OCR / Speech-to-Text) |
| Model | `gemini-3.5-flash-lite` (status *Stable*) |
| Transport | REST `generateContent` lewat `package:http` |
| Penyimpanan API key | `flutter_secure_storage` (Keychain/Keystore) |
| Pola arsitektur | feature-first Clean Architecture (domain ← data, presentation) |
| Output awal AI | Kode contoh codelab Week 10 (dipakai sebagai DRAFT v1) |
| Status uji live API | **Belum dijalankan** — API key belum tersedia (lihat §9) |

**Mengapa chat, bukan OCR/STT?** Chat memberi nilai langsung pada data yang
sudah dimiliki aplikasi (catatan lokal), tidak menambah izin kamera/mikrofon,
dan tidak memerlukan paket `image_picker`/`record` yang tidak tersedia di pub
cache mesin ini. OCR/STT akan menambah dua sumber kegagalan baru (izin runtime
+ unggah berkas) tanpa memperkuat materi utama minggu ini: integrasi LLM,
privasi, biaya, dan fallback.

## 1. Prompt 5 slot (yang benar-benar dipakai)

```text
Peran: senior Flutter developer yang disiplin pada Clean Architecture.
Konteks: project hasil refactor Week 7 (feature-first).
  lib/features/<fitur>/{domain,data,presentation}; domain bebas Flutter,
  http, dan storage. Presentation hanya boleh membaca provider.
  Stack: flutter_riverpod 3.4.3, go_router 18, sqflite 2.4.4, http 1.6.0,
  flutter_secure_storage 11.2.0.
  Kontrak yang sudah ada:
    NoteRepository.fetchNotes() -> ({List<Note> notes, Failure? failure})
    Note { int? id, String title, String body, DateTime updatedAt, bool dirty }
    Failure { sealed: LocalFailure, NetworkFailure, ValidationFailure }
Tugas: tambah fitur "chat asisten catatan" memakai Gemini API.
  Pengguna bertanya, aplikasi mengirim konteks catatan lokal + pertanyaan,
  lalu menampilkan jawaban di halaman chat.
Batas:
  - Jangan taruh API key di kode sumber; simpan di secure storage.
  - Jangan panggil http/jsonDecode dari presentation.
  - Jangan kirim data pribadi mentah ke API.
  - Tangani error tanpa melempar exception mentah ke widget.
  - Maksimal 150 baris per file; jangan sentuh fitur notes/settings
    kecuali menambah titik masuk.
Output: kode per layer + daftar test + cara uji manual.
```

Konteks yang **tidak** disertakan: API key, seluruh isi repo, dan data catatan
nyata. Yang disertakan hanya struktur folder, kontrak, dan entity.

## 2. Output awal AI (DRAFT v1)

DRAFT v1 di bawah adalah pola yang dihasilkan AI bila diminta "buat fitur chat
AI" tanpa batas tambahan — **identik dengan kode contoh codelab Week 10**.
Draft ini **tidak dipakai apa adanya**; setiap baris diverifikasi di §3.

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AiService {
  final _storage = const FlutterSecureStorage();
  final _apiUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent';

  Future<String> ask(String question) async {
    final apiKey = await _storage.read(key: 'ai_api_key');
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('API key tidak tersedia. Silakan atur di pengaturan.');
    }

    final response = await http.post(
      Uri.parse('$_apiUrl?key=$apiKey'),          // (3) key di query string
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': question},
            ],
          },
        ],
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['candidates'][0]['content']['parts'][0]['text']; // (4)
    } else {
      throw Exception('Gagal memanggil AI API: ${response.statusCode}'); // (5)
    }
  }

  Future<void> saveApiKey(String key) async {
    await _storage.write(key: 'ai_api_key', value: key);
  }
}
```

Dependensi yang diminta codelab:

```yaml
dependencies:
  http: ^1.2.0
  flutter_secure_storage: ^9.0.0
  riverpod: ^2.5.0        # (2) konflik dengan flutter_riverpod 3.4.3
```

## 3. Verifikasi DRAFT v1 — 6 temuan + 1 kebutuhan tambahan

| # | Temuan | Level | Bukti | Keputusan |
| --- | --- | --- | --- | --- |
| 1 | `gemini-pro` sudah pensiun | blocker | [`proof-model-deprecation.txt`](../screenshots/proof-model-deprecation.txt) | **DITERIMA** — ganti `gemini-3.5-flash-lite` |
| 2 | `riverpod: ^2.5.0` konflik dengan `flutter_riverpod 3.4.3` | blocker | [`proof-riverpod-conflict.txt`](../screenshots/proof-riverpod-conflict.txt) | **DITERIMA** — jangan tambah `riverpod` terpisah |
| 3 | API key dikirim lewat `?key=` di URL | blocker (keamanan) | Test `gemini_repository_test.dart` + dokumentasi Google | **DITERIMA** — pakai header `x-goog-api-key` |
| 4 | `candidates[0]` crash saat prompt diblokir | blocker | [`proof-candidates-crash.txt`](../screenshots/proof-candidates-crash.txt) | **DITERIMA** — parsing defensif |
| 5 | `throw Exception` ke presentation | blocker (UX) | Test `prompt diblokir safety → AiFailure` | **DITERIMA** — record `(value, failure)` |
| 6 | Tidak ada timeout pada `http.post` | blocker | Test `timeout → AiFailure` | **DITERIMA** — timeout 20 detik |
| 7 | Tidak ada redaksi data pribadi & batas konteks | blocker (privasi/biaya) | Test `privacy_guard_test.dart`, `ask_assistant_test.dart` | **DITERIMA** — `PrivacyGuard` + batas 5 catatan / 1500 karakter |

### Temuan #1 — model pensiun

Halaman resmi Models & Deprecations (diambil 4 November 2026) tidak lagi
mencantumkan `gemini-pro`; endpoint-nya sudah dimatikan. Kandidat pengganti
`gemini-2.5-flash` juga sudah *deprecated* (efektif 1 Desember 2026 dialihkan
ke `gemini-3.5-flash-lite`). Model final: **`gemini-3.5-flash-lite`** (Stable).

Bukti: [`../screenshots/proof-model-deprecation.txt`](../screenshots/proof-model-deprecation.txt).

### Temuan #2 — konflik versi Riverpod

```text
$ flutter pub add riverpod:^2.5.0 --offline
Because _10_week_10_ai_feature_integration depends on flutter_riverpod ^3.4.3
  which depends on riverpod 3.4.3, riverpod 3.4.3 is required.
So, because _10_week_10_ai_feature_integration depends on riverpod ^2.5.0,
  version solving failed.
exit: 65
```

`flutter_riverpod` sudah membawa `riverpod` sebagai dependensi transitif;
menambahkannya manual dengan versi lama justru merusak resolusi. **Tidak ada**
`riverpod:` di `pubspec.yaml` final.

### Temuan #3 — API key di query string

`?key=...` ikut tercatat di access log server, proxy, riwayat URL, dan
laporan crash. Google menyediakan header `x-goog-api-key` untuk menghindari
ini. Kode final mengirim key **hanya** lewat header, dan test menegaskan URL
tidak memuat key:

```dart
expect(captured.headers['x-goog-api-key'], 'AIza-test-key');
expect(captured.url.toString(), isNot(contains('AIza-test-key')));
```

### Temuan #4 — `candidates[0]` crash

Saat prompt diblokir filter keamanan, respons **tidak punya** `candidates`.
Replika kode contoh diuji dan gagal:

```text
NoSuchMethodError: The method '[]' was called on null.
```

Kode final memeriksa `promptFeedback.blockReason`, panjang `candidates`, dan
keberadaan `parts` sebelum mengakses indeks 0.

### Temuan #5 — exception mentah ke UI

`throw Exception(...)` memaksa setiap pemanggil menebak tipe error dan
menampilkan pesan teknis. Kode final memakai record
`({String? answer, Failure? failure})` dan `AiFailure` dengan flag
`retryable`, sehingga widget hanya menampilkan `failure.message` yang ramah.

### Temuan #6 — tanpa timeout

`http.post` tanpa `.timeout()` bisa menggantung tanpa batas saat jaringan
buruk. Kode final memakai `timeout` 20 detik dan memetakan `TimeoutException`
menjadi `AiFailure(retryable: true)`.

### Kebutuhan tambahan #7 — privasi & biaya

Codelab hanya memberi catatan "jangan kirim data sensitif", tanpa mekanisme.
Kode final menambahkan `PrivacyGuard` (redaksi email/NIK/telepon) dan batas
konteks (`maxNotes = 5`, `maxContextChars = 1500`). Keduanya diuji murni tanpa
jaringan.

## 4. Refactor ke Clean Architecture

| Sebelum (DRAFT v1) | Sesudah |
| --- | --- |
| `AiService` tunggal di `lib/ai/` | `features/assistant/{domain,data,presentation}` |
| `http.post` + `jsonDecode` bercampur logika | `GeminiAssistantRepository` (data) — satu-satunya yang tahu HTTP/JSON |
| `throw Exception` | record `(answer, failure)` + `AiFailure.retryable` |
| Tanpa system prompt | `AskAssistant.systemPrompt` (persona + batas + larangan mengarang) |
| Pertanyaan dikirim apa adanya | `PrivacyGuard.sanitize()` + `trimContext()` sebelum dikirim |
| Key di query string | header `x-goog-api-key` |
| Tidak ada fallback | state "API key belum diatur" + tombol "Coba lagi" |

Struktur final:

```text
lib/features/assistant/
├── domain/
│   ├── entities/chat_message.dart
│   ├── repositories/ai_assistant_repository.dart   # + ApiKeyRepository
│   ├── services/privacy_guard.dart
│   └── usecases/ask_assistant.dart
├── data/
│   ├── ai/api_key_store.dart
│   └── repositories/gemini_assistant_repository_impl.dart
└── presentation/
    ├── pages/assistant_page.dart
    ├── providers/assistant_providers.dart
    └── widgets/message_bubble.dart
```

## 5. Test sebagai pembukti

47 test baru, total **70/70 lulus**. Test ditulis untuk menargetkan perilaku
yang benar, bukan sekadar mengejar coverage.

| File | Jumlah | Fokus |
| --- | --- | --- |
| `privacy_guard_test.dart` | 10 | Redaksi email/NIK/telepon, potong konteks pada batas kata |
| `ask_assistant_test.dart` | 10 | System prompt, batas 5 catatan, redaksi, validasi pertanyaan kosong |
| `gemini_repository_test.dart` | 17 | Header key, model, skema body, parsing defensif, status HTTP, timeout |
| `assistant_widget_test.dart` | 8 | No-key state, empty state, kirim pesan, indikator menulis, retry |
| `no_hardcoded_secrets_test.dart` | 2 | Penjaga: tidak ada API key di `lib/`; nama slot secure storage bukan key |

Dua bug ditemukan oleh test dan diperbaiki:

1. **Bug kode — regex NIK terlalu kaku.** Pola `\d{6}\d{6}\d{4}` gagal
   meredaksi format lazim `3573-0125-0495-0001`. Diubah ke pola longgar
   `\d{4}[\s.-]?\d{4}[\s.-]?\d{4}[\s.-]?\d{4}`.
2. **Asersi test keliru.** Ekspektasi `'[email] saya'` salah; `redact` hanya
   mengganti alamat email, bukan memindahkannya. Diperbaiki menjadi
   `'email saya [email]'`.

Bukti hijau: [`../screenshots/flutter-test-final.txt`](../screenshots/flutter-test-final.txt).

## 5b. Insiden: API key tertulis di kode sumber

Kesalahan nyata yang terjadi **setelah** semua test hijau — ditemukan saat
menguji manual, bukan oleh test:

```dart
// SALAH — konstanta ini adalah NAMA SLOT, bukan isi key
static const _key = 'AQ.Ab8RN6J7…';

// BENAR
static const _key = 'gemini_api_key';
```

Dua dampak:

1. Key masuk ke berkas yang bisa ter-commit. (Dicek: belum pernah masuk
   history — `git log -S` kosong — lalu key di-revoke/diganti.)
2. Aplikasi **tetap** melaporkan "API key belum diatur", karena `read()`
   mencari slot yang namanya adalah key itu sendiri. Key tidak pernah
   terbaca dari konstanta.

**Akar masalah verifikasi:** grep sterilitas #4 hanya mencari `AIza…`,
sedangkan key generasi baru berformat `AQ.…` sehingga lolos tanpa terdeteksi.
Perbaikan berlapis:

| Lapis | Perubahan |
| --- | --- |
| Kode | Konstanta dikembalikan ke `'gemini_api_key'` |
| Grep | Pola menjadi `AIza[0-9A-Za-z_-]{20,}\|AQ\.[A-Za-z0-9_-]{20,}` |
| Test | `no_hardcoded_secrets_test.dart` memindai seluruh `lib/` dan memastikan nama slot bukan key |

Test penjaga dibuktikan **merah** pada kondisi yang salah sebelum diterima:

```text
Expected: empty
  Actual: ['lib/features/assistant/data/ai/api_key_store.dart']
Expected: false
  Actual: <true>
Nama slot "AQ.<REDACTED>" terlihat seperti API key.
```

Bukti: [`../screenshots/proof-secret-guard.txt`](../screenshots/proof-secret-guard.txt)
(key pada output sengaja diredaksi sebelum disimpan).

**Pelajaran:** "hijau" hanya sekuat cakupan pemeriksaannya. Aturan yang hanya
dijaga grep manual akan bolong saat format data berubah; aturan yang penting
harus dijadikan test.

## 6. AI Challenge — review kode final (6 temuan)

Prompt:

```text
Review kode fitur chat AI Flutter ini sebagai senior dev.
Konteks: feature-first (presentation->domain<-data), Riverpod 3, http, secure
storage. Fokus: kebenaran, arsitektur, privasi, UX. Abaikan style.
Beri temuan + level blocker/saran + alasan.
```

| # | Temuan AI | Level | Keputusan | Alasan |
| --- | --- | --- | --- | --- |
| 1 | Tombol "Coba lagi" memanggil `send(q)` biasa → bubble pengguna berlipat | blocker | **DITERIMA + diperbaiki** | Test merah: `Expected: <1>, Actual: <2>` |
| 2 | `ChatMessage.copyWith` tidak pernah dipakai | saran | **DITERIMA + dihapus** | Dead code; grep menunjukkan 0 pemanggil |
| 3 | `_buildChat(List messages)` memakai raw `List` | saran | **DITERIMA + diperbaiki** | Diganti `List<ChatMessage>` agar type-safe |
| 4 | Tidak ada batas request per pengguna/hari | saran | **DITOLAK (scope)** | Aplikasi lokal single-user tanpa backend/auth; mitigasi: `maxNotes`, `maxContextChars`, timeout, dan kuota gratis Gemini. Butuh backend untuk rate limit yang benar-benar bisa ditegakkan |
| 5 | Riwayat percakapan tidak dikirim ke model (tidak multi-turn) | saran | **DITOLAK (desain)** | Setiap pertanyaan sengaja berdiri sendiri: hemat token, kecil risiko privasi, dan konteks catatan sudah dikirim ulang tiap request. Multi-turn dicatat sebagai backlog |
| 6 | Validasi API key hanya "tidak kosong" | saran | **DITOLAK** | Format key dapat berubah; validasi sebenarnya ada di server (401/403) dan UI sudah menampilkan pesan yang jelas |

Bukti temuan #1: [`../screenshots/proof-retry-duplicate.txt`](../screenshots/proof-retry-duplicate.txt).

### Keputusan per file

| File | Keputusan |
| --- | --- |
| `lib/ai/ai_service.dart` (DRAFT v1) | **TOLAK seluruhnya** — key di URL, model pensiun, parsing rapuh, exception mentah |
| `domain/entities/chat_message.dart` | **TULIS MANUAL** (AI tidak memisahkan entity dari state UI) |
| `domain/repositories/ai_assistant_repository.dart` | **TULIS MANUAL** (kontrak + `ApiKeyRepository`) |
| `domain/services/privacy_guard.dart` | **TULIS MANUAL** — tidak ada di output AI |
| `domain/usecases/ask_assistant.dart` | **TULIS MANUAL** — AI menaruh prompt di dalam service data |
| `data/ai/api_key_store.dart` | **TERIMA ide + refactor** ke balik interface `ApiKeyRepository` |
| `data/repositories/gemini_assistant_repository_impl.dart` | **TULIS ULANG** — header key, model baru, parsing defensif, timeout |
| `presentation/providers/assistant_providers.dart` | **TULIS MANUAL** — satu-satunya titik wiring DI |
| `presentation/pages/assistant_page.dart` | **TERIMA struktur UI + refactor** — hapus akses data langsung |
| `presentation/widgets/message_bubble.dart` | **TERIMA** — murni presentasi, tanpa logika AI |
| `test/*` | **TULIS MANUAL** — AI hanya memberi kasus sukses |

## 7. Prompt runtime: system prompt, user prompt, dan output

### 7.1 System prompt (`AskAssistant.systemPrompt`)

```text
Kamu asisten catatan pribadi yang ramah. Jawab dalam Bahasa Indonesia,
maksimal 3 kalimat, hanya berdasarkan catatan yang diberikan. Jika
jawabannya tidak ada di catatan, katakan bahwa datanya tidak ada. Jangan
mengarang isi catatan dan jangan meminta data pribadi.
```

### 7.2 User prompt (disusun `AskAssistant._buildUserPrompt`)

Contoh untuk pertanyaan "Apa isi catatan belanja?" dengan dua catatan:

```text
Catatan pengguna:
- Belanja: susu dan telur
- Kuliah: tugas mobile dikumpulkan Jumat

Pertanyaan: Apa isi catatan belanja?
```

Aturan penyusunan:

- Maksimal **5 catatan** (`maxNotes`) — kendali biaya.
- Isi catatan dipotong **1500 karakter** pada batas kata (`maxContextChars`).
- Email, NIK, dan nomor telepon diredaksi menjadi `[email]`, `[nik]`,
  `[telepon]` **sebelum** teks meninggalkan perangkat.

### 7.3 Output awal AI (jawaban model)

**Belum tersedia.** API key Gemini belum dibuat, sehingga belum ada respons
nyata dari model untuk didokumentasikan. Yang sudah dibuktikan adalah
*parsing* respons (17 test dengan body JSON tiruan, termasuk kasus prompt
diblokir) dan *penyusunan* prompt (10 test). Bagian ini akan diisi output
nyata setelah API key tersedia dan uji live dijalankan — bukan dikarang.

## 8. Yang belum diuji

| Hal | Status | Alasan |
| --- | --- | --- |
| Panggilan nyata ke Gemini API | **belum** | API key belum dibuat |
| Perilaku model terhadap prompt asli | **belum** | idem |
| Tampilan di perangkat/emulator | **belum** | screenshot UI menunggu pengambilan manual |

Semua yang bisa diuji tanpa jaringan (domain, parsing, state, widget) sudah
diuji dan hijau. Klaim "fitur berjalan end-to-end" **tidak** dibuat sampai
uji live benar-benar dilakukan.
