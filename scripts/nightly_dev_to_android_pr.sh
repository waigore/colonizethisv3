#!/usr/bin/env bash
# Creates a PR from dev -> build/app/android for nightly APK builds.
# Requires: REPO_DIR set in environment (path to repo root).
# Optional: BASE_BRANCH, HEAD_BRANCH, REMOTE_NAME (defaults below).
# Run from cron or manually after: export REPO_DIR=/path/to/colonizethisv3

set -euo pipefail

BASE_BRANCH="${BASE_BRANCH:-build/app/android}"
HEAD_BRANCH="${HEAD_BRANCH:-dev}"
REMOTE_NAME="${REMOTE_NAME:-origin}"

if [[ -z "${REPO_DIR:-}" ]]; then
  echo "REPO_DIR must be set (e.g. export REPO_DIR=/path/to/colonizethisv3)" >&2
  exit 1
fi

log() {
  echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] $*"
}

cd "$REPO_DIR"

log "Fetching latest from remote..."
git fetch "$REMOTE_NAME"

log "Ensuring local $HEAD_BRANCH is up to date..."
git checkout "$HEAD_BRANCH"
git pull --ff-only "$REMOTE_NAME" "$HEAD_BRANCH"

log "Ensuring local $BASE_BRANCH is up to date..."
git checkout "$BASE_BRANCH"
git pull --ff-only "$REMOTE_NAME" "$BASE_BRANCH"

log "Checking for differences between $HEAD_BRANCH and $BASE_BRANCH..."
if git diff --quiet "$BASE_BRANCH".."$HEAD_BRANCH"; then
  log "No differences; nothing to PR."
  exit 0
fi

# PR source must be dev (HEAD_BRANCH) per workflow rules
log "Creating PR $HEAD_BRANCH -> $BASE_BRANCH..."
existing=$(gh pr list --base "$BASE_BRANCH" --head "$HEAD_BRANCH" --state open --json number --jq '.[0].number // empty')
if [[ -n "$existing" ]]; then
  log "Open PR already exists: #$existing"
  exit 0
fi

gh pr create \
  --base "$BASE_BRANCH" \
  --head "$HEAD_BRANCH" \
  --title "Nightly $HEAD_BRANCH → $BASE_BRANCH ($(date -u +"%Y-%m-%d"))" \
  --body "Automated nightly PR from \`$HEAD_BRANCH\` into \`$BASE_BRANCH\`."

log "Done."
