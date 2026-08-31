#!/usr/bin/env bash
# Profile/release open-to-interactive evidence for game-app UI surfaces (Refs #4687, #4688).
#
# Captures `ui_surface_open surface=<id> elapsed_ms=… budget_ms=1000 host=…` lines
# from `flutter drive --profile` for PR wall-clock evidence on binding hosts.
#
# Usage from repo root:
#   tool/run_ui_surface_profile_evidence.sh trade
#   tool/run_ui_surface_profile_evidence.sh all-empire-rail --host linux
#   tool/run_ui_surface_profile_evidence.sh development --host android --device emulator-5554
#   UI_SURFACE_PROFILE_OUT=tmp/profile-evidence tool/run_ui_surface_profile_evidence.sh trade
#
# Linux desktop (headless): uses xvfb-run when DISPLAY is unset.
# Android emulator: launch an AVD first (`flutter emulators --launch <name>`), then pass
# `--host android --device <id>` from `flutter devices`.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SURFACE="${1:-development}"
shift || true

HOST="auto"
DEVICE=""
OUT_DIR="${UI_SURFACE_PROFILE_OUT:-$ROOT/tmp/ui-surface-profile-evidence}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --host)
      HOST="${2:?--host requires linux|android|auto}"
      shift 2
      ;;
    --device)
      DEVICE="${2:?--device requires a flutter device id}"
      shift 2
      ;;
    -h | --help)
      sed -n '1,22p' "$0"
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 2
      ;;
  esac
done

_surface_target() {
  case "$1" in
    development)
      echo "integration_test/development_panel_surface_open_profile_test.dart"
      ;;
    trade)
      echo "integration_test/trade_panel_surface_open_profile_test.dart"
      ;;
    production)
      echo "integration_test/production_panel_surface_open_profile_test.dart"
      ;;
    technology)
      echo "integration_test/technology_panel_surface_open_profile_test.dart"
      ;;
    diplomacy)
      echo "integration_test/diplomacy_panel_surface_open_profile_test.dart"
      ;;
    victory)
      echo "integration_test/victory_panel_surface_open_profile_test.dart"
      ;;
    counsel)
      echo "integration_test/counsel_panel_surface_open_profile_test.dart"
      ;;
    units)
      echo "integration_test/units_panels_surface_open_profile_test.dart"
      ;;
    *)
      return 1
      ;;
  esac
}

ALL_EMPIRE_RAIL_SURFACES=(
  trade
  production
  technology
  diplomacy
  victory
  counsel
  units
)

_resolve_flutter() {
  if [[ -n "${FLUTTER_BIN:-}" ]]; then
    echo "$FLUTTER_BIN"
    return
  fi
  command -v flutter 2>/dev/null || echo "flutter"
}

FLUTTER="$(_resolve_flutter)"

# Device id is the field between the first and second bullet on `flutter devices`
# lines (e.g. `sdk gphone64 x86 64 (mobile) • emulator-5554 • android-x64`).
# Do not use a fixed $N token — multi-word emulator names break that parse.
_resolve_android_device_id() {
  "$FLUTTER" devices 2>/dev/null | awk -F'•' '/android/ {
    gsub(/^[ \t]+|[ \t]+$/, "", $2)
    if ($2 != "") { print $2; exit }
  }'
}

_resolve_device() {
  if [[ -n "$DEVICE" ]]; then
    echo "$DEVICE"
    return
  fi
  case "$HOST" in
    linux)
      echo "linux"
      ;;
    android)
      local id
      id="$(_resolve_android_device_id)"
      if [[ -z "$id" ]]; then
        echo "ERROR: no Android device/emulator found. Launch one:" >&2
        echo "  flutter emulators --launch <avd_name>" >&2
        echo "  flutter devices" >&2
        exit 1
      fi
      echo "$id"
      ;;
    auto)
      if "$FLUTTER" devices 2>/dev/null | grep -q '• android'; then
        _resolve_android_device_id
      else
        echo "linux"
      fi
      ;;
    *)
      echo "Invalid --host: $HOST (use linux, android, or auto)" >&2
      exit 2
      ;;
  esac
}

_run_surface() {
  local surface="$1"
  local target
  target="$(_surface_target "$surface")" || {
    echo "Unsupported surface: $surface" >&2
    exit 2
  }

  local device_id="$(_resolve_device)"
  mkdir -p "$OUT_DIR"
  local stamp
  stamp="$(date -u +%Y%m%dT%H%M%SZ)"
  local log="$OUT_DIR/${surface}_${device_id}_${stamp}.log"

  cd "$ROOT/app"
  "$FLUTTER" pub get >/dev/null

  local -a runner
  if [[ "$device_id" == "linux" ]]; then
    "$FLUTTER" config --enable-linux-desktop >/dev/null 2>&1 || true
    if [[ -z "${DISPLAY:-}" ]] && command -v xvfb-run >/dev/null; then
      runner=(xvfb-run -a "$FLUTTER")
    else
      runner=("$FLUTTER")
    fi
  else
    runner=("$FLUTTER")
  fi

  echo "Running profile drive: surface=$surface device=$device_id log=$log"
  set +e
  "${runner[@]}" drive \
    --driver=test_driver/integration_test.dart \
    --target="$target" \
    --profile \
    -d "$device_id" \
    --no-pub >"$log" 2>&1
  local status=$?
  set -e

  echo ""
  echo "=== ui_surface_open lines ($surface) ==="
  grep -E 'ui_surface_open surface=' "$log" || true

  if [[ $status -ne 0 ]]; then
    echo "ERROR: flutter drive failed for $surface (exit $status). See $log" >&2
    exit "$status"
  fi

  if ! grep -q 'All tests passed' "$log"; then
    echo "ERROR: drive did not report All tests passed for $surface. See $log" >&2
    exit 1
  fi

  export UI_SURFACE_PROFILE_LOG="$log"
  export UI_SURFACE_PROFILE_SURFACE="$surface"
  python3 - <<'PY'
import os
import re
import sys
from pathlib import Path

surface = os.environ["UI_SURFACE_PROFILE_SURFACE"]
log = Path(os.environ["UI_SURFACE_PROFILE_LOG"]).read_text()
lines = [m.group(0) for m in re.finditer(r"ui_surface_open surface=\S+[^\n]*", log)]
if not lines:
    print(f"ERROR: no ui_surface_open lines in log for {surface}", file=sys.stderr)
    sys.exit(1)

budget = 1000
violations = []
for line in lines:
    m = re.search(r"elapsed_ms=(\d+)", line)
    if m and int(m.group(1)) > budget:
        violations.append(line)

if violations:
    print(f"ERROR: open-to-interactive exceeded budget for {surface}:", file=sys.stderr)
    for v in violations:
        print(f"  {v}", file=sys.stderr)
    sys.exit(1)

print("")
print(f"Evidence summary — {surface} (paste into PR / issue comment):")
print("")
print("| Scenario | ui_surface_open line |")
print("|----------|----------------------|")
for i, line in enumerate(lines):
    label = "cold open" if i == 0 else f"warm re-open {i}"
    print(f"| {label} | `{line}` |")
PY

  echo ""
  echo "Wrote full log: $log"
}

if [[ "$SURFACE" == "all-empire-rail" ]]; then
  for s in "${ALL_EMPIRE_RAIL_SURFACES[@]}"; do
    _run_surface "$s"
    echo ""
    echo "---"
    echo ""
  done
  exit 0
fi

_run_surface "$SURFACE"
