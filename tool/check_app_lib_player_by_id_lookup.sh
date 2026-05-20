#!/usr/bin/env bash
# Fail if app/lib uses linear game.players.where((p) => p.id == ...) lookups.
# Use Game.playerById from colonizethis_logic (Refs #2575).

set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

TARGET="app/lib"
PATTERN='\.players\.where\(\(p\) => p\.id =='

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
  echo "ERROR: Use game.playerById(id) instead of linear players.where id lookup in $TARGET (Refs #2575)."
  printf '%s\n' "$matches"
  exit 1
fi

echo "App lib: no linear game.players.where id lookups (policy check passed)."
