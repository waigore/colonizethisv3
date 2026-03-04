#!/usr/bin/env bash
set -euo pipefail

# Placeholder script for saving a game from ctterm.
# As of the current ctterm TUI spec/implementation, there is no explicit
# in-game "Save Game" action exposed via keyboard shortcuts or menus.
# This script fails fast and documents that limitation.
#
# Usage (from repo root, with an existing session running):
#   ./ctterm/scripts/agent_tui_save_game.sh
#
# Exit status:
#   1 — save action is not available in ctterm TUI yet.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"

cd "${ROOT_DIR}"

source "${SCRIPT_DIR}/agent_tui_ctterm_common.sh"

ctterm_agent_save_game

