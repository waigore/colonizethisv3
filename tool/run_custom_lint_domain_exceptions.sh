#!/usr/bin/env bash
# Runs `dart run custom_lint` in every package wired for colonizethis_exception_lint.
# Analyzer context includes lib/, test/, and integration_test/ the same as a normal
# package analyze (GitHub #2014 slice: zero error-severity custom_lint issues).
# SPEC/program/exception-enforcement.md
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

run_if_wired() {
  local dir="$1"
  local pubspec="$ROOT/$dir/pubspec.yaml"
  if [[ -f "$pubspec" ]] && grep -q 'colonizethis_exception_lint' "$pubspec"; then
    echo "custom_lint: $dir"
    (cd "$ROOT/$dir" && dart run custom_lint)
  fi
}

for dir in \
  app \
  ctdev \
  packages/colonizethis_ai \
  packages/colonizethis_data \
  packages/colonizethis_exception_lint \
  packages/colonizethis_logger \
  packages/colonizethis_logic \
  packages/colonizethis_map \
  packages/colonizethis_models \
  packages/colonizethis_save \
  packages/colonizethis_test \
  packages/session_log_buffer \
  tool/check_gdd_coverage \
  tool/generate_map \
  tool/init_game \
  tool/show_tech \
  tool/sim_combat \
  tool/sim_combat_montecarlo \
  tool/sim_economy \
  tool/sim_scenarios
do
  run_if_wired "$dir"
done
