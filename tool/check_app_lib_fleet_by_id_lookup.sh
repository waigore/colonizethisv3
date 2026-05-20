#!/usr/bin/env bash
# Fail if app/lib uses linear worldState.fleets.where/firstWhere id lookups.
# Use Game.fleetById from colonizethis_logic (Refs #2575 Phase 4).

set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

TARGET="app/lib"
# Catches `.fleets.where((f) => f.id ==` and `.fleets.firstWhere((f) => f.id ==`
# patterns. The lambda parameter name is unconstrained (e.g. `(fleet) =>`).
PATTERN='\.fleets\.(where|firstWhere)\(\([A-Za-z_][A-Za-z0-9_]*\) => [A-Za-z_][A-Za-z0-9_]*\.id =='

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
  echo "ERROR: Use game.fleetById(id) instead of linear worldState.fleets.where/firstWhere id lookup in $TARGET (Refs #2575 Phase 4)."
  printf '%s\n' "$matches"
  exit 1
fi

echo "App lib: no linear worldState.fleets.where id lookups (policy check passed)."
