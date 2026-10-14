/// Fungsi format murni (tanpa widget) agar bisa diunit-test.
///
/// Dipakai presentation untuk menampilkan tanggal secara konsisten tanpa
/// menaruh logika formatting di dalam `build()`.

/// Format `dd/MM/yyyy HH:mm` dari [date].
library;

String formatDateTime(DateTime date) {
  final d = date.toLocal();
  String two(int v) => v.toString().padLeft(2, '0');
  return '${two(d.day)}/${two(d.month)}/${d.year} ${two(d.hour)}:${two(d.minute)}';
}

/// Parse string tanggal dengan aman; mengembalikan null bila tidak valid.
DateTime? tryParseDate(String? value) {
  if (value == null || value.isEmpty) return null;
  return DateTime.tryParse(value);
}
