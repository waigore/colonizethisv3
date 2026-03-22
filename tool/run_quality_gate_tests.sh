#!/usr/bin/env bash
# Run the same test steps as .github/workflows/quality.yml (split steps, compact reporter).
# Use this to verify the quality gate locally before pushing. Requires: dart, flutter, lcov.
# See SPEC/program/test-logging.md and tool/test_coverage.py for scope.
set -e
export SUPPRESS_IMAGE_VIEWER=1
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "=== Resolve dependencies ==="
dart pub get

echo ""
echo "=== Check test import convention (SPEC/program/test-logging.md) ==="
tool/check_test_imports.sh

echo ""
echo "=== Test packages (Dart) ==="
for dir in packages/colonizethis_models packages/colonizethis_data packages/colonizethis_save packages/colonizethis_logic packages/colonizethis_ai packages/colonizethis_map; do
  [ -d "$dir/test" ] || continue
  (cd "$dir" && dart test --coverage=coverage -j 4 --reporter=compact)
  (cd "$dir" && dart run coverage:format_coverage --lcov -i coverage -o coverage/lcov.info --report-on=lib --package=.)
done

echo ""
echo "=== App localizations + analyze (before app tests; CI: app_tests_cache job) ==="
if [ -d app ]; then
  (cd app && flutter gen-l10n)
  cd app
  output=$(flutter analyze 2>&1 || true)
  echo "$output"
  error_count=$(echo "$output" | grep -c "^[[:space:]]*error" || true)
  cd "$ROOT"
  if [ "${error_count:-0}" -gt 0 ]; then
    echo "Errors found: $error_count"
    exit 1
  fi
fi

echo ""
echo "=== Test app (Flutter) ==="
# CI runs sharded app tests with a shared deps artifact (.github/workflows/quality.yml).
# Locally: single process is enough; use the same flags as shards for parity.
if [ -d app ]; then
  (cd app && flutter test --coverage --reporter=compact -j 1 --no-track-widget-creation)
  echo ""
  echo "=== App coverage gate (>= 80% for app/lib/) ==="
  "$ROOT/tool/check_coverage_threshold.sh" 80 app
fi

echo ""
echo "=== Test ctdev (Flutter) ==="
if [ -d ctdev/test ]; then
  (cd ctdev && flutter test --coverage --reporter=compact -j 1 --no-track-widget-creation)
fi

echo ""
echo "=== Test ctterm (Dart) ==="
if [ -d ctterm/test ]; then
  (cd ctterm && dart test --coverage=coverage -j 4 --reporter=compact)
  (cd ctterm && dart run coverage:format_coverage --lcov -i coverage -o coverage/lcov.info --report-on=lib --package=.)
fi

echo ""
echo "=== Test tool packages (Dart) ==="
for dir in tool/sim_scenarios tool/sim_combat_montecarlo tool/sim_combat tool/generate_map tool/init_game tool/sim_economy tool/show_tech; do
  [ -d "$dir/test" ] || continue
  (cd "$dir" && dart test --coverage=coverage -j 4 --reporter=compact)
  (cd "$dir" && dart run coverage:format_coverage --lcov -i coverage -o coverage/lcov.info --report-on=lib --package=.)
done

echo ""
echo "=== Coverage gate (logic/map/ai >= 90%) ==="
"$ROOT/tool/check_coverage_threshold.sh" 90 packages/colonizethis_logic packages/colonizethis_map packages/colonizethis_ai

echo ""
echo "=== sim_scenarios integration gate ==="
melos run sim_scenarios

echo ""
echo "All quality-gate steps passed."
