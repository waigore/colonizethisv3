#!/usr/bin/env bash
# Compare two run_e2e_timing.sh summary markdown files (baseline vs PR) for #2336 AC8–AC9.
# Usage from repo root:
#   tool/compare_e2e_timing.sh .cursor/e2e-timing/summary_baseline.md .cursor/e2e-timing/summary_after.md
#   tool/compare_e2e_timing.sh baseline.md after.md --min-reduction-pct 25
set -euo pipefail

if [[ $# -lt 2 ]]; then
  echo "Usage: $0 <baseline_summary.md> <after_summary.md> [--min-reduction-pct N]" >&2
  exit 1
fi

BASELINE="$1"
AFTER="$2"
shift 2
MIN_REDUCTION_PCT=25
while [[ $# -gt 0 ]]; do
  case "$1" in
    --min-reduction-pct)
      MIN_REDUCTION_PCT="${2:?}"
      shift 2
      ;;
    *)
      echo "Unknown option: $1" >&2
      exit 1
      ;;
  esac
done

for f in "$BASELINE" "$AFTER"; do
  if [[ ! -f "$f" ]]; then
    echo "ERROR: not a file: $f" >&2
    exit 1
  fi
done

python3 - <<PY
import re
import statistics
import sys
from pathlib import Path

baseline_path = Path("$BASELINE")
after_path = Path("$AFTER")
min_reduction_pct = float("$MIN_REDUCTION_PCT")


def parse_medians(path: Path) -> dict[str, float]:
    text = path.read_text()
    medians: dict[str, float] = {}
    current: str | None = None
    for line in text.splitlines():
        m = re.match(r"^### (.+)$", line)
        if m:
            current = m.group(1).strip()
            continue
        m = re.match(r"^- median: ([0-9.]+)s$", line)
        if m and current:
            medians[current] = float(m.group(1))
    return medians


def aggregate(medians: dict[str, float]) -> float:
    return sum(medians.values())


baseline = parse_medians(baseline_path)
after = parse_medians(after_path)
tests = sorted(set(baseline) | set(after))
if not tests:
    print("ERROR: no per-test medians found (expected '### <test>' and '- median: N.NNs')", file=sys.stderr)
    sys.exit(1)

missing_b = sorted(set(tests) - set(baseline))
missing_a = sorted(set(tests) - set(after))
if missing_b or missing_a:
    if missing_b:
        print(f"WARN: missing in baseline: {missing_b}", file=sys.stderr)
    if missing_a:
        print(f"WARN: missing in after: {missing_a}", file=sys.stderr)

base_total = aggregate(baseline)
after_total = aggregate(after)
if base_total <= 0:
    print("ERROR: baseline aggregate median total is zero", file=sys.stderr)
    sys.exit(1)

suite_delta_pct = (base_total - after_total) / base_total * 100.0
ac9_pass = suite_delta_pct >= min_reduction_pct

print("# E2E timing comparison (Refs #2336 AC8–AC9)")
print()
print(f"- Baseline: `{baseline_path}`")
print(f"- After: `{after_path}`")
print()
print("| Test | Baseline median (s) | After median (s) | Delta % |")
print("|------|---------------------|------------------|---------|")
for test in tests:
    b = baseline.get(test)
    a = after.get(test)
    if b is None or a is None:
        print(f"| {test} | {b or '—'} | {a or '—'} | — |")
        continue
    delta = (b - a) / b * 100.0 if b > 0 else 0.0
    print(f"| {test} | {b:.2f} | {a:.2f} | {delta:+.1f}% |")

print()
print("## Aggregate (sum of per-test medians)")
print()
print(f"| | Baseline | After | Delta % |")
print(f"|--|----------|-------|---------|")
print(f"| Suite total | {base_total:.2f}s | {after_total:.2f}s | {suite_delta_pct:+.1f}% |")
print()
print(f"**AC9 ({min_reduction_pct:.0f}% aggregate reduction):** {'PASS' if ac9_pass else 'FAIL'} "
      f"({suite_delta_pct:+.1f}% vs required ≥{min_reduction_pct:.0f}%)")
PY
