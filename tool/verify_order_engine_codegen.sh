#!/usr/bin/env bash
# Regenerates OrderEngine part file and fails if the working tree would change.
# SPEC/program/order-engine.md — Code generation (OrderEngine slots)
set -euo pipefail
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"
dart run tool/generate_order_engine_slots.dart
git diff --exit-code -- \
  packages/colonizethis_orders/lib/src/orders/order_engine.g.dart
