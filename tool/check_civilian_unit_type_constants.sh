#!/usr/bin/env bash
# Enforce civilian unit type id constant usage policy in executable Dart code.

set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

dart run tool/check_civilian_unit_type_constants.dart "$@"
