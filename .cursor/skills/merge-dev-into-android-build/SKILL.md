---
name: merge-dev-into-android-build
description: Creates and merges a pull request from dev into build/app/android to trigger Android APK build workflows. Use when the user asks to produce an Android APK build via branch merge, especially when conflicts may occur and should be resolved in favor of dev.
---

# Merge `dev` Into Android Build Branch

PR-based merge of `dev` into `build/app/android` so APK workflows trigger. Conflicts favor `dev`. Conventions: [shared.md](../shared.md).

1. **Preflight** — `git status`; `git fetch --all --prune`; both `origin/dev` and `origin/build/app/android` exist; `gh auth status`. If branch names differ, ask before proceeding.

2. **Integrate** — `git checkout -B chore/android-build-sync origin/build/app/android` then `git merge origin/dev -X theirs` (`theirs` = `origin/dev` in this shape). Still-conflicted files: `git checkout --theirs -- <path>`. Continue the merge. Stop on non-conflict failures.

3. **PR** — push and `gh pr create --base build/app/android --head chore/android-build-sync` with why, conflict strategy, merge prepared.

4. **Merge** — `gh pr merge --merge --delete-branch`. If protection blocks, wait for checks (`gh pr checks --watch`) and retry.

5. **Verify** — PR merged; `origin/build/app/android` contains the merge; `gh run list --branch build/app/android`. Report PR URL, merge status, conflict summary, workflow link.
