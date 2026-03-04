#!/usr/bin/env bash
set -euo pipefail

# Scenario script: open Development and assign work to all civilian units.
#
# Behaviour (best-effort, per SPEC/tui/screens/development.md):
# - Assumes an existing ctterm session currently in the in-game shell (100006).
# - Opens the Development screen (100009) via 'D'.
# - For a bounded number of rows, repeatedly:
#   - Selects the current civilian unit (Enter/Space).
#   - Presses 'i' (Build Improvement) to start work-type selection.
#   - Accepts the default province (Enter).
#   - Accepts the default tile (Enter).
#   - Moves to the next unit row (ArrowDown).
# - Returns to the in-game shell (Escape) when done.
#
# Usage (from repo root, after starting a game and reaching in-game shell):
#   ./ctterm/scripts/agent_tui_assign_all_civilians_improvement.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"

cd "${ROOT_DIR}"

source "${SCRIPT_DIR}/agent_tui_ctterm_common.sh"

ctterm_agent_assign_all_civilians_improvement

printf 'Attempted to assign build_improvement work to all civilian units via Development screen.\n' >&2

