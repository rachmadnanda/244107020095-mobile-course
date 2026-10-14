# AI Challenge — Local Storage

## Prompt yang Digunakan

> Aplikasi Flutter Offline Notes: CRUD catatan + preferensi tema.  
> Bandingkan SharedPreferences, Hive, sqflite (SQLite), dan Drift untuk dua kebutuhan ini.  
> Kriteria: kompleksitas query, kebutuhan relasi, reaktivitas (stream), type-safety, ukuran boilerplate, dan kemudahan testing.  
> Beri rekomendasi final dalam satu tabel. Tunjukkan skema untuk 1000+ catatan dan jelaskan trade-off setiap pilihan.

## Perbandingan Storage

| Storage | Kompleksitas Query | Relasi | Stream/Reaktivitas | Type-safety | Boilerplate | Testing | Rekomendasi |
|---|---|---|---|---|---|---|---|
| SharedPreferences | Sangat sederhana, key-value | Tidak mendukung | Tidak tersedia secara bawaan | Rendah | Sangat kecil | Mudah | Preferensi tema saja |
| Hive | Sederhana, berbasis box | Terbatas/tidak relasional | Tidak sekuat database reaktif | Sedang, bergantung adapter | Kecil-sedang | Cukup mudah | Alternatif untuk data sederhana |
| sqflite/SQLite | Mendukung query SQL kompleks | Mendukung relasi dan indeks | Tidak otomatis; perlu trigger/polling/StreamController | Sedang; model dan SQL manual | Sedang | Baik dengan database test | Catatan offline |
| Drift | SQL kompleks dengan API terstruktur | Mendukung relasi dan indeks | `watch()` mendukung stream reaktif | Tinggi melalui code generation | Besar | Sangat baik dengan database test | Catatan kompleks/reaktif |

## Keputusan Final

- **Preferensi tema:** `SharedPreferences`, karena hanya menyimpan nilai sederhana seperti `light`, `dark`, atau `system`.
- **Data catatan:** `SQLite` melalui `sqflite`, karena mendukung CRUD, pencarian, pengurutan, indeks, dan data dalam jumlah besar.
- **Drift** merupakan alternatif yang lebih type-safe dan reaktif, tetapi boilerplate dan setup code generation lebih besar.
- Daftar catatan **tidak disimpan di SharedPreferences** karena penyimpanan koleksi besar sebagai JSON rapuh, sulit dicari, dan tidak efisien.

## Skema SQLite untuk 1000+ Catatan

```text
notes
├── id            INTEGER PRIMARY KEY AUTOINCREMENT
├── title         TEXT NOT NULL
├── body          TEXT NOT NULL
├── created_at    INTEGER NOT NULL
├── updated_at    INTEGER NOT NULL
├── dirty         INTEGER NOT NULL DEFAULT 1
└── deleted       INTEGER NOT NULL DEFAULT 0

Index:
├── idx_notes_updated_at ON notes(updated_at)
└── idx_notes_dirty ON notes(dirty)
```

Contoh SQL:

```sql
CREATE TABLE notes (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  dirty INTEGER NOT NULL DEFAULT 1,
  deleted INTEGER NOT NULL DEFAULT 0
);

CREATE INDEX idx_notes_updated_at
ON notes(updated_at);

CREATE INDEX idx_notes_dirty
ON notes(dirty);
```

Kolom `dirty` menandai data lokal yang belum tersinkronisasi. Kolom `updated_at` digunakan untuk menentukan perubahan terbaru saat sinkronisasi. Kolom `deleted` dapat digunakan sebagai tombstone agar penghapusan juga dapat disinkronkan.

## Trade-off

### SharedPreferences

Kelebihan:

- Instalasi dan penggunaan sederhana.
- Cocok untuk preferensi kecil.
- Tidak membutuhkan skema database.

Kekurangan:

- Tidak cocok untuk ribuan catatan.
- Tidak mendukung query, relasi, indeks, atau transaksi kompleks.
- Tidak menyediakan stream perubahan bawaan.

### Hive

Kelebihan:

- Cepat dan ringan.
- API sederhana.
- Cocok untuk penyimpanan object atau cache sederhana.

Kekurangan:

- Query dan relasi tidak sekuat SQLite.
- Membutuhkan adapter untuk object tertentu.
- Struktur data kompleks dapat lebih sulit dimigrasikan.

### sqflite/SQLite

Kelebihan:

- Stabil dan cocok untuk data besar.
- Mendukung SQL, transaksi, relasi, dan indeks.
- Mudah digunakan untuk kebutuhan CRUD dan sinkronisasi offline.

Kekurangan:

- SQL dan pemetaan model harus ditulis manual.
- Tidak memiliki stream reaktif secara otomatis.
- Migrasi skema perlu dikelola sendiri.

### Drift

Kelebihan:

- Type-safe.
- Mendukung query kompleks dan relasi.
- Memiliki `watch()` untuk stream data reaktif.
- Testing database lebih terstruktur.

Kekurangan:

- Membutuhkan code generation.
- Boilerplate dan konfigurasi lebih banyak.
- Migrasi tetap perlu direncanakan.

## Verifikasi AI

| Pemeriksaan | Temuan |
|---|---|
| Apakah daftar catatan disimpan di SharedPreferences? | Ditolak. SharedPreferences hanya digunakan untuk preferensi tema. |
| Apakah skema mendukung antrean sinkronisasi? | Ya, menggunakan `dirty`, `updated_at`, dan `deleted`. |
| Apakah klaim real-time menggunakan stream? | Hanya Drift yang menyediakan `watch()` secara langsung. sqflite memerlukan implementasi tambahan. |
| Apakah boilerplate masuk akal? | SharedPreferences paling kecil, sqflite sedang, dan Drift paling besar karena code generation. |
| Keputusan akhir | SharedPreferences untuk preferensi dan SQLite/sqflite untuk catatan. |

## Hasil Testing

Perintah instalasi yang digunakan:

```bash
flutter pub add shared_preferences
flutter pub add sqflite
flutter pub add path
```

Hasil pengujian yang harus dicatat:

- Preferensi tema dapat disimpan dan dibaca kembali.
- Catatan dapat ditambah, dibaca, dan dihapus setelah aplikasi dimulai ulang.
- Catatan dengan `dirty = 1` muncul sebagai belum tersinkronisasi.
- Query tetap berjalan untuk data 1000+ catatan.
- Migrasi database tidak menghapus data lama.

## Kesimpulan

Kombinasi `SharedPreferences + SQLite` dipilih karena sesuai dengan karakteristik masing-masing data. Preferensi tema berukuran kecil dan berbentuk key-value, sedangkan catatan membutuhkan query, indeks, transaksi, dan dukungan untuk antrean sinkronisasi offline.

## Verifikasi Refactoring Tahap 7

- Baris daftar catatan diekstrak ke widget `NoteTile` dan menampilkan badge
  `Belum tersinkron` saat `dirty` bernilai benar.
- Cache posts dan `syncNotes` dipusatkan di `lib/data/sync.dart`; file lama
  `post_cache.dart` hanya mempertahankan export kompatibilitas.
- Detail catatan tersedia melalui GoRouter pada `/note/:id` dan mengambil data
  langsung dari repository lokal melalui provider family.
- `test/note_test.dart` menguji mapping null-safe serta provider dengan
  `FakeNoteRepository`, tanpa membuka SQLite.