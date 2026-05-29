#!/usr/bin/env bash
# Run colonizethis workspace package unit tests + coverage gates (CI: package_tests job).
#
# Supports selective execution via PACKAGES_TO_TEST (comma-separated, e.g.
# "colonizethis_logic,colonizethis_ai").  When unset all six core packages run.
#
# Heavy packages are sharded: colonizethis_logic → 4 shards, colonizethis_ai → 2 shards.
# All shards run in parallel, throttled by PACKAGE_TEST_MAX_JOBS (default 6).
#
# Requires: dart, lcov.  Coverage gates only check packages that were actually tested.
set -euo pipefail

export SUPPRESS_IMAGE_VIEWER="${SUPPRESS_IMAGE_VIEWER:-1}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

ALL_PKGS=(colonizethis_models colonizethis_data colonizethis_save colonizethis_map colonizethis_logic colonizethis_ai)

# ---- read package filter ---------------------------------------------------
if [ -n "${PACKAGES_TO_TEST:-}" ]; then
  IFS=',' read -ra PKGS <<< "$PACKAGES_TO_TEST"
else
  PKGS=("${ALL_PKGS[@]}")
fi

MAX_JOBS="${PACKAGE_TEST_MAX_JOBS:-6}"

# ---- shard configuration (only colonizethis_*-prefixed keys) ----------------
declare -A SHARD_COUNT=(
  [colonizethis_models]=1
  [colonizethis_data]=1
  [colonizethis_save]=1
  [colonizethis_map]=1
  [colonizethis_logic]=4
  [colonizethis_ai]=2
)

# ---- collect tasks ----------------------------------------------------------
tasks=()
for short in "${PKGS[@]}"; do
  pkg_dir="packages/$short"
  [ -d "$pkg_dir/test" ] || continue
  total="${SHARD_COUNT[$short]:-1}"
  for ((s = 0; s < total; s++)); do
    tasks+=("$pkg_dir|$s|$total")
  done
done

echo "=== Running ${#tasks[@]} test shards across ${#PKGS[@]} packages ==="
echo ""

# ---- run all tasks in parallel (throttled) ----------------------------------
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

task_idx=0
declare -a bg_pids=()

for task in "${tasks[@]}"; do
  IFS='|' read -r pkg_dir shard total <<< "$task"

  echo "  [$task_idx] $pkg_dir (shard $shard/$total)"

  (
    cd "$ROOT/$pkg_dir"
    cov_dir="coverage.shard$shard"
    rm -rf "$cov_dir"
    # Disable -e while running the test so a non-zero dart-test exit still
    # falls through to the rc.* write below; otherwise the parent never sees
    # the failure (rc.* missing => failure-check loop silently passes).
    set +e
    dart test --coverage="$cov_dir" -j 1 --reporter=compact \
      --total-shards="$total" --shard-index="$shard" \
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
  echo "FAILED: one or more package test shards failed (check output above)."
  exit 1
fi

echo ""
echo "=== All package tests passed ==="

# ---- build per-package coverage (format + merge shards) ---------------------
for short in "${PKGS[@]}"; do
  pkg_dir="packages/$short"
  [ -d "$pkg_dir/test" ] || continue
  total="${SHARD_COUNT[$short]:-1}"

  echo ""
  echo "=== Coverage: $pkg_dir ==="

  shard_infos=()
  for ((s = 0; s < total; s++)); do
    cov_dir="$ROOT/$pkg_dir/coverage.shard$s"
    if [ -d "$cov_dir" ]; then
      shard_info="$ROOT/$pkg_dir/coverage/lcov.shard$s.info"
      (cd "$pkg_dir" && dart run coverage:format_coverage --lcov \
        -i "coverage.shard$s" -o "coverage/lcov.shard$s.info" \
        --report-on=lib --package=.)
      shard_infos+=("$shard_info")
    fi
  done

  if [ "${#shard_infos[@]}" -gt 1 ]; then
    merged="$ROOT/$pkg_dir/coverage/lcov.info"
    lcov_args=()
    for info in "${shard_infos[@]}"; do
      lcov_args+=(-a "$info")
    done
    lcov "${lcov_args[@]}" -o "$merged"
    echo "  Merged ${#shard_infos[@]} shards → coverage/lcov.info"
  elif [ "${#shard_infos[@]}" -eq 1 ]; then
    cp "${shard_infos[0]}" "$ROOT/$pkg_dir/coverage/lcov.info"
    echo "  Single shard, copied to coverage/lcov.info"
  fi
done

# ---- coverage gates (only packages that were tested) ------------------------
echo ""

gate_pkgs=()
for pkg in colonizethis_logic colonizethis_map colonizethis_ai; do
  if printf '%s\n' "${PKGS[@]}" | grep -qxF "$pkg"; then
    gate_pkgs+=("packages/$pkg")
  fi
done
if [ ${#gate_pkgs[@]} -gt 0 ]; then
  echo "=== Coverage gate (logic/map/ai >= 90%) ==="
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
