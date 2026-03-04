#!/usr/bin/env bash
set -euo pipefail

# From an in-game shell session, open Pause/Options and quit to the Main Menu.
#
# Usage (from repo root, with an existing ctterm session already running
# and showing the in-game shell 100006):
#   ./ctterm/scripts/agent_tui_quit_to_main_menu.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"

cd "${ROOT_DIR}"

source "${SCRIPT_DIR}/agent_tui_ctterm_common.sh"

ctterm_agent_quit_to_main_menu

printf 'Returned to Main Menu (100001).\n' >&2

