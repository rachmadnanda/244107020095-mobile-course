#!/usr/bin/env bash
# Ringkasan cakupan baris dari coverage/lcov.info (tanpa perlu paket lcov).
#
# Pemakaian:
#   ./tool/coverage_summary.sh [path/lcov.info]
set -euo pipefail

lcov_file="${1:-coverage/lcov.info}"

if [[ ! -f "$lcov_file" ]]; then
  echo "Berkas coverage tidak ditemukan: $lcov_file" >&2
  echo "Jalankan dulu: flutter test --coverage" >&2
  exit 1
fi

echo "== Ringkasan coverage (baris) =="
awk -F: '
  /^LF:/ { lf += $2 }
  /^LH:/ { lh += $2 }
  /^BRF:/ { brf += $2 }
  /^BRH:/ { brh += $2 }
  END {
    if (lf == 0) {
      print "Tidak ada data LF/LH di berkas ini."
      exit 1
    }
    printf "Baris : %d/%d (%.1f%%)\n", lh, lf, (100 * lh / lf)
    if (brf > 0) {
      printf "Cabang: %d/%d (%.1f%%)\n", brh, brf, (100 * brh / brf)
    }
  }
' "$lcov_file"

echo
echo "== Per file (urut persentase) =="
awk -F: '
  /^SF:/ { file = $2; lf = 0; lh = 0 }
  /^LF:/ { lf = $2 }
  /^LH:/ { lh = $2 }
  /^end_of_record/ {
    if (lf > 0) {
      printf "%6.1f%%  %4d/%-4d  %s\n", (100 * lh / lf), lh, lf, file
    }
  }
' "$lcov_file" | sort -n
