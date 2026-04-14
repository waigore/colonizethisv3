#!/usr/bin/env bash
# Enforce tech ID constant usage policy in executable Dart code.

set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

dart run tool/check_tech_id_constants.dart "$@"
