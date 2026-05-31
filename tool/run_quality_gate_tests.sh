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
echo "=== Package tests (colonizethis; CI: package_tests job) ==="
PACKAGE_TEST_MAX_JOBS=4 PACKAGE_TEST_CONCURRENCY=4 tool/run_package_tests.sh

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
echo "=== Test run_observer_game (Dart, coverage) ==="
(cd tool/run_observer_game && dart test --coverage=coverage -j 4 --reporter=compact)
(cd tool/run_observer_game && dart run coverage:format_coverage --lcov -i coverage -o coverage/lcov.info --report-on=lib --package=.)

echo ""
echo "=== Coverage gate (run_observer_game lib >= 80%) ==="
"$ROOT/tool/check_coverage_threshold.sh" 80 tool/run_observer_game

echo ""
echo "=== Nightly-only gates (skipped) ==="
echo "Tool package tests + sim_scenarios: run tool/run_nightly_gate_tests.sh"
echo "(CI: .github/workflows/nightly.yml at 23:00 Asia/Hong_Kong)"

echo ""
echo "All quality-gate steps passed."
