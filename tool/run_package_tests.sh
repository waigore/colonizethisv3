#!/usr/bin/env bash
# Run colonizethis workspace package unit tests + coverage gates (CI: package_tests job).
# Same scope as the former quality.yml package steps. Requires: dart, lcov.
set -euo pipefail
export SUPPRESS_IMAGE_VIEWER="${SUPPRESS_IMAGE_VIEWER:-1}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

PARALLEL="${PACKAGE_TEST_JOBS:-2}"

for dir in \
  packages/colonizethis_models \
  packages/colonizethis_data \
  packages/colonizethis_save \
  packages/colonizethis_logic \
  packages/colonizethis_ai \
  packages/colonizethis_map; do
  [ -d "$dir/test" ] || continue
  echo "=== Test $dir (Dart) ==="
  (cd "$dir" && dart test --coverage=coverage -j "$PARALLEL" --reporter=compact)
  (cd "$dir" && dart run coverage:format_coverage --lcov -i coverage -o coverage/lcov.info --report-on=lib --package=.)
done

echo ""
echo "=== Coverage gate (logic/map/ai >= 90%) ==="
"$ROOT/tool/check_coverage_threshold.sh" 90 \
  packages/colonizethis_logic \
  packages/colonizethis_map \
  packages/colonizethis_ai

echo ""
echo "=== Coverage gate (data >= 80%) ==="
"$ROOT/tool/check_coverage_threshold.sh" 80 packages/colonizethis_data

echo "Package tests and coverage gates passed."
