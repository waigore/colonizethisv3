---
name: refine-github-issue
description: |-
  Refines an open GitHub issue using feedback in issue comments: tightens reproduction steps and root-cause analysis, resolves internal inconsistencies, and clarifies subtask priorities and dependencies. Works each feedback item explicitly—updates the issue body when the point is accurate and reasonable, otherwise returns numbered clarification questions for the user. Use when the user asks to address issue feedback, refine an issue from reviewer comments, reconcile comments with the description, or refresh an issue after triage discussion.

  Examples:
  - user: "Apply the feedback on #88" → map each comment to concrete edits or numbered pushbacks
  - user: "Update the issue from the last three comments" → merge non-conflicting clarifications into the body
  - user: "Comments say repro is wrong—fix the issue text" → verify against thread, edit body or ask numbered questions if ambiguous
---

# Refine a GitHub issue from comment feedback (ColonizeThis)

## When this applies

The user gives a **GitHub issue number** or **URL** and wants the **issue body** brought in line with **feedback already written in issue comments** (review, triage, or author follow-ups)—not greenfield drafting of a new issue.

**Related skills:** Use [review-github-issue](../review-github-issue/SKILL.md) for a **fresh** purpose–method review before implementation. Use [verify-github-issue](../verify-github-issue/SKILL.md) to check **implementation/SPEC/tests** against acceptance criteria.

## Non-negotiables

Follow **[AGENTS.md](../../../AGENTS.md)** and **[CONTRIBUTING.md](../../../CONTRIBUTING.md)**. If comment feedback would change **game or product behavior** in a way that **contradicts `SPEC/`**, do **not** silently rewrite the issue to match the comment—**flag it** for the user (and point to the SPEC section) until SPEC and issue align.

## What “feedback” means here

Treat each distinct point in comments as one **feedback item** (one bullet in the thread, one numbered reviewer note, or one clearly separable paragraph). Typical themes:

| Theme | Agent checks | Body updates might include |
|-------|----------------|---------------------------|
| **Reproduction** | Steps complete, ordered, environment-specific where needed, expected vs actual consistent with title | Rewritten **Repro** / **Steps** sections; split flaky vs deterministic symptoms |
| **Root cause / analysis** | Hypotheses labeled vs facts; gaps vs symptoms; whether proposed cause matches scope | Clearer **RCA** / **Analysis**; open questions moved to **Open questions** |
| **Description consistency** | Title vs body; AC vs narrative; scope vs labels; duplicate or conflicting requirements | Single source of truth in body; remove contradictions |
| **Subtasks: priority & dependencies** | Ordering, blockers, parallelizable work, “must do first” edges | **Subtasks** table or numbered list with **Priority** and **Depends on** (or explicit **Phase 1 / 2**) |

## Workflow

### 1. Load issue and full comment thread

```bash
gh issue view <n> --json title,body,state,labels,url,comments
```

Confirm **open** unless the user explicitly asked about a closed issue. Read **comments in chronological order**; if GitHub **review threads** or **quoted replies** matter, pull the web view or `gh api` as needed so no feedback is missed.

### 2. Inventory feedback items

Build an internal list: **F1, F2, …** with (a) short quote or paraphrase, (b) author, (c) which theme(s) above.

Merge **duplicate** comments into one item. If two comments **conflict**, keep both as separate items and resolve in step 4.

### 3. Evaluate each item (before editing)

For each **F*k***:

- **Accurate and reasonable** for the issue’s stated goal → plan a **concrete body edit** (which section, what text).
- **Partly right** → plan a **partial** edit and note what remains uncertain.
- **Wrong, speculative without evidence, or contradicts SPEC/repo facts** → **do not** adopt; prepare a **numbered clarification** for the user (why it was not applied, what evidence would change the decision).
- **Needs repo verification** (e.g. “repro step 3 is wrong”) → use read-only checks (code, SPEC, local repro) **only as far as needed** to decide; if still ambiguous after a reasonable check, **escalate** with a numbered question instead of guessing.

### 4. Update the issue body (when appropriate)

Prefer **minimal edits**: fix the described gap without unrelated rewrites.

- Prepare the full new body (keep existing headings/structure when they work).
- Apply:

```bash
# Write the new body to a file, then:
gh issue edit <n> --body-file path/to/new-body.md
```

Re-fetch the issue JSON to confirm the edit landed.

**Optional but useful:** For non-trivial edits, add a **short issue comment** summarizing which feedback threads were incorporated (no essay; no blame).

### 5. Report back to the user

Always use **numbered lists** for anything that was **not** applied or needs **author decision**.

Suggested output shape:

```markdown
Issue: #<n> <url>

## Body updated
- F1: [one line what changed]
- F3: …

## Needs your input
1. F2: [why not applied or what decision is needed]
2. F5: …

## Optional follow-up
- …
```

## Quality bar

- **Every** inventoried feedback item appears in **Body updated** or **Needs your input**—no silent drops.
- Edits are **traceable** to comment content (paraphrase is fine; do not invent requirements the comments did not imply).
- Dependencies: make **cycles** explicit if detected; do not pretend a DAG exists when comments imply a loop.

## Anti-patterns

- Rewriting the issue from scratch when small patches suffice.
- Treating the latest comment as automatically authoritative over earlier agreed text without reconciliation.
- Closing contradictions with the **issue author** by editing the body when the contradiction is **SPEC vs comment**—stop and ask the user.
