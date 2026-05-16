#!/usr/bin/env bash
# Check per-target line coverage against a threshold (default 90%).
# Default targets: app, ctdev, and packages. Pass explicit dirs to include tool packages
# (e.g. tool/run_observer_game) after generating coverage/lcov.info under each. Requires lcov.
# Usage: tool/check_coverage_threshold.sh [threshold] [dir1 [dir2 ...]]
# Example: tool/check_coverage_threshold.sh 90
# Example: tool/check_coverage_threshold.sh 90 packages/colonizethis_logic
set -e
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
THRESHOLD="${1:-90}"
shift || true

if [ $# -eq 0 ]; then
  TARGETS=(packages/colonizethis_models packages/colonizethis_data packages/colonizethis_save packages/colonizethis_logic packages/colonizethis_ai packages/colonizethis_map app ctdev)
else
  TARGETS=("$@")
fi

if ! command -v lcov &>/dev/null; then
  echo "lcov is required. Install it to run this check."
  exit 1
fi

FAILED=()
for dir in "${TARGETS[@]}"; do
  lcov_file="$ROOT/$dir/coverage/lcov.info"
  if [ ! -f "$lcov_file" ]; then
    echo "Skip $dir (no coverage/lcov.info — run tool/test_coverage.py first)"
    continue
  fi
  # App: use full lcov (widgetbook/catalog.dart uses Dart coverage:ignore-file).
  # Copy so consumers of lcov.filtered.info always get a fresh file.
  filtered_lcov="$lcov_file"
  if [ "$dir" = "app" ]; then
    filtered_lcov="$ROOT/$dir/coverage/lcov.filtered.info"
    cp "$lcov_file" "$filtered_lcov"
  fi

  summary=$(lcov --summary "$filtered_lcov" 2>/dev/null) || true
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
if [ ${#TARGETS[@]} -eq 1 ]; then
  echo "${TARGETS[0]} at or above ${THRESHOLD}% line coverage."
else
  echo "All checked targets (app, ctdev, packages) at or above ${THRESHOLD}% line coverage."
fi
exit 0
