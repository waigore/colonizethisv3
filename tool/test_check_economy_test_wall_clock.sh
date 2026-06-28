#!/usr/bin/env bash
# Regression tests for tool/check_economy_test_wall_clock.sh (Refs #3661).
#
# These exercise the deterministic comparison + mode behaviour without running
# the real economy suite by injecting ECONOMY_TEST_TIMING_MEASURED_SECONDS (and
# SKIP_ECONOMY_TEST_TIMING for the skip path). Run directly:
#   bash tool/test_check_economy_test_wall_clock.sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT="$ROOT/tool/check_economy_test_wall_clock.sh"

if [ ! -f "$SCRIPT" ]; then
  echo "FAIL: cannot find $SCRIPT" >&2
  exit 1
fi

PASS_COUNT=0
FAIL_COUNT=0
FAIL_NAMES=()

# run_case <name> <expected_rc> <expected_substr> <env assignments...>
run_case() {
  local name="$1"; shift
  local expected_rc="$1"; shift
  local expected_substr="$1"; shift

  echo "--- $name ---"
  local out_file
  out_file="$(mktemp)"
  set +e
  env "$@" bash "$SCRIPT" >"$out_file" 2>&1
  local actual_rc=$?
  set -e

  local ok=1
  if [ "$actual_rc" -ne "$expected_rc" ]; then
    echo "  expected exit $expected_rc, got $actual_rc"
    ok=0
  fi
  if [ -n "$expected_substr" ] && ! grep -qF "$expected_substr" "$out_file"; then
    echo "  expected output to contain: $expected_substr"
    ok=0
  fi

  if [ "$ok" -eq 1 ]; then
    PASS_COUNT=$((PASS_COUNT + 1))
    echo "  PASS"
  else
    FAIL_COUNT=$((FAIL_COUNT + 1))
    FAIL_NAMES+=("$name")
    echo "  --- output ---"
    sed 's/^/    /' "$out_file"
    echo "  --------------"
  fi
  rm -f "$out_file"
}

# AC: skip path never measures and exits 0.
run_case "skip path exits 0" 0 "skipping economy test timing" \
  SKIP_ECONOMY_TEST_TIMING=1 ECONOMY_TEST_TIMING_MEASURED_SECONDS=999

# AC: under ceiling => PASS, exit 0 (advisory default).
run_case "under ceiling passes" 0 "PASS: median 10" \
  ECONOMY_TEST_TIMING_MEASURED_SECONDS=10 ECONOMY_TEST_TIMING_CEILING_SECONDS=25

# AC: equal to ceiling is within budget even when enforcing.
run_case "equal to ceiling passes (enforce)" 0 "PASS: median 25" \
  ECONOMY_TEST_TIMING_MEASURED_SECONDS=25 ECONOMY_TEST_TIMING_CEILING_SECONDS=25 \
  ECONOMY_TEST_TIMING_ENFORCE=1

# AC: over ceiling, advisory => WARN, exit 0.
run_case "over ceiling advisory warns (exit 0)" 0 "WARN: median 40" \
  ECONOMY_TEST_TIMING_MEASURED_SECONDS=40 ECONOMY_TEST_TIMING_CEILING_SECONDS=25

# AC: over ceiling, enforce => FAIL, exit 1.
run_case "over ceiling enforce fails (exit 1)" 1 "FAIL: median 40" \
  ECONOMY_TEST_TIMING_MEASURED_SECONDS=40 ECONOMY_TEST_TIMING_CEILING_SECONDS=25 \
  ECONOMY_TEST_TIMING_ENFORCE=1

# AC: fractional median compares correctly (24.99 <= 25).
run_case "fractional under ceiling passes" 0 "PASS: median 24.99" \
  ECONOMY_TEST_TIMING_MEASURED_SECONDS=24.99 ECONOMY_TEST_TIMING_CEILING_SECONDS=25

# AC: invalid RUNS (even) is rejected with exit 2.
run_case "even runs rejected" 2 "must be an odd integer" \
  ECONOMY_TEST_TIMING_MEASURED_SECONDS=10 ECONOMY_TEST_TIMING_RUNS=2

# --- summary --------------------------------------------------------------
echo ""
echo "=========================================="
echo " check_economy_test_wall_clock: $PASS_COUNT pass, $FAIL_COUNT fail"
echo "=========================================="
if [ "$FAIL_COUNT" -gt 0 ]; then
  for n in "${FAIL_NAMES[@]}"; do
    echo "  FAIL: $n"
  done
  exit 1
fi
exit 0
