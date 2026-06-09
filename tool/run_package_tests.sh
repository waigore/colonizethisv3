#!/usr/bin/env bash
# Run colonizethis workspace package unit tests + coverage gates (CI: package_tests job).
#
# Supports selective execution via PACKAGES_TO_TEST (comma-separated, e.g.
# "colonizethis_logic,colonizethis_ai").  When unset all six core packages run.
#
# One `dart test` process per package (no intra-package sharding). Packages run
# in parallel, throttled by PACKAGE_TEST_MAX_JOBS (default 6). Intra-package
# concurrency uses PACKAGE_TEST_CONCURRENCY (default 4, passed to dart test -j).
#
# Requires: dart, lcov.  Coverage gates only check packages that were actually tested.
set -euo pipefail

export SUPPRESS_IMAGE_VIEWER="${SUPPRESS_IMAGE_VIEWER:-1}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

ALL_PKGS=(colonizethis_models colonizethis_data colonizethis_save colonizethis_map colonizethis_world colonizethis_combat colonizethis_economy colonizethis_diplomacy colonizethis_setup colonizethis_orders colonizethis_turn colonizethis_ai_contracts colonizethis_logic colonizethis_ai)

# ---- read package filter ---------------------------------------------------
if [ -n "${PACKAGES_TO_TEST:-}" ]; then
  IFS=',' read -ra PKGS <<< "$PACKAGES_TO_TEST"
else
  PKGS=("${ALL_PKGS[@]}")
fi

MAX_JOBS="${PACKAGE_TEST_MAX_JOBS:-6}"
TEST_CONCURRENCY="${PACKAGE_TEST_CONCURRENCY:-4}"

# ---- collect tasks (one per package) ---------------------------------------
tasks=()
for short in "${PKGS[@]}"; do
  pkg_dir="packages/$short"
  [ -d "$pkg_dir/test" ] || continue
  tasks+=("$pkg_dir")
done

echo "=== Running ${#tasks[@]} package test jobs across ${#PKGS[@]} packages (-j ${TEST_CONCURRENCY}) ==="
echo ""

# ---- run all tasks in parallel (throttled) ----------------------------------
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

task_idx=0
declare -a bg_pids=()

for pkg_dir in "${tasks[@]}"; do
  echo "  [$task_idx] $pkg_dir"

  (
    cd "$ROOT/$pkg_dir"
    rm -rf coverage
    # Disable -e while running the test so a non-zero dart-test exit still
    # falls through to the rc.* write below; otherwise the parent never sees
    # the failure (rc.* missing => failure-check loop silently passes).
    set +e
    dart test --coverage=coverage -j "$TEST_CONCURRENCY" --reporter=compact \
      --test-randomize-ordering-seed=42
    rc=$?
    set -e
    echo "$rc" > "$tmpdir/rc.$task_idx"
    exit "$rc"
  ) &
  bg_pids+=($!)
  # Use $((...)) assignment instead of ((task_idx++)). Under `set -e`,
  # `((expr))` returns exit status 1 whenever expr evaluates to 0, and
  # post-increment yields the PRE-increment value, so `((task_idx++))` exits
  # the script on the very first iteration when task_idx is still 0.
  task_idx=$((task_idx + 1))

  # throttle
  if [ ${#bg_pids[@]} -ge "$MAX_JOBS" ]; then
    wait -n 2>/dev/null || true
    new_pids=()
    for pid in "${bg_pids[@]}"; do
      if kill -0 "$pid" 2>/dev/null; then
        new_pids+=("$pid")
      fi
    done
    bg_pids=("${new_pids[@]}")
  fi
done

# drain remaining
for pid in "${bg_pids[@]}"; do
  wait "$pid" || true
done

# ---- check failures ---------------------------------------------------------
failed=0
for f in "$tmpdir"/rc.*; do
  [ -f "$f" ] || continue
  rc=$(cat "$f")
  if [ "$rc" != "0" ]; then
    failed=1
  fi
done

if [ "$failed" -ne 0 ]; then
  echo ""
  echo "FAILED: one or more package tests failed (check output above)."
  exit 1
fi

echo ""
echo "=== All package tests passed ==="

# ---- build per-package coverage ---------------------------------------------
for short in "${PKGS[@]}"; do
  pkg_dir="packages/$short"
  [ -d "$pkg_dir/test" ] || continue

  echo ""
  echo "=== Coverage: $pkg_dir ==="

  if [ -d "$ROOT/$pkg_dir/coverage" ]; then
    (cd "$pkg_dir" && dart run coverage:format_coverage --lcov \
      -i coverage -o coverage/lcov.info \
      --report-on=lib --package=.)
    echo "  Formatted coverage/lcov.info"
  fi
done

# ---- coverage gates (only packages that were tested) ------------------------
echo ""

gate_pkgs=()
for pkg in colonizethis_logic colonizethis_map colonizethis_ai colonizethis_ai_contracts colonizethis_combat colonizethis_economy colonizethis_diplomacy colonizethis_setup colonizethis_orders colonizethis_turn; do
  if printf '%s\n' "${PKGS[@]}" | grep -qxF "$pkg"; then
    gate_pkgs+=("packages/$pkg")
  fi
done
if [ ${#gate_pkgs[@]} -gt 0 ]; then
  echo "=== Coverage gate (logic/map/ai + split domain packages >= 90%; world deferred) ==="
  "$ROOT/tool/check_coverage_threshold.sh" 90 "${gate_pkgs[@]}"
fi

gate_pkgs=()
for pkg in colonizethis_data; do
  if printf '%s\n' "${PKGS[@]}" | grep -qxF "$pkg"; then
    gate_pkgs+=("packages/$pkg")
  fi
done
if [ ${#gate_pkgs[@]} -gt 0 ]; then
  echo ""
  echo "=== Coverage gate (data >= 80%) ==="
  "$ROOT/tool/check_coverage_threshold.sh" 80 "${gate_pkgs[@]}"
fi

echo "Package tests and coverage gates passed."
