#!/usr/bin/env bash
# Membuat ulang project baseline (Week 10 + alat ukur) di direktori sementara.
#
# Pemakaian:
#   tool/reproduce_baseline.sh [tujuan]
#
# Default tujuan: /tmp/opencode/week11_baseline
#
# Kode aplikasi Week 10 TIDAK diubah. Skrip hanya:
#   1. menyalin project Week 10,
#   2. menambahkan performance_probe.dart + dev_seed_service.dart,
#   3. mengganti nama paket/aplikasi agar bisa dipasang berdampingan,
#   4. menambahkan flag SEED_NOTES dan pemasangan probe di main.dart.
set -euo pipefail
export LC_ALL=C

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WEEK10="$ROOT/../_10_week_10_ai_feature_integration"
DEST="${1:-/tmp/opencode/week11_baseline}"

if [[ ! -d "$WEEK10" ]]; then
  echo "Project Week 10 tidak ditemukan di: $WEEK10" >&2
  exit 1
fi

rm -rf "$DEST"
mkdir -p "$DEST"

rsync -a \
  --exclude 'build/' \
  --exclude '.dart_tool/' \
  --exclude '.flutter-plugins-dependencies' \
  --exclude 'android/.gradle/' \
  --exclude 'android/.kotlin/' \
  --exclude 'android/local.properties' \
  --exclude '.idea/' \
  "$WEEK10/" "$DEST/"

mkdir -p "$DEST/lib/core/dev"
cp "$ROOT/lib/core/dev/performance_probe.dart" "$DEST/lib/core/dev/"
cp "$ROOT/lib/core/dev/dev_seed_service.dart" "$DEST/lib/core/dev/"

# Nama paket Dart & Android harus berbeda dari aplikasi utama agar keduanya
# bisa terpasang di perangkat yang sama.
perl -pi -e 's/^name: .*/name: week11_baseline/' "$DEST/pubspec.yaml"
perl -pi -e 's/com\.example\.u_05_week_5_local_storage_offline_first/com.example.week11_baseline/g' \
  "$DEST/android/app/build.gradle.kts"

KOTLIN_OLD="$DEST/android/app/src/main/kotlin/com/example/u_05_week_5_local_storage_offline_first"
KOTLIN_NEW="$DEST/android/app/src/main/kotlin/com/example/week11_baseline"
if [[ -f "$KOTLIN_OLD/MainActivity.kt" ]]; then
  mkdir -p "$KOTLIN_NEW"
  mv "$KOTLIN_OLD/MainActivity.kt" "$KOTLIN_NEW/MainActivity.kt"
  perl -pi -e 's/^package .*/package com.example.week11_baseline/' \
    "$KOTLIN_NEW/MainActivity.kt"
  rmdir -p "$KOTLIN_OLD" 2>/dev/null || true
fi

# Tambahkan import + flag seed + probe ke main.dart Week 10.
python3 - "$DEST/lib/main.dart" <<'PY'
import sys

path = sys.argv[1]
source = open(path, encoding="utf-8").read()

imports_old = (
    "import 'package:flutter/material.dart';\n"
    "import 'package:flutter_riverpod/flutter_riverpod.dart';\n"
    "import 'package:go_router/go_router.dart';\n"
)
imports_new = (
    "import 'package:flutter/foundation.dart';\n"
    "import 'package:flutter/material.dart';\n"
    "import 'package:flutter_riverpod/flutter_riverpod.dart';\n"
    "import 'package:go_router/go_router.dart';\n"
    "\n"
    "import 'core/dev/dev_seed_service.dart';\n"
    "import 'core/dev/performance_probe.dart';\n"
)
if imports_old not in source:
    raise SystemExit("Pola import main.dart tidak dikenali")
source = source.replace(imports_old, imports_new, 1)

main_old = (
    "Future<void> main() async {\n"
    "  WidgetsFlutterBinding.ensureInitialized();\n"
    "  runApp(const ProviderScope(child: MyApp()));\n"
    "}\n"
)
main_new = (
    "Future<void> main() async {\n"
    "  WidgetsFlutterBinding.ensureInitialized();\n"
    "\n"
    "  const seedCount = int.fromEnvironment('SEED_NOTES');\n"
    "  if (!kReleaseMode && seedCount > 0) {\n"
    "    await const DevSeedService().replaceWithSample(seedCount);\n"
    "  }\n"
    "\n"
    "  PerformanceProbe.instance.install();\n"
    "  runApp(const ProviderScope(child: MyApp()));\n"
    "}\n"
)
if main_old not in source:
    raise SystemExit("Pola main() tidak dikenali")
source = source.replace(main_old, main_new, 1)

open(path, "w", encoding="utf-8").write(source)
PY

cat <<EOF
Baseline dibuat di: $DEST

Jalankan:
  cd "$DEST"
  flutter pub get
  flutter run -d emulator-5554 --profile \\
    --dart-define=SEED_NOTES=1000 --dart-define=PERF_PROBE=true
EOF