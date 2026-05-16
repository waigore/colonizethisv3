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
echo "=== Wang incremental assets gate (Python) ==="
if ! python3 -c "import PIL" 2>/dev/null; then
  python3 -m pip install -q pillow
fi
(cd pytool && python3 test_wang_incremental_assets_and_preview.py)

echo ""
echo "=== Test packages (Dart) ==="
for dir in packages/colonizethis_models packages/colonizethis_data packages/colonizethis_save packages/colonizethis_logic packages/colonizethis_ai packages/colonizethis_map; do
  [ -d "$dir/test" ] || continue
  (cd "$dir" && dart test --coverage=coverage -j 4 --reporter=compact)
  (cd "$dir" && dart run coverage:format_coverage --lcov -i coverage -o coverage/lcov.info --report-on=lib --package=.)
done

echo ""
echo "=== Workspace analyze (errors only; includes test/ + integration_test/; CI: quality job) ==="
dart run tool/run_workspace_analyze_errors_only.dart

echo ""
echo "=== App hardcoded UI string gate (AST, app/lib/** -> l10n) ==="
dart run "$ROOT/tool/check_app_hardcoded_ui_strings.dart"

echo ""
echo "=== Work target constants convention gate ==="
dart run "$ROOT/tool/check_work_target_constants.dart"

echo ""
echo "=== Test app (Flutter) ==="
# CI runs sharded app tests with a shared deps artifact (.github/workflows/quality.yml).
# Locally: single process is enough; use the same flags as shards for parity.
if [ -d app ]; then
  (cd app && flutter test test/ --coverage --reporter=compact -j 1 --no-track-widget-creation)
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
echo "=== Test tool packages (Dart) ==="
for dir in tool/sim_scenarios tool/sim_combat_montecarlo tool/sim_combat tool/generate_map tool/init_game tool/sim_economy tool/show_tech; do
  [ -d "$dir/test" ] || continue
  (cd "$dir" && dart test --coverage=coverage -j 4 --reporter=compact)
  (cd "$dir" && dart run coverage:format_coverage --lcov -i coverage -o coverage/lcov.info --report-on=lib --package=.)
done

echo ""
echo "=== Test run_observer_game (Dart, coverage) ==="
(cd tool/run_observer_game && dart test --coverage=coverage -j 4 --reporter=compact)
(cd tool/run_observer_game && dart run coverage:format_coverage --lcov -i coverage -o coverage/lcov.info --report-on=lib --package=.)

echo ""
echo "=== Coverage gate (run_observer_game lib >= 80%) ==="
"$ROOT/tool/check_coverage_threshold.sh" 80 tool/run_observer_game

echo ""
echo "=== Coverage gate (logic/map/ai >= 90%) ==="
"$ROOT/tool/check_coverage_threshold.sh" 90 packages/colonizethis_logic packages/colonizethis_map packages/colonizethis_ai

echo ""
echo "=== sim_scenarios integration gate ==="
melos run sim_scenarios

echo ""
echo "All quality-gate steps passed."
