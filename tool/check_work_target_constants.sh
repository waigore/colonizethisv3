#!/usr/bin/env bash
# Enforce work target constant usage policy in executable Dart code.

set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

dart run tool/check_work_target_constants.dart "$@"
