#!/usr/bin/env bash
# SPEC/program/test-logging.md — enforce test import convention:
# - No direct "package:test/test.dart"; use "package:colonizethis_test/test.dart".
# - Flutter test files must import colonizethis_test first, then flutter_test.
# Exit 0 if all checks pass, 1 otherwise.

set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

FAIL=0

for f in $(find app packages ctdev ctterm tool -name '*_test.dart' -type f 2>/dev/null | sort); do
  # Forbid direct package:test/test.dart
  if grep -q "package:test/test\.dart" "$f"; then
    echo "ERROR: $f must not import package:test/test.dart; use package:colonizethis_test/test.dart first (see SPEC/program/test-logging.md)"
    FAIL=1
  fi
  # If uses flutter_test, must have colonizethis_test first (lower line number)
  if grep -q "package:flutter_test/flutter_test\.dart" "$f"; then
    if ! grep -q "package:colonizethis_test/test\.dart" "$f"; then
      echo "ERROR: $f uses flutter_test but does not import package:colonizethis_test/test.dart first (see SPEC/program/test-logging.md)"
      FAIL=1
    else
      LN_CT=$(grep -n "package:colonizethis_test/test\.dart" "$f" | head -1 | cut -d: -f1)
      LN_FLUTTER=$(grep -n "package:flutter_test/flutter_test\.dart" "$f" | head -1 | cut -d: -f1)
      if [[ -n "${LN_CT:-}" && -n "${LN_FLUTTER:-}" && "$LN_CT" -gt "$LN_FLUTTER" ]]; then
        echo "ERROR: $f must import package:colonizethis_test/test.dart before package:flutter_test/flutter_test.dart (see SPEC/program/test-logging.md)"
        FAIL=1
      fi
    fi
  fi
done

if [[ $FAIL -eq 1 ]]; then
  exit 1
fi
echo "Test import convention check passed."
exit 0
