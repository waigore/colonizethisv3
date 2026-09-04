---
name: consolidate-prs
description: Collapses multiple open pull requests that target the same GitHub issue into one consolidated PR, unblocks any stalled contributor PRs via strict `fix-pr` first, then cancels in-progress GitHub Actions runs that are no longer attached to any open PR. Use when the user asks to consolidate, merge, or de-duplicate open PRs by issue and tidy CI usage.
---

# Consolidate open PRs by issue (ColonizeThis)

Named issue → that issue only; otherwise every open issue with ≥2 referencing PRs.

Conventions: [shared.md](../shared.md). Children: [fix-pr](../fix-pr/SKILL.md) (stalled PRs), [clean-local-branches](../clean-local-branches/SKILL.md) (local only). Read base from PR metadata.

## Workflow

1. **Discover** — `gh pr list --state open --limit 200 --json number,title,headRefName,baseRefName,isDraft,updatedAt,body,headRepository`. Group by issue refs (`Refs`/`Fixes`/`Closes`/`Resolves` `#n`, `gh-n`, URLs). Drop singleton groups. Skip groups whose issue is closed (report them).

2. **Canonical PR** — user nomination, else currently mergeable, else most AC-complete diff, else oldest `createdAt`.

3. **Unblock** — `fix-pr` on every stalled PR in the group (canonical and redundant) before folding.

4. **Fold** into canonical locally. If `canonical..redundant` is empty, skip to close. Else merge (clean extra slice), cherry-pick (partial), or drop (already represented / unspecified behavior). Conflict judgment as in `fix-pr`. Verify locally; do not push if red. `git push origin HEAD:<canonical-head>`.

5. **Close** redundant PRs whose work is now in canonical (or was empty):

   ```bash
   gh pr close <pr> --comment "Consolidated into #<canonical-pr> for issue #<n>. Closing to keep one PR per issue."
   ```

   Do **not** `--delete-branch`. If contested unspecified hunks remain, leave the PR open and comment on both.

6. **Cancel orphan runs** — in-flight `pull_request` / `pull_request_target` whose `headBranch` is not an open-PR head **and** whose `headSha` is not an open PR `headRefOid`. Do not cancel `push`/`schedule`/`workflow_dispatch`/`merge_group` on this rule. `gh run cancel <id>`. Do not `gh run delete`.

## Report

Per issue: canonical + rationale, redundant closed/skipped, `fix-pr` outcomes, push SHA, verification. Then orphan runs cancelled vs intentionally kept.
