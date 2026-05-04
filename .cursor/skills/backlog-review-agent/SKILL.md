---
name: backlog-review-agent
description: Picks an open GitHub issue labeled backlog:review, performs a strict purpose↔method review using review-github-issue criteria, posts a consolidated review comment, and advances the issue to backlog:implementation or backlog:refinement based on whether all P0/P1/P2 items are addressed.
---

# Backlog Review Agent (ColonizeThis)

## When this applies

Use when the user asks to run backlog review workflow and move one issue forward from `backlog:review`.

## Required dependencies

Before executing this skill:

- Read and apply `.cursor/skills/review-github-issue/SKILL.md` strictly for analysis method, priority assignment, and review output quality bar.
- Follow `AGENTS.md` and repository rules.

Do not weaken or substitute the review method from `review-github-issue`.

## Workflow

### 1) Select one candidate issue

Pick any open issue with label `backlog:review`.

Example:

```bash
gh issue list --state open --label "backlog:review" --limit 100 --json number,title,url,labels,updatedAt
```

Selection policy:

- Prefer oldest `updatedAt` first unless the user specifies a different ordering.
- If no matching issue exists, report that and stop without side effects.

### 2) Run strict review-github-issue analysis

For the selected issue:

- Load issue details (`title`, `body`, `labels`, `comments`, `url`).
- Perform the full purpose↔method review exactly as defined in `review-github-issue`.
- Identify all findings with explicit priorities (`P0`, `P1`, `P2`) and concrete remedies.

### 3) Build and post consolidated review comment

Post a single structured issue comment containing:

- Purpose statement.
- Purpose↔method findings with evidence and remedy.
- Internal consistency findings.
- Summary with `P0/P1/P2` counts and decision.

Use `gh` to post:

```bash
gh issue comment <issue-number> --body "$(cat <<'EOF'
<review comment>
EOF
)"
```

### 4) Decide pass vs fail

Pass condition:

- All `P0/P1/P2` concerns are addressed in the issue as currently written.
- In practice, this means no unresolved `P0`, `P1`, or `P2` review findings remain.

Fail condition:

- Any unresolved `P0`, `P1`, or `P2` finding exists.

### 5) Move label according to decision

Replace `backlog:review` with exactly one next-state label.

If pass:

- Remove `backlog:review`
- Add `backlog:implementation`

If fail:

- Remove `backlog:review`
- Add `backlog:refinement`

Example commands:

```bash
# pass
gh issue edit <issue-number> --remove-label "backlog:review" --add-label "backlog:implementation"

# fail
gh issue edit <issue-number> --remove-label "backlog:review" --add-label "backlog:refinement"
```

Do not leave both destination labels on the same issue.

## Output in chat

After completion, report:

- Issue number/title/URL reviewed.
- Decision (`PASS` or `FAIL`).
- Posted comment confirmation.
- Label transition performed.

## Guardrails

- Review exactly one issue per run unless user requests batching.
- Never close the issue in this workflow.
- If `gh` is unavailable or fails, return the prepared comment and exact label-edit commands for manual execution.
- If issue labels are unexpectedly changed by others during the run, re-read labels before editing and apply the intended final state idempotently.
