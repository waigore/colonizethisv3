---
name: backlog-refine-agent
description: Picks one open GitHub issue labeled backlog:refinement, applies refine-github-issue strictly against all comment feedback, updates the issue body directly, and relabels to backlog:review when fully resolved or backlog:clarification when uncertainties remain.
---

# Backlog Refine Agent (ColonizeThis)

Use when the user asks to move one issue forward from `backlog:refinement`.

Follow [backlog-agent.md](../backlog-agent.md) and [shared.md](../shared.md). Child: [refine-github-issue](../refine-github-issue/SKILL.md).

## Run

1. Select one `backlog:refinement` issue.
2. Apply `refine-github-issue` in full (`gh issue edit --body-file`).
3. Relabel:
   - **Resolved** (all inventoried feedback in the body; no material uncertainty; scope still one issue) → `backlog:review`
   - **Uncertain** (any feedback cannot be resolved from comments/SPEC/code, or scope should split) → `backlog:clarification`, and post one numbered-list comment of remaining uncertainties
