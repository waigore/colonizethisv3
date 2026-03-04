#!/usr/bin/env bash
set -euo pipefail

#
# Common helpers for driving ctterm via agent-tui.
#
# Contract (per SPEC/tui/ctterm.md §5.2):
# - Terminal size: 80x24
# - cwd: repo root (so `dart run ctterm` works)
# - One ctterm session per test data-dir
# - Interaction via `agent-tui press`, `agent-tui type`, `agent-tui wait`, `agent-tui screenshot`
#
# Environment variables:
# - CTTERM_REPO_ROOT      (optional) : repo root; auto-detected from this script when unset
# - CTTERM_TEST_DATA_DIR  (optional) : Hive data dir for this session; auto-created when unset
# - CTTERM_AGENT_SESSION  (optional) : agent-tui session id; when set, all commands pass --session
#

_ctterm_agent_repo_root() {
  if [[ -n "${CTTERM_REPO_ROOT:-}" ]]; then
    printf '%s\n' "$CTTERM_REPO_ROOT"
    return
  fi

  # Resolve repo root as two levels above this script: ctterm/scripts/ → repo root
  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  CTTERM_REPO_ROOT="$(cd "${script_dir}/../.." && pwd)"
  export CTTERM_REPO_ROOT
  printf '%s\n' "$CTTERM_REPO_ROOT"
}

_ctterm_agent_data_dir() {
  if [[ -n "${CTTERM_TEST_DATA_DIR:-}" ]]; then
    printf '%s\n' "$CTTERM_TEST_DATA_DIR"
    return
  fi

  # Default: create a temporary per-run data directory
  CTTERM_TEST_DATA_DIR="$(mktemp -d -t ctterm_data_XXXXXX)"
  export CTTERM_TEST_DATA_DIR
  printf '%s\n' "$CTTERM_TEST_DATA_DIR"
}

_ctterm_agent_session_args() {
  if [[ -n "${CTTERM_AGENT_SESSION:-}" ]]; then
    printf '%s %s' "--session" "$CTTERM_AGENT_SESSION"
  fi
}

