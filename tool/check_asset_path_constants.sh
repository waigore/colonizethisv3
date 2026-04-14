#!/usr/bin/env bash
# Enforce asset path constants policy in app runtime code.

set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

dart run tool/check_asset_path_constants.dart
