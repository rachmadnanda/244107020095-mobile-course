import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

/// Probe ringan untuk mengukur frame time aplikasi saat mode profile.
///
/// Aktif hanya bila dijalankan dengan:
///
/// ```bash
/// flutter run --profile --dart-define=PERF_PROBE=true
/// ```
///
/// Di release probe ini tidak di-install (flag compile-time false), sehingga
/// tidak menambah biaya ke aplikasi produksi.
class PerformanceProbe {
  PerformanceProbe._();

  static final PerformanceProbe instance = PerformanceProbe._();

  /// Flag compile-time. Bukan konfigurasi runtime agar bisa di-tree-shake.
  static const bool enabled = bool.fromEnvironment('PERF_PROBE');

  static const int _window = 120;
  static const double _frameBudgetMs = 1000 / 60;

  final List<FrameTiming> _frames = [];
  bool _installed = false;

  void install() {
    if (!enabled || _installed) return;
    _installed = true;
    SchedulerBinding.instance.addTimingsCallback(_onTimings);
    debugPrint(
      '[PERF] probe aktif — ringkasan dicetak tiap $_window frame '
      '(budget ${_frameBudgetMs.toStringAsFixed(2)} ms)',
    );
  }

  void reset() {
    _frames.clear();
    debugPrint('[PERF] counter direset');
  }

  void _onTimings(List<FrameTiming> timings) {
    _frames.addAll(timings);
    if (_frames.length >= _window) {
      printSummary();
      _frames.clear();
    }
  }

  /// Mencetak ringkasan ke log. Bisa dipanggil manual dari Pengaturan.
  void printSummary() {
    if (_frames.isEmpty) {
      debugPrint('[PERF] belum ada frame terkumpul');
      return;
    }

    final builds = _sortedMs(
      _frames.map((frame) => frame.buildDuration.inMicroseconds),
    );
    final rasters = _sortedMs(
      _frames.map((frame) => frame.rasterDuration.inMicroseconds),
    );
    final totals = _sortedMs(
      _frames.map((frame) => frame.totalSpan.inMicroseconds),
    );

    final jank16 = _frames
        .where((frame) => frame.totalSpan.inMicroseconds > 16667)
        .length;
    final jank32 = _frames
        .where((frame) => frame.totalSpan.inMicroseconds > 33333)
        .length;

    debugPrint(
      '[PERF] frames=${_frames.length} '
      'build_p50=${_p(builds, .5)} build_p90=${_p(builds, .9)} '
      'raster_p50=${_p(rasters, .5)} raster_p90=${_p(rasters, .9)} '
      'total_p50=${_p(totals, .5)} total_p90=${_p(totals, .9)} '
      'jank16=${_percent(jank16)}% jank32=${_percent(jank32)}%',
    );
  }

  List<double> _sortedMs(Iterable<int> microseconds) {
    final values =
        microseconds.map((value) => value / 1000).toList(growable: false)
          ..sort();
    return values;
  }

  String _p(List<double> values, double percentile) {
    final index = (values.length * percentile).floor().clamp(
      0,
      values.length - 1,
    );
    return '${values[index].toStringAsFixed(2)}ms';
  }

  String _percent(int count) {
    if (_frames.isEmpty) return '0.0';
    return (count * 100 / _frames.length).toStringAsFixed(1);
  }
}
