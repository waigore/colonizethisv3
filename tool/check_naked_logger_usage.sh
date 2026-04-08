#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

matches="$(
  rg --line-number "\\bLogger\\(" \
    --glob '*.dart' \
    --glob '!**/.dart_tool/**' \
    --glob '!**/build/**' \
    --glob '!**/package_logger.dart' \
    --glob '!**/test/**' \
    . || true
)"

matches="$(printf '%s\n' "$matches" | rg -v 'packages/colonizethis_logger/lib/src/ct_logger.dart' || true)"

if [[ -n "$matches" ]]; then
  printf '%s\n' "$matches"
  echo
  echo "Naked Logger(...) usage detected. Use package-local packageLogger() API."
  exit 1
fi

echo "No naked Logger(...) usage detected."
#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

matches="$(
  rg --line-number "\\bLogger\\(" \
    --glob '*.dart' \
    --glob '!**/.dart_tool/**' \
    --glob '!**/build/**' \
    --glob '!**/package_logger.dart' \
    --glob '!**/test/**' \
    . || true
)"

matches="$(printf '%s\n' "$matches" | rg -v 'packages/colonizethis_logger/lib/src/ct_logger.dart' || true)"

if [[ -n "$matches" ]]; then
  printf '%s\n' "$matches"
  echo
  echo "Naked Logger(...) usage detected. Use package-local packageLogger() API."
  exit 1
fi

echo "No naked Logger(...) usage detected."
