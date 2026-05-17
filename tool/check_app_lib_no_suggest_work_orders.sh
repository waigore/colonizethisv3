#!/usr/bin/env bash
# Fail if app runtime code invokes broad per-player suggestWorkOrders (Refs #2133).
# UI must use getAvailableWorkTargetsForUnit / getValidWorkOrderTileKeysWithVisibility.
# Integration tests and AI may still call suggestWorkOrders outside app/lib.

set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

TARGET="app/lib"
PATTERN='suggestWorkOrders\s*\('

SEARCH_TOOL=rg
if ! command -v rg >/dev/null 2>&1; then
  SEARCH_TOOL=grep
fi

if [[ "$SEARCH_TOOL" == "rg" ]]; then
  matches="$(rg --line-number --glob '*.dart' "$PATTERN" "$TARGET" || true)"
else
  matches="$(grep -RInE --include='*.dart' "$PATTERN" "$TARGET" || true)"
fi
if [[ -n "$matches" ]]; then
  echo "ERROR: Broad suggestWorkOrders must not be called from $TARGET (Refs #2133, SPEC/program/order-suggestions.md)."
  echo "Use getAvailableWorkTargetsForUnit or getValidWorkOrderTileKeysWithVisibility for panel and Assign hot paths."
  printf '%s\n' "$matches"
  exit 1
fi

echo "App lib: no broad suggestWorkOrders calls (policy check passed)."
