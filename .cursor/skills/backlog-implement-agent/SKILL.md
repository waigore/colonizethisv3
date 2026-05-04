---
name: backlog-implement-agent
description: Picks one open GitHub issue labeled backlog:implementation, applies implement-github-issue strictly to deliver a complete implementation or a valid scoped slice, opens a PR documenting implemented vs deferred work, and relabels the issue to backlog:verification only when no outstanding work remains.
---

# Backlog Implement Agent (ColonizeThis)

## When this applies

Use when the user asks to run backlog implementation workflow and move one issue forward from `backlog:implementation`.

## Required dependencies

Before executing this skill:

- Read and apply `.cursor/skills/implement-github-issue/SKILL.md` strictly for issue quality gate, SPEC-first behavior, slicing rules, implementation quality, testing, and PR workflow.
- Follow `AGENTS.md`, `CONTRIBUTING.md`, and repository rules.

Do not weaken or substitute the implementation method from `implement-github-issue`.

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

### 2) Determine scope for this run

For the selected issue, decide whether to implement fully or as a slice:

- Prefer slicing/scoping criteria already present in the issue body (subtasks, phases, explicit boundaries).
- If not explicit, apply `.cursor/skills/implement-github-issue/SKILL.md` scope triage and choose one isolatable, testable slice when needed.
- Keep scope explicit and reviewable before changing code.

### 3) Execute strict implement-github-issue workflow

- Run the full readiness gate and SPEC updates if needed.
- Implement only SPEC-authorized behavior.
- Add/adjust tests (positive and negative where applicable) mapped to targeted ACs.
- Run relevant test commands until green.
- Create a PR targeting `dev` using neutral issue reference (`Refs #<n>` or equivalent) and never auto-close the issue.

### 4) Document implemented vs deferred work in PR

In the PR body, include:

- What was implemented in this PR.
- What remains deferred (if any) and why.
- Which ACs/spec sections are covered now vs left for follow-up.

The reviewer must be able to tell whether the PR is full completion or a partial slice.

### 5) Decide issue completion status

Complete condition:

- The issue requirements are fully implemented and validated.
- No substantive work remains for the issue.
- All open PRs linked to this issue are successfully merged. If any linked PR is still open (including draft), the issue is not complete by definition.

Partial condition:

- Any material work remains (including intentionally deferred scope).
- Any PR linked to the issue remains open or unmerged.

### 6) Move label only when complete

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
- Scope decision (`FULL` or `SLICE`) and rationale.
- PR URL and whether it represents full completion or partial delivery.
- Implemented work and deferred work summary.
- Label transition performed (or explicitly not performed, with reason).

## Guardrails

- Implement exactly one issue per run unless user requests batching.
- Never close the issue in this workflow.
- If `gh` is unavailable or fails, return prepared PR body text and exact commands needed for manual issue label transition.
- If labels change unexpectedly during the run, re-read current labels and apply the intended final state idempotently.
