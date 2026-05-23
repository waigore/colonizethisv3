---
name: consolidate-prs
description: Collapses multiple open pull requests that target the same GitHub issue into one consolidated PR, unblocks any stalled contributor PRs via strict `fix-pr` first, then cancels in-progress GitHub Actions runs that are no longer attached to any open PR. Use when the user asks to consolidate, merge, or de-duplicate open PRs by issue and tidy CI usage.
---

# Consolidate open PRs by issue (ColonizeThis)

## When this applies

Use this skill when the user asks to:

- Collapse multiple open PRs that reference the same issue into one PR.
- Reduce duplicate or overlapping in-flight PR work per issue.
- Stop wasted CI minutes from workflow runs whose PRs have since been closed.

If the user names a single specific issue, scope this run to that issue only.
Otherwise, scan all open issues with two or more referencing open PRs.

## Required dependencies

Read and apply strictly — do not reinvent lighter substitutes:

- `.cursor/skills/fix-pr/SKILL.md` — used end-to-end whenever a PR in scope is
  stalled (merge conflicts vs its base, failing required checks, or checks not
  running). Discover the PR via `gh`; pass the PR number/URL into that skill’s
  workflow.
- `.cursor/skills/clean-local-branches/SKILL.md` — governs **local** branch
  hygiene after consolidation. Never delete remote branches in this skill.

Also follow `AGENTS.md`, `CONTRIBUTING.md`, and `.cursor/rules/`.

## Non-negotiables (repo policy)

- **One issue per PR** stays true after consolidation — never bundle multiple
  issues into the consolidated PR.
- **Never close issues** here. Only close redundant PRs (with a pointer
  comment), and only after their changes are represented in the canonical PR.
- **Never delete branches on the remote** (`git push <remote> --delete` and
  equivalents are forbidden). Local pruning is handled by
  `clean-local-branches`.
- **No quality-gate bypass.** Do not force-merge or skip required checks to
  finish consolidation.
- **SPEC-first behavior.** Do not introduce or retain behavior outside SPEC
  authorization. If a non-canonical PR carries unspecified behavior, drop that
  hunk during consolidation (do not silently preserve it).
- **Read base from PR metadata** (`gh pr view --json baseRefName`). Do not
  assume `dev` — verify per PR.

## Workflow

### 1. Discover and group

1. List open PRs (paginated): `gh pr list --state open --limit 200 --json
   number,title,headRefName,baseRefName,isDraft,updatedAt,body,headRepository`.
2. For each PR, extract referenced issue numbers from `title` and `body` using
   `Refs #<n>`, `Fixes #<n>`, `Closes #<n>`, `Resolves #<n>` (case-insensitive,
   `gh-<n>` and full URLs `…/issues/<n>` also count).
3. Group PRs by referenced issue number. Drop groups with only one PR.
4. For each multi-PR group, confirm the issue is **open**
   (`gh issue view <n> --json state`); if the issue is closed, skip
   consolidation for that group and surface it in the final report — the user
   probably needs to decide whether to close those PRs outright.

### 2. Pick the canonical PR per issue

For each remaining group, choose **one** canonical PR. Prefer in this order:

1. PR explicitly nominated by the user.
2. PR currently `mergeable` per `gh pr view --json mergeable,mergeStateStatus`.
3. PR with the most commits implementing the issue’s ACs (read the PR diff
   and body — favor scope match over branch age).
4. Tie-breaker: oldest `createdAt` (preserves earliest review history).

Record the canonical PR number, head ref, and base ref. All others in the
group are **redundant PRs** to be folded in and closed.

### 3. Unblock stalled PRs via `fix-pr`

For every PR in the group (canonical and redundant) that is **stalled**, apply
`.cursor/skills/fix-pr/SKILL.md` end-to-end **before** attempting
consolidation. Stalled means any of:

- Merge conflicts against the PR’s configured base ref.
- Required checks failing.
- Open but checks not running (not triggered, stuck pending, or branch/base
  state blocks CI until updated).

Do not skip this step. Trying to consolidate a stalled branch produces messy
merges and may hide real failures.

### 4. Fold redundant PRs into the canonical PR

Operate on the canonical branch locally. For each redundant PR, prefer the
**least destructive** mechanism that preserves authorship and avoids
re-introducing behavior already represented in canonical:

