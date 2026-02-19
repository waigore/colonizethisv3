#!/usr/bin/env bash
# Check per-package line coverage against a threshold (default 90%).
# Run after tool/test_coverage.sh. Requires lcov.
# Usage: tool/check_coverage_threshold.sh [threshold]
# Example: tool/check_coverage_threshold.sh 90
set -e
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
THRESHOLD="${1:-90}"

if ! command -v lcov &>/dev/null; then
  echo "lcov is required. Install it to run this check."
  exit 1
fi

FAILED=()
for dir in packages/colonizethis_models packages/colonizethis_data packages/colonizethis_save packages/colonizethis_logic packages/colonizethis_ai packages/colonizethis_map app; do
  lcov_file="$ROOT/$dir/coverage/lcov.info"
  if [ ! -f "$lcov_file" ]; then
    echo "Skip $dir (no coverage/lcov.info — run tool/test_coverage.sh first)"
    continue
  fi
  summary=$(lcov --summary "$lcov_file" 2>/dev/null) || true
  line_pct=$(echo "$summary" | grep -E '^\s*lines' | sed -E 's/.*: ([0-9.]+)%.*/\1/') || true
  if [ -z "$line_pct" ]; then
    echo "Skip $dir (could not parse coverage)"
    continue
  fi
  # Compare using awk to handle decimals
  if awk "BEGIN { exit !($line_pct < $THRESHOLD) }"; then
    FAILED+=("$dir: ${line_pct}%")
  fi
done

if [ ${#FAILED[@]} -gt 0 ]; then
  echo "Coverage below ${THRESHOLD}%:"
  printf '  %s\n' "${FAILED[@]}"
  exit 1
fi
echo "All packages at or above ${THRESHOLD}% line coverage."
exit 0
