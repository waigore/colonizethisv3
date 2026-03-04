#!/usr/bin/env bash
# Agent-TUI test: assign a builder to work a tile, end turn, then assert the tile is improved.
# SPEC/tui/ctterm.md §5.2. Requires agent-tui on PATH (https://github.com/pproenca/agent-tui).
# Run from repo root: ./ctterm/scripts/agent_tui_builder_improvement_test.sh

set -e

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
DATA_DIR="$(mktemp -d)"
trap 'agent-tui kill 2>/dev/null || true; rm -rf "$DATA_DIR"' EXIT

cd "$REPO_ROOT"

if ! command -v agent-tui &>/dev/null; then
  echo "agent-tui not found on PATH. Install from https://github.com/pproenca/agent-tui"
  exit 1
fi

agent-tui daemon start 2>/dev/null || true

echo "Starting ctterm (80x24) with data-dir $DATA_DIR..."
agent-tui run --cols 80 --rows 24 --cwd "$REPO_ROOT" -- dart run ctterm --data-dir "$DATA_DIR" &
RUN_PID=$!
sleep 4

# Main Menu (100001) -> New Game
agent-tui wait "100001" --assert --timeout 15
agent-tui press N
sleep 2

# Game Setup (100002): auto-fill slots, Start
agent-tui wait "100002" --assert --timeout 15
agent-tui press A
sleep 1
agent-tui press S
sleep 2

# Wait for in-game shell (100006); world gen blocks UI so we wait for 100006 directly
agent-tui wait "100006" --assert --timeout 120 || {
  echo "Timeout waiting for in-game shell (100006). Current screen:"
  agent-tui screenshot --strip-ansi 2>/dev/null | head -40
  exit 1
}

# Open Development (100009)
agent-tui press D
agent-tui wait "100009" --assert --timeout 10

# Select first civilian unit (Enter), assign build_improvement (i), first province (Enter), first tile (Enter)
agent-tui press Enter
sleep 1
agent-tui press i
sleep 1
agent-tui press Enter
sleep 1
agent-tui press Enter
sleep 2

# Back to in-game shell
agent-tui press Escape
agent-tui wait "100006" --assert --timeout 10

# End turn (E). Builder has work so no idle prompt; if prompt appears, confirm with Y.
agent-tui press E
sleep 2
# If idle prompt appeared (e.g. multiple builders), confirm
agent-tui screenshot --strip-ansi 2>/dev/null | grep -q "End turn anyway" && agent-tui press Y || true
# Wait for turn to finish
agent-tui wait "Processing turn" --assert --timeout 5
agent-tui wait "Processing turn" --gone --timeout 30
sleep 2

# Open Production (100010) and check for improved tile (imp:1 or Farm or improvement level)
agent-tui press P
agent-tui wait "100010" --assert --timeout 10
sleep 1
SCREEN="$(agent-tui screenshot --strip-ansi 2>/dev/null)"
if echo "$SCREEN" | grep -qE "imp:[1-4]|Farm|Mine|Ranch|Plantation|Lumber camp|Pasture|Fur post|Improvement"; then
  echo "PASS: Tile improvement visible (imp level or improvement name found)."
else
  echo "FAIL: No tile improvement found on Production screen."
  echo "--- screenshot (strip-ansi) ---"
  echo "$SCREEN"
  exit 1
fi

agent-tui kill 2>/dev/null || true
wait $RUN_PID 2>/dev/null || true
exit 0
