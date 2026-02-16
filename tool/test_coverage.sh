#!/usr/bin/env bash
set -e
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

export SUPPRESS_IMAGE_VIEWER=1

# Packages: run tests and generate coverage (skip if no test/ directory)
# Then convert raw coverage to lcov.info so it can be merged.
for dir in packages/colonizethis_models packages/colonizethis_data packages/colonizethis_save packages/colonizethis_logic packages/colonizethis_ai packages/colonizethis_map; do
  if [ -d "$dir/test" ]; then
    (cd "$dir" && dart test --coverage=coverage)
    (cd "$dir" && dart run coverage:format_coverage --lcov -i coverage -o coverage/lcov.info --report-on=lib --package=.) 2>/dev/null || true
  fi
done

# App: run tests and generate coverage
(cd app && flutter test --coverage)

# Optional: merge lcov files and print summary
MERGE="$ROOT/coverage_merged"
COVERAGE_FILES=()
[ -f app/coverage/lcov.info ] && COVERAGE_FILES+=("$ROOT/app/coverage/lcov.info")
for dir in packages/colonizethis_models packages/colonizethis_data packages/colonizethis_save packages/colonizethis_logic packages/colonizethis_ai packages/colonizethis_map; do
  [ -f "$dir/coverage/lcov.info" ] && COVERAGE_FILES+=("$ROOT/$dir/coverage/lcov.info")
done

# Coverage breakdown: app and each package
if command -v lcov &>/dev/null; then
  echo ""
  echo "=== Coverage breakdown ==="
  if [ -f app/coverage/lcov.info ]; then
    echo "--- app ---"
    lcov --summary app/coverage/lcov.info 2>/dev/null | grep -E "lines|source" || true
  fi
  for dir in packages/colonizethis_models packages/colonizethis_data packages/colonizethis_save packages/colonizethis_logic packages/colonizethis_ai packages/colonizethis_map; do
    if [ -f "$dir/coverage/lcov.info" ]; then
      echo "--- $dir ---"
      lcov --summary "$dir/coverage/lcov.info" 2>/dev/null | grep -E "lines|source" || true
    fi
  done
fi

# Merge and overall summary
if command -v lcov &>/dev/null && [ ${#COVERAGE_FILES[@]} -gt 0 ]; then
  mkdir -p "$MERGE"
  MERGE_ARGS=()
  for f in "${COVERAGE_FILES[@]}"; do MERGE_ARGS+=(-a "$f"); done
  lcov -q "${MERGE_ARGS[@]}" -o "$MERGE/all.info" 2>/dev/null || true
  if [ -f "$MERGE/all.info" ]; then
    lcov -q --remove "$MERGE/all.info" '*.g.dart' '*.freezed.dart' -o "$MERGE/all.info" 2>/dev/null || true
    echo "--- Overall (merged) ---"
    lcov --summary "$MERGE/all.info"
    echo "Per-package coverage: app/coverage/, packages/*/coverage/"
    echo "Merged: $MERGE/all.info"
  else
    echo "Per-package coverage: app/coverage/, packages/*/coverage/"
  fi
else
  echo "Per-package coverage: app/coverage/, packages/*/coverage/"
  if [ ${#COVERAGE_FILES[@]} -eq 0 ]; then
    echo "No lcov.info files found."
  elif ! command -v lcov &>/dev/null; then
    echo "Install lcov for merged summary."
  fi
fi
