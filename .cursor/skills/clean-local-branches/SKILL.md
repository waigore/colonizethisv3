---
name: clean-local-branches
description: Deletes local git branch refs that are not the primary development branch `dev` and not the head branch of an open pull request; never deletes branches on the remote. Use when pruning merged or stale local branches, tidying a clone, or when the user asks to remove old local branches without affecting GitHub/remotes.
---

# Clean local branches (keep `dev` + open PRs)

## Goal

Remove unnecessary **local** branch refs (`refs/heads/*`). Keep:

- `dev` (default integration branch for this repo)
- The **currently checked-out** branch (switch before deleting if it should go)
- Any branch that is the **head ref of an open PR** on the default GitHub remote

Do **not** delete or rewrite anything on the remote (no `git push origin --delete`, no force-push to drop remote branches).

## Preconditions

- Run from the repository root (or `cd` there first).
- Prefer a clean working tree; if not clean, warn and avoid destructive git steps until the user resolves or confirms.

## Build the keep set

1. **Always keep**: `dev`.
2. **Always keep**: the current branch name (from `git branch --show-current`). If the user wants it deleted, have them checkout another branch first (usually `git checkout dev`).
3. **Open PR heads** (GitHub CLI when available):

   ```bash
   gh pr list --state open --json headRefName \
     --jq '.[].headRefName' | sort -u
   ```

   If `gh` is missing, unauthenticated, or the repo has no `origin` mapping, **stop** and ask the user for the list of branch names to preserve (or install/auth `gh`), instead of guessing.

## Enumerate candidates

List local branches (no remote prefixes):

```bash
git branch --format='%(refname:short)'
```

Exclude `dev`, the current branch, and every name from the open-PR list.

## Delete local refs only

For each candidate branch:

1. Prefer safe delete: `git branch -d <branch>`
2. If Git refuses because the branch is not fully merged:
   - If it is **not** in the keep set and the user asked for cleanup of unused branches, **ask once** whether to force-delete locally (`git branch -D <branch>`), explaining that unmerged commits would only be dropped from the **local** ref.
3. Never delete the branch you are on.

## Explicit prohibitions

- Do **not** run `git push <remote> --delete`, `git push <remote> :<branch>`, or any remote branch deletion.
- Do **not** treat this task as permission to rewrite remote history (no force-push to drop remote branches).

## Optional local housekeeping (only if the user wants it)

These only change **local** refs; they do **not** delete branches on the server:

- Drop stale **remote-tracking** refs after teammates delete remote branches: `git fetch --prune` (or `git remote prune origin`).

State clearly that this prunes local `refs/remotes/...` mirrors, not `refs/heads/...` topic branches, and still does not delete anything on GitHub.

## Report

Summarize: branches deleted, branches skipped (and why), any failures, and confirm no remote-deletion commands were used.
