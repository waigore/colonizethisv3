---
name: backlog-accept-agent
description: |-
  Picks one open GitHub issue labeled backlog:acceptance, applies accept-github-issue strictly to execute acceptance, posts the consolidated acceptance comment, and relabels to backlog:done (accept) or backlog:implementation (reject). Use when asked to run acceptance on the backlog, sign off ready issues, or move backlog:acceptance issues to a terminal state.

  Examples:
  - user: "Run acceptance on the backlog" → pick oldest backlog:acceptance issue, apply accept-github-issue, relabel
  - user: "Accept everything that's ready" → one issue per run; repeat runs for further issues
  - user: "Move the acceptance queue forward" → select, execute acceptance, post comment, move label
---

# Backlog Accept Agent (ColonizeThis)

## When this applies

Use when the user asks to run the backlog acceptance workflow and move one issue forward from `backlog:acceptance` — the final pipeline stage after `backlog:verification`.

## Required dependencies

Before executing this skill:

- Read and apply **`.cursor/skills/accept-github-issue/SKILL.md`** (and its `reference.md`) strictly for the acceptance method, category procedures (in-app AC execution / diff-invariance / vision inspection), evidence standards, hard-fail rules, and the comment template.
- Follow `AGENTS.md` and repository rules.

Do not weaken or substitute the acceptance method from `accept-github-issue`.

## Workflow

### 1) Select one candidate issue

```bash
gh issue list --state open --label "backlog:acceptance" --limit 100 --json number,title,url,labels,updatedAt
```

- Prefer oldest `updatedAt` first unless the user specifies a different ordering.
- A user-supplied issue number/URL overrides auto-selection (must be open and carry `backlog:acceptance`; if not, confirm with the user).
- If no matching issue exists, report that and stop without side effects.

### 2) Run strict accept-github-issue analysis

Apply `accept-github-issue` to the selected issue in full: classify (gameplay/UI, refactor, art generation), sync to latest `dev`, run common gates, execute the category procedure, and record per-AC evidence. The acceptance comment is posted per that skill's template.

### 3) Decide

- **Accept:** `accept-github-issue` outcome is ACCEPT — all ACs executed and passing on merged `dev`, no hard-fails.
- **Reject:** any FAIL AC or hard-fail gap remains.

### 4) Move the label

Create `backlog:done` once (ignore "already exists"):

```bash
gh label create "backlog:done" --color 0E8A16 --description "Backlog management: accepted by product owner agent; ready for final closure" || true
```

Replace `backlog:acceptance` with exactly one terminal label:

```bash
# accept
gh issue edit <n> --remove-label "backlog:acceptance" --add-label "backlog:done"

# reject
gh issue edit <n> --remove-label "backlog:acceptance" --add-label "backlog:implementation"
```

- `backlog:done` issues stay open for the product owner's final closure.
- Rejections rely on the gap list and follow-ups in the acceptance comment.
- Re-read labels (`gh issue view <n> --json labels`) immediately before editing; apply the final state idempotently; never leave both destination labels on the issue.

## Output in chat

Report: issue number/title/URL accepted, category, per-AC pass/fail summary, decision (ACCEPT/REJECT), posted comment confirmation, label transition performed.

## Guardrails

- Accept exactly one issue per run unless the user requests batching.
- Never close issues; never merge PRs in this workflow.
- If `gh` is unavailable or fails, return the prepared acceptance comment and exact label-edit commands for manual execution.
- If labels are unexpectedly changed by others during the run, re-read and apply the intended final state idempotently.
