---
name: backlog-implement-agent
description: Optimizes code throughput across open issues labeled backlog:implementation. Each run does substantial work and never waits for CI, reviews, or merges. Unblocks stalled PRs (conflicts, failing checks, or open with checks not running) via strict fix-pr toward merge readiness, then moves on. Only PRs that reference those labelled issues. Applies strict implement-github-issue for new work. Each PR targets exactly one issue. Relabels to backlog:verification only when an issue is fully done.
---

# Backlog Implement Agent (ColonizeThis)

## When this applies

Use when the user asks to run backlog implementation work and push `backlog:implementation` issues forward.

## Required dependencies

Read and apply these strictly — do not invent lighter substitutes:

- `.cursor/skills/implement-github-issue/SKILL.md` — readiness gate, SPEC-first behavior, scope/slicing, tests, PR workflow.
- `.cursor/skills/fix-pr/SKILL.md` — used whenever an in-scope PR is stalled. The agent discovers the PR via `gh` (this run’s labelled issues); then apply that skill’s workflow end-to-end for that PR number/URL.

Also follow `AGENTS.md`, `CONTRIBUTING.md`, and repository rules.

## Operating principles

1. **Throughput across issues.** Optimize for productive code shipped across the set of open `backlog:implementation` issues. A run may touch **multiple issues** — pick whatever combination of work moves the most quality code forward.

2. **One issue per PR.** Every PR opened or pushed to in this run targets exactly **one** issue (`Refs #<n>`). Never bundle multiple issues into one PR.

3. **Never wait.** Do not wait for CI, reviews, or merges at any point. After any push, PR creation, or successful unblock, move on to the next useful unit of work in the same run.

4. **Unblock first, then move on (goal: merge-ready PRs).** For **open PRs that reference a candidate `backlog:implementation` issue** only: if the PR is **stalled**, unblock it via strict `fix-pr` before opening new implementation work for that same issue. Treat as stalled when **any** of these holds: merge conflicts against the PR’s **configured base branch** (read from PR metadata — often `dev`, always verify), **failing checks**, or the PR is **open but checks are not running** (for example required workflows not triggered, stuck pending, or branch/base state that blocks CI until updated). Prefer the oldest stalled PR first. After pushing fixes or bringing the branch current with its base, **do not** wait for remote CI, reviews, or merge confirmation — **no dallying**; move on immediately. This is a hard rule.

5. **Agent picks scope.** Use issue-defined slicing where it exists; otherwise apply `implement-github-issue` scope triage. No fixed slice-size requirement is imposed here — implement as much as is responsibly testable and reviewable in one PR.

6. **SPEC-first and tested.** All new behavior must be SPEC-authorized. Add positive and negative tests mapped to ACs; run relevant tests until green before pushing.

7. **Disclose scope in the PR.** PR body states what was implemented, what was deferred and why, and which ACs/spec sections are covered now vs follow-up.

8. **Conservative label transitions.** Move an issue from `backlog:implementation` to `backlog:verification` only when the issue is fully implemented **and** every linked PR is merged. If anything is still open or deferred, leave the label. Never close the issue.

## Selecting work

- Candidate issues: open issues with label `backlog:implementation`.
- Candidate PRs: **only** open PRs that reference a candidate issue (title/body refs like `Refs #<n>`, `Fixes #<n>`). Do not run `fix-pr` for unrelated open PRs. Use `gh pr list --search` and `gh issue list --state open --label "backlog:implementation"`.
- For each candidate PR, read **base branch** from PR metadata (`gh pr view`) and use that (not a hardcoded branch name) when merging/rebasing to resolve drift or conflicts — `dev` is typical but not guaranteed.
- A run may handle several issues; for each, follow the principles above.

## Output in chat

For each issue touched, report:

- Issue number / title / URL.
- Whether the run unblocked a stalled PR (which one) or opened/advanced a new PR (which one).
- One-line scope summary (implemented vs deferred).
- Label transition performed, or explicitly not performed with reason.

## Guardrails

- Never wait for CI, reviews, or merges (including after a `fix-pr` push aimed at merge readiness).
- Never bundle multiple issues into one PR.
- Never close an issue in this workflow.
- If `gh` is unavailable, return prepared PR body text and the exact commands needed for manual follow-up.
