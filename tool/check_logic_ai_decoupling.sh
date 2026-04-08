#!/usr/bin/env bash
# Enforce architecture boundary between colonizethis_logic and colonizethis_ai.
# Exit 0 when all checks pass, 1 otherwise.

set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

FAIL=0
LOGIC_PUBSPEC="packages/colonizethis_logic/pubspec.yaml"
AI_LIB_DIR="packages/colonizethis_ai/lib"
LOGIC_TEST_DIR="packages/colonizethis_logic/test"
SEARCH_TOOL=rg

if ! command -v rg >/dev/null 2>&1; then
  SEARCH_TOOL=grep
fi

echo "Checking logic/ai decoupling policy..."
echo "Using search tool: $SEARCH_TOOL"

search_has_match() {
  local pattern="$1"
  local target="$2"
  if [[ "$SEARCH_TOOL" == "rg" ]]; then
    rg -n "$pattern" "$target" >/dev/null
  else
    grep -RInE "$pattern" "$target" >/dev/null
  fi
}

search_lines() {
  local pattern="$1"
  local target="$2"
  if [[ "$SEARCH_TOOL" == "rg" ]]; then
    rg -n "$pattern" "$target" || true
  else
    grep -RInE "$pattern" "$target" || true
  fi
}

# 1) logic package must not depend on ai package (including dev_dependencies).
if search_has_match "^[[:space:]]*colonizethis_ai[[:space:]]*:" "$LOGIC_PUBSPEC"; then
  echo "ERROR: $LOGIC_PUBSPEC must not contain colonizethis_ai in dependencies/dev_dependencies."
  FAIL=1
fi

# 2) AI must not import broad logic barrel.
if search_has_match "package:colonizethis_logic/colonizethis_logic\\.dart" "$AI_LIB_DIR"; then
  echo "ERROR: Forbidden import found in $AI_LIB_DIR: package:colonizethis_logic/colonizethis_logic.dart"
  FAIL=1
fi

# 3) AI may import only narrow logic contracts.
ALLOWED_IMPORT_A="package:colonizethis_logic/ai_api.dart"
ALLOWED_IMPORT_B="package:colonizethis_logic/order_suggestion_api.dart"
IMPORTS="$(search_lines "package:colonizethis_logic/[^']+" "$AI_LIB_DIR")"
if [[ -n "$IMPORTS" ]]; then
  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    import_path="$(echo "$line" | sed -E "s/.*(package:colonizethis_logic\/[^']+).*/\1/")"
    if [[ "$import_path" != "$ALLOWED_IMPORT_A" && "$import_path" != "$ALLOWED_IMPORT_B" ]]; then
      echo "ERROR: Non-contract logic import in AI: $line"
      echo "       Allowed: $ALLOWED_IMPORT_A or $ALLOWED_IMPORT_B"
      FAIL=1
    fi
  done <<< "$IMPORTS"
fi

# 4) logic tests should not import ai package.
if [[ -d "$LOGIC_TEST_DIR" ]]; then
  if search_has_match "package:colonizethis_ai/" "$LOGIC_TEST_DIR"; then
    echo "ERROR: $LOGIC_TEST_DIR must not import package:colonizethis_ai/..."
    FAIL=1
  fi
fi

if [[ $FAIL -eq 1 ]]; then
  exit 1
fi

echo "Logic/AI decoupling check passed."
exit 0