ctterm_agent_start_session() {
  # Starts the agent-tui daemon (idempotent) and launches a ctterm session.
  # Usage: ctterm_agent_start_session [data_dir]
  #
  # When CTTERM_AGENT_SESSION is already set, this function only ensures the
  # daemon is running and does NOT start another session.

  local data_dir
  if [[ $# -ge 1 ]]; then
    data_dir="$1"
    CTTERM_TEST_DATA_DIR="$data_dir"
    export CTTERM_TEST_DATA_DIR
  else
    data_dir="$(_ctterm_agent_data_dir)"
  fi

  local repo_root
  repo_root="$(_ctterm_agent_repo_root)"

  # Ensure daemon is running; ignore error if already started.
  if ! agent-tui daemon start >/dev/null 2>&1; then
    # Best-effort; continue even if this fails (daemon may already be running).
    :
  fi

  # If the caller provided a session id, assume the session is already running.
  if [[ -n "${CTTERM_AGENT_SESSION:-}" ]]; then
    printf 'ctterm_agent_start_session: using existing session "%s" with data-dir "%s"\n' \
      "$CTTERM_AGENT_SESSION" "$data_dir" >&2
    return 0
  fi

  printf 'ctterm_agent_start_session: starting ctterm with data-dir "%s"\n' "$data_dir" >&2

  # Start ctterm in an 80x24 terminal. agent-tui will create a default session;
  # follow-up commands will target that session implicitly unless the caller
  # supplies CTTERM_AGENT_SESSION.
  agent-tui run \
    --cols 80 \
    --rows 24 \
    --cwd "${repo_root}" \
    dart -- run ctterm --data-dir "${data_dir}"
}

ctterm_agent_kill_session() {
  # Kill the current agent-tui session.
  # If CTTERM_AGENT_SESSION is set, use it; otherwise kill the default session.

  if [[ -n "${CTTERM_AGENT_SESSION:-}" ]]; then
    agent-tui --session "${CTTERM_AGENT_SESSION}" kill
  else
    agent-tui kill
  fi
}

ctterm_agent_press() {
  # Sends one or more keys to ctterm.
  # Example: ctterm_agent_press N
  #          ctterm_agent_press ArrowDown Enter

  if [[ $# -lt 1 ]]; then
    printf 'ctterm_agent_press: expected at least one key\n' >&2
    return 1
  fi

  # shellcheck disable=SC2048,SC2086
  agent-tui $(_ctterm_agent_session_args) press "$@"
}

ctterm_agent_type() {
  # Types literal text into ctterm.
  # Example: ctterm_agent_type "Save 1"

  if [[ $# -ne 1 ]]; then
    printf 'ctterm_agent_type: expected exactly one argument (text)\n' >&2
    return 1
  fi

  local text="$1"
  # shellcheck disable=SC2048,SC2086
  agent-tui $(_ctterm_agent_session_args) type "${text}"
}

ctterm_agent_wait_for_text() {
  # Waits until the given text appears on screen.
  # Example: ctterm_agent_wait_for_text "100001"    # Main Menu screen id

  if [[ $# -ne 1 ]]; then
    printf 'ctterm_agent_wait_for_text: expected exactly one argument (text)\n' >&2
    return 1
  fi

  local text="$1"
  # shellcheck disable=SC2048,SC2086
  agent-tui $(_ctterm_agent_session_args) wait "${text}" --assert
}

ctterm_agent_wait_until_gone() {
  # Waits until the given text disappears from the screen.
  # Example: ctterm_agent_wait_until_gone "Generating world"

  if [[ $# -ne 1 ]]; then
    printf 'ctterm_agent_wait_until_gone: expected exactly one argument (text)\n' >&2
    return 1
  fi

  local text="$1"
  # shellcheck disable=SC2048,SC2086
  agent-tui $(_ctterm_agent_session_args) wait "${text}" --gone
}

ctterm_agent_wait_for_screen() {
  # Waits until a screen id (e.g. 100001) is visible.
  # Example: ctterm_agent_wait_for_screen 100006   # In-game shell

  if [[ $# -ne 1 ]]; then
    printf 'ctterm_agent_wait_for_screen: expected exactly one argument (screen id)\n' >&2
    return 1
  fi

  local id="$1"
  ctterm_agent_wait_for_text "${id}"
}

ctterm_agent_screenshot() {
  # Captures a screenshot (ANSI stripped). If a path is passed, writes to that
  # file; otherwise prints to stdout.
  #
  # Example: ctterm_agent_screenshot                 # prints to stdout
  #          ctterm_agent_screenshot tmp/snap.txt   # writes to file

  if [[ $# -gt 1 ]]; then
    printf 'ctterm_agent_screenshot: expected zero or one argument (output path)\n' >&2
    return 1
  fi

  local out_path="${1:-}"
  if [[ -z "${out_path}" ]]; then
    # shellcheck disable=SC2048,SC2086
    agent-tui $(_ctterm_agent_session_args) screenshot --strip-ansi
  else
    # shellcheck disable=SC2048,SC2086
    agent-tui $(_ctterm_agent_session_args) screenshot --strip-ansi > "${out_path}"
  fi
}

#
# Higher-level helpers for common flows. These can be used directly when
# sourcing this file, and are also wrapped by standalone scripts.
#

ctterm_agent_new_game_default() {
  # From Main Menu, start a new game with auto-assigned slots and wait until
  # the in-game shell (100006) is visible.
  #
  # Steps:
  # - Wait for Main Menu (100001)
  # - Press N to open Game Setup
  # - Wait for Game Setup (100002)
  # - Press A to auto-assign nations/leaders
  # - Press S to Start Game
  # - Wait for "Generating World"
  # - Wait until "Generating World" is gone
  # - Wait for In-game shell (100006)

  ctterm_agent_wait_for_screen 100001
  ctterm_agent_press N
  ctterm_agent_wait_for_screen 100002
  ctterm_agent_press A
  ctterm_agent_press S
  ctterm_agent_wait_for_text "Generating World"
  ctterm_agent_wait_until_gone "Generating World"
  ctterm_agent_wait_for_screen 100006
}

ctterm_agent_quit_to_main_menu() {
  # From in-game shell, open Pause/Options and exit to Main Menu via the
  # confirmation dialog.
  #
  # Steps:
  # - Assert In-game shell (100006)
  # - Press Escape to open Pause/Options (100018)
  # - Ensure "Exit to Main Menu" is visible
  # - Press Enter to open confirmation
  # - Press Y to confirm exit
  # - Wait for Main Menu (100001)

  ctterm_agent_wait_for_screen 100006
  ctterm_agent_press Escape
  ctterm_agent_wait_for_screen 100018
  ctterm_agent_wait_for_text "Exit to Main Menu"
  ctterm_agent_press Enter
  ctterm_agent_wait_for_text "Exit to Main Menu?"
  ctterm_agent_press Y
  ctterm_agent_wait_for_screen 100001
}

ctterm_agent_open_development() {
  # From in-game shell, navigate to the Development screen (100009).
  ctterm_agent_wait_for_screen 100006
  ctterm_agent_press D
  ctterm_agent_wait_for_screen 100009
}

ctterm_agent_assign_all_civilians_improvement() {
  # Best-effort helper: opens the Development screen and attempts to assign
  # a basic build_improvement work order to each civilian unit row by:
  # - Selecting the current unit (Enter)
  # - Pressing 'i' (build_improvement)
  # - Accepting the default province (Enter)
  # - Accepting the default tile (Enter)
  # - Moving to the next row (ArrowDown)
  #
  # This relies on the Development screen behaviour and hotkeys defined in
  # SPEC/tui/screens/development.md. It does not introspect the screen; it
  # simply walks a bounded number of rows, so it is safe even when there
  # are fewer units.

  ctterm_agent_open_development

  # Try up to 16 rows, which should exceed the number of civilian stacks
  # in typical games but keeps the loop bounded.
  local i
  for i in $(seq 1 16); do
    # Select unit
    ctterm_agent_press Enter

    # Choose Build Improvement work type (idle civilians only)
    ctterm_agent_press i

    # Province selection: accept default province
    ctterm_agent_press Enter

    # Tile selection: accept default tile
    ctterm_agent_press Enter

    # Move to next unit row
    ctterm_agent_press ArrowDown
  done

  # Return to in-game shell
  ctterm_agent_press Escape
  ctterm_agent_wait_for_screen 100006
}

ctterm_agent_save_game() {
  # Placeholder for an explicit in-game save flow.
  #
  # As of SPEC/tui (ctterm) and current implementation, there is no
  # dedicated "Save Game" menu item or hotkey exposed from the in-game
  # shell or Pause/Options. Saves are produced by external tools and
  # logic via save_service (SPEC/program/save-load.md).
  #
  # This helper fails fast so callers know that manual save is not yet
  # scriptable at the TUI level. When a TUI save flow is specified and
  # implemented, update this function to drive it via agent-tui.

  printf 'ctterm_agent_save_game: in-game save is not exposed via ctterm TUI yet; no save action was performed.\n' >&2
  return 1
}


