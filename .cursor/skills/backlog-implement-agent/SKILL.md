---
name: backlog-implement-agent
description: Picks one open GitHub issue labeled backlog:implementation, prefers merging existing open PRs for that issue (unblocking stalled ones via fix-pr first), otherwise applies implement-github-issue strictly; opens or advances PRs documenting implemented vs deferred work; relabels to backlog:verification only when no outstanding work remains.
---

# Backlog Implement Agent (ColonizeThis)

## When this applies

Use when the user asks to run backlog implementation workflow and move one issue forward from `backlog:implementation`.

## Required dependencies

Before executing this skill:

- Read and apply `.cursor/skills/implement-github-issue/SKILL.md` strictly for issue quality gate, SPEC-first behavior, slicing rules, implementation quality, testing, and PR workflow.
- When a pull request needs unblocking (see §2), read and apply `.cursor/skills/fix-pr/SKILL.md` strictly for diagnosis, minimal fixes, conflict resolution, and verification—do not invent a lighter substitute.
- Follow `AGENTS.md`, `CONTRIBUTING.md`, and repository rules.

Do not weaken or substitute the implementation method from `implement-github-issue`, or the unblock method from `fix-pr`.

## Workflow

### 1) Select one candidate issue

Pick any open issue with label `backlog:implementation`.

Example:

```bash
gh issue list --state open --label "backlog:implementation" --limit 100 --json number,title,url,labels,updatedAt
```

Selection policy:

- Prefer oldest `updatedAt` first unless the user specifies a different ordering.
- If no matching issue exists, report that and stop without side effects.

### 2) Open PRs for this issue: discover, stall check, unblock (merge-first)

**Discover associated open PRs** by searching the repo for open PRs whose title or body references the issue (for example `Refs #<n>`, `Fixes #<n>`, `in:body` / `in:title` patterns, or the bare issue token where reliable). Use `gh pr list` with `--search` (GitHub search syntax) and `--json` so results are de-duplicated by PR number. Default scope is the current repository; if context is ambiguous, resolve repo once before searching.

**Sort** matching open PRs **oldest first** (prefer `createdAt` ascending; if unavailable, use PR number ascending as a tie-break).

**Stalled** means either:

- The PR branch **has merge conflicts** against its base (for example `mergeable` is `CONFLICTING`, or the PR is reported as not mergeable due to conflicts), or
- The PR has **failing checks** (any check run / status rollup conclusion indicating failure, such as `FAILURE` or `TIMED_OUT`, per `gh` JSON such as `statusCheckRollup`—treat red / failed required checks as stalled).

**Priority:** Prefer **merging existing PRs** that already carry issue work over **opening new implementation slices**. The objective for the issue is **full scope implemented and merged into `dev`**; the agent may choose how much of this run goes to unblocking and merging versus new work, but must not skip stall handling when open stalled PRs exist for the issue.

For each stalled PR, **oldest first**, read `.cursor/skills/fix-pr/SKILL.md` and execute that workflow for that PR until it is unblocked or fix-pr’s own outcome shows remaining blockers the agent cannot clear in this run. After merges or successful unblocks, **re-query** open PRs for the issue before starting new implementation, so the merge path stays preferred.

If there are no open PRs for the issue, or none are stalled, continue to scope (§3) and implementation (§4) as needed.

### 3) Determine scope for this run

For the selected issue, decide whether to implement fully or as a slice **only where merge-first work does not already satisfy the next step**:

- Prefer slicing/scoping criteria already present in the issue body (subtasks, phases, explicit boundaries).
- If not explicit, apply `.cursor/skills/implement-github-issue/SKILL.md` scope triage and choose one isolatable, testable slice when needed.
- Keep scope explicit and reviewable before changing code.

### 4) Execute strict implement-github-issue workflow

When new implementation (or follow-up slices) is required after §2–§3:

- Run the full readiness gate and SPEC updates if needed.
- Implement only SPEC-authorized behavior.
- Add/adjust tests (positive and negative where applicable) mapped to targeted ACs.
- Run relevant test commands until green.
- Create a PR targeting `dev` using neutral issue reference (`Refs #<n>` or equivalent) and never auto-close the issue.

### 5) Document implemented vs deferred work in PR

In the PR body, include:

- What was implemented in this PR.
- What remains deferred (if any) and why.
- Which ACs/spec sections are covered now vs left for follow-up.

If this run focused on unblocking, summarize that PR’s fix scope per `fix-pr` output style where helpful.

The reviewer must be able to tell whether the PR is full completion or a partial slice.

### 6) Decide issue completion status

Complete condition:

- The issue requirements are fully implemented and validated.
- No substantive work remains for the issue.
- All open PRs linked to this issue are successfully merged. If any linked PR is still open (including draft), the issue is not complete by definition.

Partial condition:

- Any material work remains (including intentionally deferred scope).
- Any PR linked to the issue remains open or unmerged.

### 7) Move label only when complete

If complete:

- Remove `backlog:implementation`
- Add `backlog:verification`

If partial:

- Leave `backlog:implementation` in place.

Example completion command:

```bash
gh issue edit <issue-number> --remove-label "backlog:implementation" --add-label "backlog:verification"
```

Do not apply `backlog:verification` while outstanding work remains.

## Output in chat

After completion, report:

- Issue number/title/URL implemented.
- Any **open PRs found** for the issue, **stall status**, and **fix-pr** actions or outcomes (per PR, oldest-first order).
- Scope decision (`FULL` or `SLICE`) and rationale.
- PR URL(s) and whether each represents full completion, partial delivery, or unblock-only work.
- Implemented work and deferred work summary.
- Label transition performed (or explicitly not performed, with reason).

## Guardrails

- Implement exactly one issue per run unless user requests batching.
- Never close the issue in this workflow.
- If `gh` is unavailable or fails, return prepared PR body text and exact commands needed for manual issue label transition.
- If labels change unexpectedly during the run, re-read current labels and apply the intended final state idempotently.
