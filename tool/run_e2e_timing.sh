#!/usr/bin/env bash
# Linux desktop E2E wall-clock timing for GitHub #2336 (AC8 baseline / post-refactor).
# Requires: flutter linux desktop, CT_E2E, a display (or xvfb-run), and a linker
# that can build the Linux desktop bundle (snap Flutter often needs
# `sudo ln -sf /usr/lib/llvm-18/bin/ld.lld /snap/flutter/current/usr/lib/llvm-10/bin/ld.lld`).
# Usage from repo root:
#   tool/run_e2e_timing.sh [runs_per_test]
#   E2E_TIMING_OUT=./timing_logs tool/run_e2e_timing.sh 3
#   FLUTTER_BIN=~/development/flutter/bin/flutter tool/run_e2e_timing.sh 3
# Baseline checkout (e.g. git worktree) without copying this script:
#   CT_REPO_ROOT=/path/to/checkout tool/run_e2e_timing.sh 3
set -euo pipefail

ROOT="${CT_REPO_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
RUNS="${1:-3}"
OUT_DIR="${E2E_TIMING_OUT:-$ROOT/.cursor/e2e-timing}"
mkdir -p "$OUT_DIR"
# Absolutize before the later `cd "$ROOT/app"` so a relative E2E_TIMING_OUT
# (e.g. `./timing_logs`, as the header documents) still resolves when the
# summary and per-run logs are written from the app/ working directory.
OUT_DIR="$(cd "$OUT_DIR" && pwd)"

_snap_lld_path_for_flutter_root() {
  local flutter_root="$1"
  if [[ -z "$flutter_root" ]]; then
    return 1
  fi
  local snap_lld="${flutter_root}/usr/lib/llvm-10/bin/ld.lld"
  if [[ -d "$(dirname "$snap_lld" 2>/dev/null || echo)" ]]; then
    echo "$snap_lld"
    return 0
  fi
  return 1
}

_ensure_user_snap_ld_lld() {
  local snap_lld="$1"
  if [[ -x "$snap_lld" ]]; then
    return 0
  fi
  local llvm18="/usr/lib/llvm-18/bin/ld.lld"
  if [[ ! -x "$llvm18" ]]; then
    return 1
  fi
  mkdir -p "$(dirname "$snap_lld")"
  ln -sf "$llvm18" "$snap_lld" 2>/dev/null || return 1
  [[ -x "$snap_lld" ]]
}

