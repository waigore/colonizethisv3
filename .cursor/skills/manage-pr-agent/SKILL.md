---
name: manage-pr-agent
description: Keeps open pull requests moving through CI and GitHub workflows in an orderly manner. Enforces one open PR per GitHub issue (via consolidate-prs) and maintains a running-CI quota of 2 PRs (both floor and ceiling) by pausing excess via `[skip ci]` empty commits **and cancelling** their in-flight `pull_request` runs (before and after the skip commit). Whenever the quota has headroom and any open PRs exist, fills it by any means necessary: resuming paused PRs, updating mergeable-but-behind PR branches against base, and unblocking stalled PRs via fix-pr (older PRs first). Performs actions once and then ends the run without waiting for merges, CI, or unblock confirmation. Use when the user asks to tidy, throttle, unblock, or generally manage in-flight PRs.
---

# Manage PR Agent (ColonizeThis)

One orderly pass, then **end**. Never wait for CI, reviews, merges, or unblock confirmation.

Conventions: [shared.md](../shared.md). Children (apply strictly): [consolidate-prs](../consolidate-prs/SKILL.md), [fix-pr](../fix-pr/SKILL.md). Read base from PR metadata — do not assume `dev`. Never merge PRs.

## 1. Discover

```bash
gh pr list --state open --limit 200 --json \
  number,title,url,headRefName,baseRefName,isDraft,mergeable,mergeStateStatus,updatedAt,body,headRepository,headRepositoryOwner,statusCheckRollup
```

Group by referenced issue (`Refs`/`Fixes`/`Closes`/`Resolves` `#n`, `gh-n`, `…/issues/n`). Note groups with >1 PR.

Per PR:

- **Has running workflows** — check `status` in `IN_PROGRESS`, `QUEUED`, `PENDING`, `WAITING`.
- **Is stalled** — `CONFLICTING`, or required check `FAILURE`/`CANCELLED`/`TIMED_OUT`/`ACTION_REQUIRED`, or open with no checks running and none completed for this head SHA.
- **Is behind base** — `mergeable == MERGEABLE` and `mergeStateStatus == BEHIND`.

## 2. One PR per issue

For each issue with ≥2 open PRs, apply `consolidate-prs` end-to-end. Re-fetch the open-PR set before phase 3.

## 3. CI quota of 2 (floor and ceiling)

Skip only when there are **zero** open PRs. Otherwise push projected `R` toward `min(2, number of owned fillable PRs)`.

- `R` = PRs with running workflows
- `P` = owned (non-fork) PRs whose HEAD subject has `[skip ci]` / `[ci skip]` / `[no ci]` / `[skip actions]` / `[actions skip]`
- `B` = owned behind-base PRs not in `P` or `R`, newest `updatedAt` first
- `S` = stalled PRs not in `P` or `B`, oldest first

`R > 2` → pause `R - 2`. `R < 2` with anything in `P ∪ B ∪ S` → fill. Else no-op.

Each successful push/update increments projected `R` by 1 for this phase. Do not wait for the run to appear. Fork-owned PRs count toward `R` when running; skip them for pause-push / resume / update.

### Pause

Keep the two highest-priority running PRs: (1) PRs this run just consolidated, (2) mergeable waiting only on CI, (3) non-draft over draft, (4) newer `updatedAt`. Pause is CI-budget only — no draft conversion, no merge-blocking comments.

**Cancel + skip + cancel** (skip commit alone is not enough):

```bash
gh run list --branch <headRefName> --limit 50 --json \
  databaseId,status,event,headSha,workflowName \
  --jq '.[] | select(.status=="in_progress" or .status=="queued") | select(.event=="pull_request" or .event=="pull_request_target")'
# gh run cancel <databaseId> for each — all matching runs on the branch, any headSha
# do not cancel push/schedule/workflow_dispatch/merge_group on this rule alone

git fetch origin <headRefName>
git checkout -B _pause/<headRefName> origin/<headRefName>
git commit --allow-empty -m "[skip ci] manage-pr-agent: pause CI to honour 2-PR quota"
git push origin HEAD:<headRefName>
# cancel again
```

### Fill

Default cheapest-first: resume `P`, then `gh pr update-branch` on `B`, then `fix-pr` on `S`. Interleave if a closer-to-merge PR is obvious; record deviations.

Resume:

```bash
git fetch origin <headRefName>
git checkout -B _resume/<headRefName> origin/<headRefName>
git commit --allow-empty -m "chore: resume CI (manage-pr-agent)"
git push origin HEAD:<headRefName>
```

Update: `gh pr update-branch <number>`. Fallback: local `git merge --no-ff --no-edit origin/<base>` + push (never rebase/force-push a branch this agent did not create). On conflict: abort, reclassify into `S`, `fix-pr`.

Do not exit fill with projected `R < 2` while owned `P ∪ B ∪ S` remain unattempted.

## 4. Report and stop

**Consolidation** — per issue: canonical PR, redundant closed, or defer to `consolidate-prs` report.

**CI throughput** — open PRs; `R` before/after; branch (pause/fill/quota met); paused (cancel ids before/after, skip SHA); resumed; updated (`gh pr update-branch` vs local merge); unblocked (`fix-pr` one-liner); skipped forks; residual gap reasons.

**No-op phases** — one line each.
