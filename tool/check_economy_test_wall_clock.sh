#!/usr/bin/env bash
# Economy test wall-clock gate (Refs #3661).
#
# Measures the wall-clock time of `dart test` in packages/colonizethis_economy
# and compares the median of repeated runs against a configurable ceiling. The
# economy suite was deduplicated and its fixtures hoisted in #3661; this tool
# locks in the wall-clock gain so it is not silently regressed.
#
# Modes:
#   - Advisory (default): measure, report, always exit 0 (over-ceiling => WARN).
#   - Enforce (ECONOMY_TEST_TIMING_ENFORCE=1): over-ceiling => exit 1.
#   - Skip (SKIP_ECONOMY_TEST_TIMING=1): print notice, exit 0, no measurement.
#
# Config (see SPEC/program/economy-test-wall-clock.md):
#   ECONOMY_TEST_TIMING_CEILING_SECONDS  (default 25)
#   ECONOMY_TEST_TIMING_RUNS             (default 3; odd integer >= 1)
#   ECONOMY_TEST_TIMING_ENFORCE          (1 => hard fail over ceiling)
#   SKIP_ECONOMY_TEST_TIMING             (1 => skip)
#   ECONOMY_TEST_TIMING_MEASURED_SECONDS (test/CI hook: bypass dart test and
#                                         use this value as the median)
set -euo pipefail

export SUPPRESS_IMAGE_VIEWER="${SUPPRESS_IMAGE_VIEWER:-1}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

PKG_DIR="${ECONOMY_TEST_TIMING_PKG_DIR:-packages/colonizethis_economy}"
CEILING="${ECONOMY_TEST_TIMING_CEILING_SECONDS:-25}"
RUNS="${ECONOMY_TEST_TIMING_RUNS:-3}"
ENFORCE="${ECONOMY_TEST_TIMING_ENFORCE:-0}"

PREFIX="check_economy_test_wall_clock:"

if [ "${SKIP_ECONOMY_TEST_TIMING:-0}" = "1" ]; then
  echo "$PREFIX SKIP_ECONOMY_TEST_TIMING=1 set; skipping economy test timing."
  exit 0
fi

# Validate RUNS is an odd positive integer so the median is well defined.
if ! printf '%s' "$RUNS" | grep -qE '^[0-9]+$' || [ "$RUNS" -lt 1 ] \
  || [ $((RUNS % 2)) -eq 0 ]; then
  echo "$PREFIX ERROR: ECONOMY_TEST_TIMING_RUNS must be an odd integer >= 1 (got '$RUNS')." >&2
  exit 2
fi

# ---- obtain median measurement ---------------------------------------------
if [ -n "${ECONOMY_TEST_TIMING_MEASURED_SECONDS:-}" ]; then
  # Deterministic comparison hook: skip running the suite.
  median="$ECONOMY_TEST_TIMING_MEASURED_SECONDS"
  echo "$PREFIX using injected median ${median}s (dart test not run)."
else
  if [ ! -d "$ROOT/$PKG_DIR/test" ]; then
    echo "$PREFIX ERROR: $PKG_DIR/test not found; nothing to measure." >&2
    exit 2
  fi
  echo "$PREFIX measuring 'dart test' in $PKG_DIR over $RUNS run(s)..."
  measurements=()
  for i in $(seq 1 "$RUNS"); do
    start=$(date +%s.%N)
    (cd "$ROOT/$PKG_DIR" && dart test --reporter=compact \
      --test-randomize-ordering-seed=42 >/dev/null)
    end=$(date +%s.%N)
    elapsed=$(awk -v a="$start" -v b="$end" 'BEGIN { printf "%.2f", b - a }')
    echo "$PREFIX   run $i: ${elapsed}s"
    measurements+=("$elapsed")
  done
  median=$(printf '%s\n' "${measurements[@]}" | sort -g \
    | awk -v n="$RUNS" 'NR==int(n/2)+1 { print; exit }')
fi

# ---- deterministic comparison ----------------------------------------------
# over = 1 when median > ceiling (strictly); equal is within budget.
over=$(awk -v m="$median" -v c="$CEILING" 'BEGIN { print (m > c) ? 1 : 0 }')

if [ "$over" -eq 0 ]; then
  echo "$PREFIX PASS: median ${median}s <= ceiling ${CEILING}s."
  exit 0
fi

if [ "$ENFORCE" = "1" ]; then
  echo "$PREFIX FAIL: median ${median}s > ceiling ${CEILING}s (enforce mode)." >&2
  echo "$PREFIX The economy test suite regressed past its wall-clock budget." >&2
  echo "$PREFIX Restore dedup/fixture hoisting (Refs #3661) or justify a new ceiling." >&2
  exit 1
fi

echo "$PREFIX WARN: median ${median}s > ceiling ${CEILING}s (advisory mode; not failing)."
echo "$PREFIX Set ECONOMY_TEST_TIMING_ENFORCE=1 to make this a hard failure."
exit 0
