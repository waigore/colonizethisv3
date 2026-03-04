#!/usr/bin/env bash
set -euo pipefail

# Captures the current ctterm screen via agent-tui.
#
# Usage (from repo root, with an existing ctterm session running):
#   ./ctterm/scripts/agent_tui_screenshot.sh [output_path]
#
# - When [output_path] is provided, the screenshot text (ANSI stripped)
#   is written to that file.
# - When omitted, the screenshot is printed to stdout.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"

cd "${ROOT_DIR}"

source "${SCRIPT_DIR}/agent_tui_ctterm_common.sh"

OUT_PATH="${1:-}"

if [[ -n "${OUT_PATH}" ]]; then
  ctterm_agent_screenshot "${OUT_PATH}"
  printf 'Screenshot written to %s\n' "${OUT_PATH}" >&2
else
  ctterm_agent_screenshot
fi

