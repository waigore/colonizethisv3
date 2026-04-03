---
name: merge-dev-into-android-build
description: Creates and merges a pull request from dev into build/app/android to trigger Android APK build workflows. Use when the user asks to produce an Android APK build via branch merge, especially when conflicts may occur and should be resolved in favor of dev.
---

# Merge `dev` Into Android Build Branch

## Purpose

Use this skill to reliably trigger Android APK build automation by merging `dev` into `build/app/android` through a PR.

## When this applies

Apply this workflow when the user asks to:

- create an Android APK build for this project,
- create and merge a PR from `dev` to `build/app/android`, or
- handle expected merge conflicts while favoring `dev`.

## Constraints

- Prefer PR-based merge (no direct merge commit to protected branch unless user explicitly requests).
- If conflicts occur, resolve in favor of `dev` content.
- Ensure final result is merged into `build/app/android` so build automation can trigger.
- Do not force-push to `main`/`master`. Avoid destructive git operations.

## Workflow

### 1) Preflight checks

Run these checks first:

1. Confirm clean or acceptable working tree:
   - `git status --short --branch`
2. Fetch remotes:
   - `git fetch --all --prune`
3. Confirm both branches exist remotely:
   - `git ls-remote --heads origin dev build/app/android`
4. Confirm GitHub auth and repo access:
   - `gh auth status`

If branch names differ from expectation, stop and ask user before proceeding.

### 2) Create an integration branch from target

Create a temporary merge branch off the target branch:

1. `git checkout -B chore/android-build-sync origin/build/app/android`
2. Merge `origin/dev` into it, preferring `dev` during conflicts:
   - `git merge origin/dev -X theirs`

Notes:

- In this merge shape, `theirs` maps to `origin/dev`.
- If merge still reports unresolved files, resolve each conflicted file by taking `origin/dev` version:
  - `git checkout --theirs -- <path>`
  - `git add <path>`
- Continue with:
  - `git merge --continue`

If merge fails for non-conflict reasons, report error and stop.

### 3) Push and create the PR

1. Push branch:
   - `git push -u origin chore/android-build-sync`
2. Create PR with `base=build/app/android` and `head=chore/android-build-sync`:
   - `gh pr create --base build/app/android --head chore/android-build-sync --title "Sync dev into build/app/android for APK build" --body "<body>"`

Use a body that includes:

- Why this merge is needed (trigger Android APK build),
- Conflict strategy (favor `dev`),
- Brief validation note (merge commit prepared successfully).

### 4) Merge the PR

Merge using GitHub CLI:

- `gh pr merge --merge --delete-branch`

If branch protection requires checks/reviews, wait and re-run merge when unblocked:

- `gh pr checks <pr-number> --watch`

### 5) Verify merge and trigger conditions

After merge:

1. Confirm PR state is merged:
   - `gh pr view <pr-number> --json state,mergedAt,baseRefName,headRefName,url`
2. Confirm target branch contains merge result:
   - `git fetch origin`
   - `git log --oneline origin/build/app/android -n 5`
3. Confirm workflow trigger started (if workflow name known):
   - `gh run list --branch build/app/android --limit 10`

Report PR URL and latest relevant workflow run URL/status to the user.

## Failure handling

- If `gh` is unavailable or unauthenticated, provide exact commands for user to run after fixing auth and keep PR metadata draft ready.
- If PR cannot be merged due to required checks, report blocking checks and remain in "ready to merge" state.
- If conflict resolution by `-X theirs` is insufficient, manually resolve conflicted files in favor of `dev` and proceed.

## Output format

When done, provide:

1. PR URL,
2. Merge status (`merged` or `blocked` with reason),
3. Conflict summary (none / resolved in favor of `dev`),
4. Build workflow status link (or note if pending/unavailable).

## Safety notes

- Never run `git reset --hard` or force-push unless explicitly requested.
- Never change git config.
- Keep all actions scoped to `dev`, `build/app/android`, and temporary integration branch.