# Snap Flutter links the Linux desktop bundle with the engine toolchain bundled
# inside the read-only snap mount (e.g.
# `/snap/flutter/current/usr/lib/llvm-10/bin/ld.lld`), NOT the writable SDK
# clone under `~/snap/flutter/common/flutter` that `flutter --version --machine`
# reports as `flutterRoot`. The SDK-clone check above can pass while the build
# still fails opaquely mid-link because flutter_tools searches the snap-bundled
# directory. Echo the snap-toolchain `ld.lld` path so preflight can check the
# location the build actually consults.
_snap_toolchain_lld() {
  local flutter_bin="$1"
  local flutter_root resolved
  flutter_root="$(_flutter_root "$flutter_bin")"
  resolved="$(readlink -f "$(command -v "$flutter_bin" 2>/dev/null || echo "$flutter_bin")" 2>/dev/null || true)"
  if [[ "$resolved" != /snap/* && "$flutter_root" != "${HOME}/snap/flutter"* && "$flutter_root" != /snap/* ]]; then
    return 1
  fi
  local dir="/snap/flutter/current/usr/lib/llvm-10/bin"
  if [[ ! -d "$dir" ]]; then
    return 1
  fi
  echo "${dir}/ld.lld"
}

_ensure_snap_toolchain_ld_lld() {
  local snap_lld="$1"
  local dir
  dir="$(dirname "$snap_lld")"
  # flutter_tools accepts either `ld.lld` or `ld` in this directory.
  if [[ -e "$snap_lld" || -e "${dir}/ld" ]]; then
    return 0
  fi
  local llvm18="/usr/lib/llvm-18/bin/ld.lld"
  if [[ ! -e "$llvm18" ]]; then
    return 1
  fi
  if ln -sf "$llvm18" "$snap_lld" 2>/dev/null && [[ -e "$snap_lld" ]]; then
    return 0
  fi
  if sudo -n true 2>/dev/null && sudo ln -sf "$llvm18" "$snap_lld" 2>/dev/null \
    && [[ -e "$snap_lld" ]]; then
    return 0
  fi
  return 1
}

_flutter_root() {
  local flutter_bin="$1"
  "$flutter_bin" --version --machine 2>/dev/null | python3 -c "import json,sys; print(json.load(sys.stdin).get('flutterRoot',''))" 2>/dev/null || true
}

_snap_flutter_missing_ld_lld() {
  local flutter_bin="$1"
  local flutter_root
  flutter_root="$(_flutter_root "$flutter_bin")"
  local snap_lld
  snap_lld="$(_snap_lld_path_for_flutter_root "$flutter_root")" || return 1
  [[ ! -x "$snap_lld" ]]
}

_resolve_flutter() {
  if [[ -n "${FLUTTER_BIN:-}" ]]; then
    echo "$FLUTTER_BIN"
    return
  fi
  local path_flutter
  path_flutter="$(command -v flutter 2>/dev/null || true)"
  local dev_flutter="${HOME}/development/flutter/bin/flutter"
  local candidates=()
  if [[ -x "$dev_flutter" ]]; then
    candidates+=("$dev_flutter")
  fi
  if [[ -n "$path_flutter" && "$path_flutter" != "$dev_flutter" ]]; then
    candidates+=("$path_flutter")
  fi
  for c in "${candidates[@]}"; do
    if _snap_flutter_missing_ld_lld "$c"; then
      continue
    fi
    echo "$c"
    return
  done
  if [[ -n "$path_flutter" && -x "$path_flutter" ]]; then
    echo "$path_flutter"
    return
  fi
  if [[ -x "$dev_flutter" ]]; then
    echo "$dev_flutter"
    return
  fi
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
    echo "ERROR: DISPLAY is unset and xvfb-run is not installed." >&2
    echo "  Linux desktop integration tests need a display." >&2
    echo "  Install once: sudo apt install xvfb" >&2
    echo "  Then re-run (script will wrap with xvfb-run -a when DISPLAY is unset)." >&2
    exit 1
  fi
  local flutter_root
  flutter_root="$(_flutter_root "$FLUTTER")"
  local snap_lld
  if snap_lld="$(_snap_lld_path_for_flutter_root "$flutter_root")"; then
    if [[ ! -x "$snap_lld" ]]; then
      if _ensure_user_snap_ld_lld "$snap_lld"; then
        echo "Linked ld.lld for snap Flutter at ${snap_lld}" >&2
      else
        echo "ERROR: Flutter expects ld.lld at ${snap_lld} but it is missing." >&2
        echo "  Fix (once, requires sudo): sudo ln -sf /usr/lib/llvm-18/bin/ld.lld ${snap_lld}" >&2
        echo "  Or set FLUTTER_BIN=~/development/flutter/bin/flutter (non-snap toolchain)." >&2
        exit 1
      fi
    fi
  fi
  local snap_toolchain_lld
  if snap_toolchain_lld="$(_snap_toolchain_lld "$FLUTTER")"; then
    if ! _ensure_snap_toolchain_ld_lld "$snap_toolchain_lld"; then
      echo "ERROR: snap Flutter links the Linux desktop bundle with ld.lld at" >&2
      echo "  ${snap_toolchain_lld}, but it is missing and the snap mount is read-only." >&2
      echo "  flutter_tools searches this snap-bundled toolchain dir during the link" >&2
      echo "  step; the writable SDK-clone flutterRoot is NOT consulted, so the build" >&2
      echo "  otherwise fails opaquely mid-link with 'Failed to find any of [ld.lld, ld]'." >&2
      echo "  Fix (once, requires sudo): sudo ln -sf /usr/lib/llvm-18/bin/ld.lld ${snap_toolchain_lld}" >&2
      echo "  Or set FLUTTER_BIN to a non-snap Flutter (e.g. FLUTTER_BIN=~/development/flutter/bin/flutter)." >&2
      exit 1
    fi
    echo "Verified snap Flutter toolchain ld.lld at ${snap_toolchain_lld}" >&2
  fi
  if [[ -z "${DISPLAY:-}" ]] && command -v xvfb-run >/dev/null; then
    echo "DISPLAY unset; tests will run under xvfb-run -a" >&2
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
