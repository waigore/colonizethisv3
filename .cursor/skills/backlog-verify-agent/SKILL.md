---
name: backlog-verify-agent
description: Picks one open GitHub issue labeled backlog:verification, applies verify-github-issue strictly to confirm implementation completeness, posts a verification comment, and relabels to backlog:acceptance when complete or backlog:implementation when gaps remain.
---

# Backlog Verify Agent (ColonizeThis)

Use when the user asks to move one issue forward from `backlog:verification`.

Follow [backlog-agent.md](../backlog-agent.md) and [shared.md](../shared.md). Child: [verify-github-issue](../verify-github-issue/SKILL.md).

## Run

1. Select one `backlog:verification` issue.
2. Apply `verify-github-issue` in full (that skill posts the comment).
3. Relabel:
   - **Complete** → `backlog:acceptance`
   - **Gaps remain** → `backlog:implementation`
