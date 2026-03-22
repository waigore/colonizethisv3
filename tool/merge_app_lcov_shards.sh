#!/usr/bin/env bash
# Merge Flutter app coverage shard files into app/coverage/lcov.info for the 80% gate.
# Usage: tool/merge_app_lcov_shards.sh <shard_count>
# Expects app/coverage/lcov.shard0.info … lcov.shard(N-1).info (from CI shards).
set -e
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
COUNT="${1:?shard count required}"
OUT="$ROOT/app/coverage/lcov.info"
mkdir -p "$ROOT/app/coverage"

args=()
found=0
i=0
while [ "$i" -lt "$COUNT" ]; do
  f="$ROOT/app/coverage/lcov.shard${i}.info"
  if [ -f "$f" ]; then
    args+=(-a "$f")
    found=$((found + 1))
  fi
  i=$((i + 1))
done

if [ "$found" -eq 0 ]; then
  echo "merge_app_lcov_shards: no shard files under app/coverage/lcov.shard*.info"
  exit 1
fi

lcov "${args[@]}" -o "$OUT"
echo "Merged $found shard file(s) -> $OUT"
