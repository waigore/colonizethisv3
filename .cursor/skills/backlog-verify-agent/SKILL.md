---
name: backlog-verify-agent
description: Picks one open GitHub issue labeled backlog:verification, applies verify-github-issue strictly to confirm implementation completeness, posts a verification comment, and relabels to backlog:acceptance when complete or backlog:implementation when gaps remain.
---

# Backlog Verify Agent (ColonizeThis)

## When this applies

Use when the user asks to run backlog verification workflow and move one issue forward from `backlog:verification`.

## Required dependencies

Before executing this skill:

- Read and apply `.cursor/skills/verify-github-issue/SKILL.md` strictly for verification method, evidence standards, gap reporting, and posting the comment on the issue.
- Follow `AGENTS.md` and repository rules.

Do not weaken or substitute the verification method from `verify-github-issue`.

## Workflow

### 1) Select one candidate issue

Pick any open issue with label `backlog:verification`.

Example:

```bash
gh issue list --state open --label "backlog:verification" --limit 100 --json number,title,url,labels,updatedAt
```

Selection policy:

- Prefer oldest `updatedAt` first unless the user specifies a different ordering.
- If no matching issue exists, report that and stop without side effects.

### 2) Run strict verify-github-issue analysis

For the selected issue:

- Load issue details (`title`, `body`, `labels`, `comments`, `url`).
- Apply `.cursor/skills/verify-github-issue/SKILL.md` strictly to verify whether implementation is complete with no gaps.
- Enumerate every remaining gap with concrete evidence when any are found.

### 3) Post verification comment

Post one consolidated issue comment with:

- Verification outcome (`COMPLETE` or `GAPS REMAIN`).
- AC/spec/test mapping summary per `verify-github-issue`.
- Explicit gap list and required follow-ups when incomplete.
- When complete, state clearly that verification found no material gaps (per `verify-github-issue`); do not instruct closing the issue.

Use `gh` to post:

```bash
gh issue comment <issue-number> --body "$(cat <<'EOF'
<verification comment>
EOF
)"
```

### 4) Decide completion status

Complete condition:

- `verify-github-issue` confirms full implementation with no remaining material gaps.

Incomplete condition:

- Any unresolved implementation/spec/test/AC gap remains.

### 5) Move label according to decision

Replace `backlog:verification` with exactly one next-state label.

If complete:

- Remove `backlog:verification`
- Add `backlog:acceptance`
- Product owner then performs final acceptance decisioning while the issue is in `backlog:acceptance`.

If incomplete:

- Remove `backlog:verification`
- Add `backlog:implementation`

Example commands:

```bash
# complete
gh issue edit <issue-number> --remove-label "backlog:verification" --add-label "backlog:acceptance"

# incomplete
gh issue edit <issue-number> --remove-label "backlog:verification" --add-label "backlog:implementation"
```

Do not leave both destination labels on the same issue.

## Output in chat

After completion, report:

- Issue number/title/URL verified.
- Decision (`COMPLETE` or `INCOMPLETE`).
- Posted comment confirmation.
- Label transition performed.

## Guardrails

- Verify exactly one issue per run unless user requests batching.
- Never close the issue in this workflow.
- If `gh` is unavailable or fails, return the prepared verification comment and exact label-edit commands for manual execution.
- If issue labels are unexpectedly changed by others during the run, re-read labels before editing and apply the intended final state idempotently.
