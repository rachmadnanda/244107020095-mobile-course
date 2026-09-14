# AI Challenge — AI Output

## 1. AI Assistant

AI assistant yang digunakan dalam praktikum ini adalah **ChatGPT**.

## 2. Tujuan

AI digunakan untuk membantu membuat halaman statistik dengan state management asynchronous menggunakan Riverpod.

Implementasi harus memenuhi beberapa kondisi, yaitu loading, error, dan success.

## 3. Hasil dari AI

AI menghasilkan `StatsNotifier` menggunakan `AsyncNotifier`.

```dart
class StatsNotifier extends AsyncNotifier<List<String>> {
  @override
  Future<List<String>> build() async {
    await Future.delayed(
      const Duration(seconds: 2),
    );

    if (Random().nextDouble() < 0.3) {
      throw Exception('Gagal mengambil data statistik');
    }

    return [
      'Total tugas: 10',
      'Tugas selesai: 6',
      'Tugas belum selesai: 4',
    ];
  }

  Future<void> refresh() async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(
      () => build(),
    );
  }
}

final statsProvider =
    AsyncNotifierProvider<StatsNotifier, List<String>>(
  StatsNotifier.new,
);
```

AI juga menghasilkan halaman `StatsPage` menggunakan `ConsumerWidget`.

Pada halaman tersebut, provider diamati menggunakan:

```dart
final stats = ref.watch(statsProvider);
```

Kemudian state asynchronous ditampilkan menggunakan:

```dart
stats.when(
  loading: () => ...,
  error: (error, stackTrace) => ...,
  data: (data) => ...,
);
```

## 4. Evaluasi Output AI

Output AI diperiksa berdasarkan requirement yang diberikan.

| Requirement             | Hasil  |
| ----------------------- | ------ |
| `flutter_riverpod`      | Sesuai |
| `ConsumerWidget`        | Sesuai |
| `AsyncNotifier`         | Sesuai |
| `AsyncNotifierProvider` | Sesuai |
| Delay 2 detik           | Sesuai |
| Kemungkinan error 30%   | Sesuai |
| Loading state           | Sesuai |
| Error state             | Sesuai |
| Success/data state      | Sesuai |
| Retry                   | Sesuai |
| Unit test               | Sesuai |
| Tipe provider eksplisit | Sesuai |

## 5. Verifikasi

Kode hasil AI tidak langsung dianggap benar. Kode diperiksa menggunakan `flutter analyze` dan `flutter test`.

Jika ditemukan error atau warning, kode diperbaiki sebelum digunakan sebagai hasil akhir praktikum.

## 6. Kesimpulan

AI berhasil membantu membuat implementasi state management asynchronous menggunakan Riverpod.

Namun, hasil dari AI tetap perlu diperiksa dan diuji oleh developer untuk memastikan kode dapat dijalankan dan memenuhi requirement praktikum.
