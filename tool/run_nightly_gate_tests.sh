#!/usr/bin/env bash
# Run the same steps as .github/workflows/nightly.yml integration job locally.
# Observer campaign verify is slow (~minutes); run via melos/workflow or:
#   cd tool/run_observer_game && dart run run_observer_game --output /tmp/obs --seed 42 --max-turns 100 --verify-conquest
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
bash "$ROOT/tool/run_nightly_integration_gate.sh"
