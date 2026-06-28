#!/usr/bin/env bash
# Tool package tests + sim_scenarios integration (nightly CI gate).
# See .github/workflows/nightly.yml and SPEC/program/test-logging.md.
set -euo pipefail
export SUPPRESS_IMAGE_VIEWER=1
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

dart pub get
dart pub global activate melos
melos --version

echo "=== Test tool packages (Dart) ==="
for dir in tool/sim_scenarios tool/sim_combat_montecarlo tool/sim_combat tool/generate_map tool/init_game tool/sim_economy tool/show_tech; do
  [ -d "$dir/test" ] || continue
  (cd "$dir" && dart test -j 2 --reporter=compact)
done

echo ""
echo "=== sim_scenarios integration gate ==="
melos run sim_scenarios

echo ""
echo "=== economy test wall-clock (advisory; Refs #3661) ==="
# Advisory by default: reports the economy suite's median wall-clock against the
# ceiling without failing the gate. See SPEC/program/economy-test-wall-clock.md.
bash tool/check_economy_test_wall_clock.sh

echo "Nightly integration gate passed."
