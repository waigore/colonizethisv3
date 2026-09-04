---
name: clean-local-branches
description: Deletes local git branch refs that are not the primary development branch `dev` and not the head branch of an open pull request; never deletes branches on the remote. Use when pruning merged or stale local branches, tidying a clone, or when the user asks to remove old local branches without affecting GitHub/remotes.
---

# Clean local branches (keep `dev` + open PRs)

Delete unused **local** `refs/heads/*`. Keep `dev`, the current branch, and open-PR head refs. Never delete remotes (`git push --delete` is forbidden). Conventions: [shared.md](../shared.md).

Keep set: `dev`; `git branch --show-current`; `gh pr list --state open --json headRefName --jq '.[].headRefName'`. If `gh` is unavailable, **stop** and ask for the preserve list (interactive).

Candidates: `git branch --format='%(refname:short)'` minus the keep set. Prefer `git branch -d`. If unmerged and the user asked for unused-branch cleanup, ask once before `git branch -D`. Never delete the branch you are on.

Optional, only if asked: `git fetch --prune` (local remote-tracking refs only). Report deleted, skipped, and that no remote-deletion commands ran.
