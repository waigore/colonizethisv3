#!/usr/bin/env bash
# Profile/release open-to-interactive evidence for game-app UI surfaces (Refs #4687, #4690).
#
# Captures `ui_surface_open surface=<id> elapsed_ms=… budget_ms=1000 host=…` lines
# from `flutter drive --profile` for PR wall-clock evidence on binding hosts.
#
# Usage from repo root:
#   tool/run_ui_surface_profile_evidence.sh development
#   tool/run_ui_surface_profile_evidence.sh provinceOverlay
#   tool/run_ui_surface_profile_evidence.sh development --host linux
#   tool/run_ui_surface_profile_evidence.sh provinceOverlay --host android --device emulator-5554
#   UI_SURFACE_PROFILE_OUT=tmp/profile-evidence tool/run_ui_surface_profile_evidence.sh provinceOverlay
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
      sed -n '1,20p' "$0"
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 2
      ;;
  esac
done

case "$SURFACE" in
  development)
    TARGET="integration_test/development_panel_surface_open_profile_test.dart"
    EXPECTED_HOST_LINUX="linux_desktop_profile"
    EXPECTED_HOST_ANDROID="android_emulator_profile"
    ;;
  provinceOverlay)
    TARGET="integration_test/province_overlay_surface_open_profile_test.dart"
    EXPECTED_HOST_LINUX="linux_desktop_profile"
    EXPECTED_HOST_ANDROID="android_emulator_profile"
    ;;
  *)
    echo "Unsupported surface: $SURFACE (supported: development, provinceOverlay)" >&2
    exit 2
    ;;
esac

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

DEVICE_ID="$(_resolve_device)"
mkdir -p "$OUT_DIR"
stamp="$(date -u +%Y%m%dT%H%M%SZ)"
log="$OUT_DIR/${SURFACE}_${DEVICE_ID}_${stamp}.log"

cd "$ROOT/app"
"$FLUTTER" pub get >/dev/null

if [[ "$DEVICE_ID" == "linux" ]]; then
  "$FLUTTER" config --enable-linux-desktop >/dev/null 2>&1 || true
  if [[ -z "${DISPLAY:-}" ]] && command -v xvfb-run >/dev/null; then
    RUNNER=(xvfb-run -a "$FLUTTER")
  else
    RUNNER=("$FLUTTER")
  fi
else
  RUNNER=("$FLUTTER")
fi

echo "Running profile drive: surface=$SURFACE device=$DEVICE_ID log=$log"
set +e
"${RUNNER[@]}" drive \
  --driver=test_driver/integration_test.dart \
  --target="$TARGET" \
  --profile \
  -d "$DEVICE_ID" \
  --no-pub >"$log" 2>&1
status=$?
set -e

echo ""
echo "=== ui_surface_open lines ==="
grep -E 'ui_surface_open surface=' "$log" || true

if [[ $status -ne 0 ]]; then
  echo "ERROR: flutter drive failed (exit $status). See $log" >&2
  exit "$status"
fi

if ! grep -q 'All tests passed' "$log"; then
  echo "ERROR: drive did not report All tests passed. See $log" >&2
  exit 1
fi

export UI_SURFACE_PROFILE_LOG="$log"
python3 - <<'PY'
import os
import re
import sys
from pathlib import Path

log = Path(os.environ["UI_SURFACE_PROFILE_LOG"]).read_text()
lines = [m.group(0) for m in re.finditer(r"ui_surface_open surface=\S+[^\n]*", log)]
if not lines:
    print("ERROR: no ui_surface_open lines in log", file=sys.stderr)
    sys.exit(1)

budget = 1000
violations = []
for line in lines:
    m = re.search(r"elapsed_ms=(\d+)", line)
    if m and int(m.group(1)) > budget:
        violations.append(line)

if violations:
    print("ERROR: open-to-interactive exceeded budget:", file=sys.stderr)
    for v in violations:
        print(f"  {v}", file=sys.stderr)
    sys.exit(1)

print("")
print("Evidence summary (paste into PR / issue comment):")
print("")
print("| Scenario | ui_surface_open line |")
print("|----------|----------------------|")
for i, line in enumerate(lines):
    label = "cold open" if i == 0 else f"warm re-open {i}"
    print(f"| {label} | `{line}` |")
PY

echo ""
echo "Wrote full log: $log"
