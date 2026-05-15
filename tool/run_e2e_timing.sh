#!/usr/bin/env bash
# Linux desktop E2E wall-clock timing for GitHub #2336 (AC8 baseline / post-refactor).
# Requires: flutter linux desktop, CT_E2E, a display (or xvfb-run), and a linker
# that can build the Linux desktop bundle (snap Flutter often needs
# `sudo ln -sf /usr/lib/llvm-18/bin/ld.lld /snap/flutter/current/usr/lib/llvm-10/bin/ld.lld`).
# Usage from repo root:
#   tool/run_e2e_timing.sh [runs_per_test]
#   E2E_TIMING_OUT=./timing_logs tool/run_e2e_timing.sh 3
#   FLUTTER_BIN=~/development/flutter/bin/flutter tool/run_e2e_timing.sh 3
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
RUNS="${1:-3}"
OUT_DIR="${E2E_TIMING_OUT:-$ROOT/.cursor/e2e-timing}"
mkdir -p "$OUT_DIR"

_resolve_flutter() {
  if [[ -n "${FLUTTER_BIN:-}" ]]; then
    echo "$FLUTTER_BIN"
    return
  fi
  local candidates=(
    "$HOME/development/flutter/bin/flutter"
    "$(command -v flutter 2>/dev/null || true)"
  )
  for c in "${candidates[@]}"; do
    if [[ -n "$c" && -x "$c" ]]; then
      echo "$c"
      return
    fi
  done
  echo "flutter" >&2
}

FLUTTER="$(_resolve_flutter)"

_preflight_e2e_host() {
  echo "Using Flutter: $FLUTTER ($("$FLUTTER" --version 2>/dev/null | head -1))"
  if ! "$FLUTTER" config --list 2>/dev/null | grep -q 'enable-linux-desktop: true'; then
    echo "Enabling linux desktop..." >&2
    "$FLUTTER" config --enable-linux-desktop >/dev/null
  fi
  if [[ -z "${DISPLAY:-}" ]] && ! command -v xvfb-run >/dev/null; then
    echo "WARNING: DISPLAY is unset and xvfb-run is not installed." >&2
    echo "  Integration tests need a graphical session or: sudo apt install xvfb" >&2
    echo "  Then re-run with: xvfb-run -a tool/run_e2e_timing.sh ${RUNS}" >&2
  fi
  local flutter_root
  flutter_root="$("$FLUTTER" --version --machine 2>/dev/null | python3 -c "import json,sys; print(json.load(sys.stdin).get('flutterRoot',''))" 2>/dev/null || true)"
  if [[ -n "$flutter_root" ]]; then
    local snap_lld="${flutter_root}/usr/lib/llvm-10/bin/ld.lld"
    if [[ -d "$(dirname "$snap_lld" 2>/dev/null || echo)" ]] && [[ ! -x "$snap_lld" ]]; then
      echo "WARNING: Flutter expects ld.lld at ${snap_lld} but it is missing." >&2
      echo "  Fix (once, requires sudo): sudo ln -sf /usr/lib/llvm-18/bin/ld.lld ${snap_lld}" >&2
      echo "  Or set FLUTTER_BIN to a non-snap Flutter install that bundles its toolchain." >&2
    fi
  fi
}

_preflight_e2e_host

TESTS=(
  "integration_test/new_game_full_turn_e2e_test.dart"
  "integration_test/new_game_capital_panel_e2e_test.dart"
  "integration_test/new_game_fleet_reaches_new_world_e2e_test.dart"
)

cd "$ROOT/app"

stamp="$(date -u +%Y%m%dT%H%M%SZ)"
summary="$OUT_DIR/summary_${stamp}.md"
{
  echo "# E2E timing run ${stamp}"
  echo ""
  echo "Branch: \`$(git -C "$ROOT" rev-parse --abbrev-ref HEAD)\` @ \`$(git -C "$ROOT" rev-parse --short HEAD)\`"
  echo "Runs per test: ${RUNS}"
  echo ""
  echo "| Test | Run | Wall (s) | Pass | Log |"
  echo "|------|-----|----------|------|-----|"
} >"$summary"

for test_path in "${TESTS[@]}"; do
  base="$(basename "$test_path" .dart)"
  echo "=== ${base} (${RUNS} runs) ==="
  times=()
  for ((i = 1; i <= RUNS; i++)); do
    log="$OUT_DIR/${base}_run${i}_${stamp}.log"
    echo "--- run ${i}/${RUNS} -> ${log}"
    set +e
    start=$(date +%s.%N)
    if command -v xvfb-run >/dev/null && [[ -z "${DISPLAY:-}" ]]; then
      run_cmd=(xvfb-run -a "$FLUTTER" test "$test_path" -d linux --dart-define=CT_E2E=true)
    else
      run_cmd=("$FLUTTER" test "$test_path" -d linux --dart-define=CT_E2E=true)
    fi
    /usr/bin/time -f 'WALL_SECONDS %e' "${run_cmd[@]}" >"$log" 2>&1
    status=$?
    set -e
    end=$(date +%s.%N)
    wall="$(python3 - <<PY
start, end = float("$start"), float("$end")
print(f"{end - start:.2f}")
PY
)"
    if grep -q '^WALL_SECONDS ' "$log"; then
      wall="$(grep '^WALL_SECONDS ' "$log" | tail -1 | awk '{print $2}')"
    fi
    times+=("$wall")
    pass="no"
    if [[ $status -eq 0 ]] && grep -q 'All tests passed!' "$log"; then
      pass="yes"
    fi
    echo "| ${base} | ${i} | ${wall} | ${pass} | \`${log#$ROOT/}\` |" >>"$summary"
    if [[ "$pass" != "yes" ]]; then
      echo "FAILED (exit ${status}); see ${log}" >&2
    fi
  done

  times_csv="$(IFS=,; echo "${times[*]}")"
  python3 - <<PY >>"$summary"
import statistics

times = [float(x) for x in "${times_csv}".split(",")]
base = "${base}"
print()
print(f"### {base}")
print(f"- min: {min(times):.2f}s")
print(f"- median: {statistics.median(times):.2f}s")
print(f"- max: {max(times):.2f}s")
PY
done

SUMMARY_PATH="$summary" python3 - <<'PY' >>"$summary"
import os
import re
from pathlib import Path

text = Path(os.environ["SUMMARY_PATH"]).read_text()
medians = [
    float(m.group(1))
    for m in re.finditer(r"^- median: ([0-9.]+)s$", text, re.M)
]
if medians:
    total = sum(medians)
    print()
    print("## Aggregate (sum of per-test medians)")
    print(f"- **{total:.2f}s** ({len(medians)} tests)")
PY

echo ""
echo "Wrote ${summary}"
echo "Paste per-test medians and sum of medians into the PR table (Refs #2336 AC8)."