1. `git fetch origin <canonical-head> <redundant-head>`
2. Check whether redundant commits are already reachable from canonical
   (`git log --oneline canonical-head..redundant-head`). If empty → nothing
   to fold; the PR is purely redundant. Skip to step 5.
3. Otherwise fold using engineering judgment per commit/hunk:
   - **Merge** when the redundant branch carries a clean, self-contained
     additional slice and a merge commit is acceptable on the canonical PR.
   - **Cherry-pick** specific commits when only part of the redundant work
     belongs in the canonical scope.
   - **Drop** hunks that re-implement what canonical already has, or that
     add unspecified behavior.
4. Resolve conflicts hunk-by-hunk using the same prefer-base vs prefer-PR
   judgment described in `fix-pr` (lowest-risk, SPEC-aligned, no opportunistic
   refactors).
5. Run the same targeted local verification `fix-pr` requires (tests/static
   analysis impacted by the folded changes) until green. Do not push if
   verification fails.
6. Push canonical: `git push origin HEAD:<canonical-head>`.

### 5. Close redundant PRs with a pointer

For each redundant PR whose changes are now represented in the canonical PR
(or that was empty per step 4.2):

```bash
gh pr close <pr> --comment "Consolidated into #<canonical-pr> for issue #<n>. Closing to keep one PR per issue (see .cursor/skills/consolidate-prs)."
```

Do **not** pass `--delete-branch`. Branch cleanup is local-only and handled
by `clean-local-branches` if and when the user runs it.

If a redundant PR contained material the user must review before dropping
(unspecified behavior, contested approach), **do not close it**. Leave a
comment on both PRs noting the unresolved hunks and surface it in the report.

### 6. Cancel orphan GitHub Actions runs

After consolidation, free CI by cancelling **in-flight runs no longer
attached to an open PR**.

1. Refresh the open-PR head set:

   ```bash
   gh pr list --state open --limit 500 --json headRefName,headRepositoryOwner \
     --jq '.[] | "\(.headRepositoryOwner.login):\(.headRefName)"' | sort -u
   ```

2. List active workflow runs (queued + in_progress, both statuses):

   ```bash
   gh run list --limit 200 --json databaseId,status,headBranch,event,headSha,displayTitle,workflowName \
     --jq '.[] | select(.status=="in_progress" or .status=="queued")'
   ```

3. A run is an **orphan** when **all** of these hold:
   - Its `event` is `pull_request` or `pull_request_target`, **and**
   - Its `headBranch` is **not** in the open-PR head set computed in (1),
     **and**
   - No open PR currently has that `headSha` as its `headRefOid` (verify with
     `gh pr list --search "head:<branch>"` or by mapping head SHAs).

   Do **not** cancel runs whose `event` is `push`, `schedule`,
   `workflow_dispatch`, or `merge_group` based on this rule alone — those are
   not "attached to an open PR" by definition and likely belong to required
   branch/release pipelines. Only cancel non-PR-event runs if the user has
   explicitly asked to stop them.

4. Cancel each orphan run:

   ```bash
   gh run cancel <databaseId>
   ```

   The user said **forcibly** end them: do not wait for graceful termination
   beyond what `gh run cancel` already performs, and do not re-trigger them.

5. Do **not** delete workflow run history (`gh run delete`) unless the user
   explicitly asks. Cancellation is sufficient to stop CI usage.

## Output in chat

Report, per issue handled:

- Issue number / title / URL.
- Canonical PR (number / URL) and chosen rationale (one line).
- Redundant PRs: closed (with pointer), skipped (and why).
- `fix-pr` invocations performed and outcomes (per PR).
- Consolidation push result (commit SHA on canonical).
- Verification commands run and results.

Then a single CI section:

- Orphan runs cancelled: list of `databaseId / workflowName / headBranch`.
- Runs intentionally **not** cancelled (with reason — usually non-PR event).

## Guardrails

- Never close issues. Never delete remote branches. Never bypass required
  checks.
- Never bundle multiple issues into the consolidated PR.
- If `gh` is unavailable, return the exact commands and prepared close/comment
  bodies for manual follow-up instead of guessing.
- If consolidation would require dropping unresolved contested changes, stop
  and surface the conflict for the user — do not silently discard work.
