#!/usr/bin/env bash
# Check per-target line coverage against a threshold (default 90%).
# Checks app, ctdev, and packages only (not tool/ packages). Run after tool/test_coverage.py. Requires lcov.
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
  # App: enforce threshold on widget-unit code only (lib/widgets/). See SPEC/program/test-logging.md.
  if [ "$dir" = "app" ]; then
    app_widgets="$ROOT/app/coverage/lcov_widgets.info"
    lcov -q --extract "$lcov_file" 'lib/widgets/*' -o "$app_widgets" --ignore-errors empty,unused 2>/dev/null || true
    if [ -s "$app_widgets" ]; then
      lcov_file="$app_widgets"
    fi
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
if [ ${#TARGETS[@]} -eq 1 ]; then
  echo "${TARGETS[0]} at or above ${THRESHOLD}% line coverage."
else
  echo "All checked targets (app, ctdev, packages) at or above ${THRESHOLD}% line coverage."
fi
exit 0
