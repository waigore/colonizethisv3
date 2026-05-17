---
name: backlog-refine-agent
description: Picks one open GitHub issue labeled backlog:refinement, applies refine-github-issue strictly against all comment feedback, updates the issue body directly, and relabels to backlog:review when fully resolved or backlog:clarification when uncertainties remain.
---

# Backlog Refine Agent (ColonizeThis)

## When this applies

Use when the user asks to run backlog refinement workflow and move one issue forward from `backlog:refinement`.

## Required dependencies

Before executing this skill:

- Read and apply `.cursor/skills/refine-github-issue/SKILL.md` strictly for comment-to-edit handling, SPEC contradiction handling, and clarification handling.
- Follow `AGENTS.md` and repository rules.

Do not weaken or substitute the refinement method from `refine-github-issue`.

## Workflow

### 1) Select one candidate issue

Pick any open issue with label `backlog:refinement`.

Example:

```bash
gh issue list --state open --label "backlog:refinement" --limit 100 --json number,title,url,labels,updatedAt
```

Selection policy:

- Prefer oldest `updatedAt` first unless the user specifies a different ordering.
- If no matching issue exists, report that and stop without side effects.

### 2) Gather issue context and feedback

For the selected issue:

- Load issue details (`title`, `body`, `labels`, `url`, `comments`).
- Inventory all actionable comment feedback items.
- Carefully review relevant `SPEC/` and repository code when needed to determine whether each feedback item can be resolved directly.

### 3) Apply strict refine-github-issue workflow

- Process each feedback item using `.cursor/skills/refine-github-issue/SKILL.md`.
- Update the issue body directly so accepted feedback is reflected in the issue text.
- Do not leave comment-raised requirements only in discussion threads.

Use:

```bash
gh issue edit <issue-number> --body-file path/to/new-body.md
```

### 4) Decide resolved vs uncertain

After refinement, decide whether all comment-raised items are adequately addressed.

Resolved condition:

- All inventoried feedback items are addressed in the updated issue body.
- No material uncertainty remains in issue scope, intended behavior, or acceptance criteria.
- Scope is reasonable and not too large for one coherent issue.

Uncertain condition (any one is enough):

- One or more feedback items cannot be confidently resolved from comments, SPEC, and code.
- Material ambiguity remains in issue scope, behavior, or AC definitions.
- Scope is too large and should be split before review.

### 5) Post uncertainty comment when needed

If uncertain:

- Post one consolidated issue comment listing every remaining uncertainty as a numbered list.
- Include what was checked (comments/SPEC/code) and what exact clarification is needed.

Example:

```bash
gh issue comment <issue-number> --body "$(cat <<'EOF'
Remaining uncertainties:
1. ...
2. ...
EOF
)"
```

### 6) Move label according to decision

Replace `backlog:refinement` with exactly one next-state label.

If resolved:

- Remove `backlog:refinement`
- Add `backlog:review`

If uncertain:

- Remove `backlog:refinement`
- Add `backlog:clarification`
- Product owner then performs clarification decisions while the issue is in `backlog:clarification`.

Example commands:

```bash
# resolved
gh issue edit <issue-number> --remove-label "backlog:refinement" --add-label "backlog:review"

# uncertain
gh issue edit <issue-number> --remove-label "backlog:refinement" --add-label "backlog:clarification"
```

Do not leave both destination labels on the same issue.

## Output in chat

After completion, report:

- Issue number/title/URL refined.
- Decision (`RESOLVED` or `UNCERTAIN`).
- Issue body update confirmation.
- Uncertainty comment confirmation (if posted).
- Label transition performed.

## Guardrails

- Refine exactly one issue per run unless user requests batching.
- Never close the issue in this workflow.
- If `gh` is unavailable or fails, return the prepared issue body text, uncertainty comment text (if needed), and exact label-edit commands for manual execution.
- If issue labels are unexpectedly changed by others during the run, re-read labels before editing and apply the intended final state idempotently.
