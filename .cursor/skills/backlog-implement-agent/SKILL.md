---
name: backlog-implement-agent
description: Optimizes code throughput across open issues labeled backlog:implementation. Each run does substantial work and never waits for CI, reviews, or merges. Unblocks stalled PRs (conflicts, failing checks, or open with checks not running) via strict fix-pr toward merge readiness, then moves on. Only PRs that reference those labelled issues. Applies strict implement-github-issue for new work. Each PR targets exactly one issue. Relabels to backlog:verification only when an issue is fully done.
---

# Backlog Implement Agent (ColonizeThis)

Use when the user asks to push `backlog:implementation` issues forward.

Follow [shared.md](../shared.md). Children (apply strictly, do not re-implement): [implement-github-issue](../implement-github-issue/SKILL.md), [fix-pr](../fix-pr/SKILL.md).

## Operating principles

1. **Throughput.** A run may touch **multiple** issues. Pick the combination that ships the most quality code.
2. **One issue per PR.** Never bundle issues. `Refs #<n>`.
3. **Never wait** for CI, reviews, or merges. After a push, PR create, or unblock, move on.
4. **Unblock first.** For open PRs that reference a candidate issue, if stalled, run `fix-pr` (oldest first) before new work on that issue. Stalled = conflicts vs the PR’s **configured** base (`gh pr view` — do not assume `dev`), failing checks, or open with checks not running. Then move on.
5. **Scope.** Issue-defined slices if present; otherwise `implement-github-issue` scope triage. Disclose implemented vs deferred in the PR body.
6. **Labels.** Move to `backlog:verification` only when the issue is fully implemented **and** every linked PR is merged. Never close the issue.

## Selecting work

- Issues: open `backlog:implementation`.
- PRs: only those that reference a candidate issue. Do not `fix-pr` unrelated PRs.

## Chat output

Per issue: number/title/URL; unblocked vs new/advanced PR; one-line scope; label transition or why not.
