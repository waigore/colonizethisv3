#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

SEARCH_TOOL=rg
if ! command -v rg >/dev/null 2>&1; then
  SEARCH_TOOL=grep
fi

if [ "$SEARCH_TOOL" = "rg" ]; then
  matches="$(
    rg --line-number '\bLogger\(' \
      --glob '*.dart' \
      --glob '!**/.dart_tool/**' \
      --glob '!**/build/**' \
      --glob '!**/.plugin_symlinks/**' \
      --glob '!**/flutter/ephemeral/**' \
      --glob '!**/package_logger.dart' \
      --glob '!**/test/**' \
      . || true
  )"
else
  matches="$(
    grep -RInE --include='*.dart' \
      --exclude-dir='.dart_tool' \
      --exclude-dir='build' \
      --exclude-dir='.plugin_symlinks' \
      --exclude='package_logger.dart' \
      --exclude-dir='test' \
      '(^|[^[:alnum:]_])Logger\(' . || true
  )"
fi

matches="$(printf '%s\n' "$matches" | grep -v 'packages/colonizethis_logger/lib/src/ct_logger.dart' || true)"

if [[ -n "$matches" ]]; then
  printf '%s\n' "$matches"
  echo
  echo "Naked Logger(...) usage detected. Use package-local packageLogger() API."
  exit 1
fi

echo "No naked Logger(...) usage detected."
