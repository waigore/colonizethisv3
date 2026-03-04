#!/usr/bin/env bash
set -euo pipefail

# Starts ctterm (if needed), auto-assigns default nations/leaders,
# and waits until the in-game shell is visible.
#
# Usage (from repo root):
#   ./ctterm/scripts/agent_tui_new_game_default.sh [data_dir]
#
# - When [data_dir] is provided, it is used as the ctterm Hive data dir.
# - When omitted, a temporary data dir is created for this session.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"

cd "${ROOT_DIR}"

source "${SCRIPT_DIR}/agent_tui_ctterm_common.sh"

DATA_DIR="${1:-}"

if [[ -n "${DATA_DIR}" ]]; then
  ctterm_agent_start_session "${DATA_DIR}"
else
  ctterm_agent_start_session
fi

# Drive the TUI: New Game -> auto-assign -> start -> in-game shell.
ctterm_agent_new_game_default

printf 'New game started. Data dir: %s\n' "${CTTERM_TEST_DATA_DIR:-<unknown>}" >&2

