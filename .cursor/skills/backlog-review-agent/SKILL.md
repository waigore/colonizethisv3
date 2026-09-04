---
name: backlog-review-agent
description: Picks an open GitHub issue labeled backlog:review, performs a strict purpose↔method review using review-github-issue criteria, posts a consolidated review comment, and advances the issue to backlog:implementation or backlog:refinement based on whether all P0/P1/P2 items are addressed.
---

# Backlog Review Agent (ColonizeThis)

Use when the user asks to move one issue forward from `backlog:review`.

Follow [backlog-agent.md](../backlog-agent.md) and [shared.md](../shared.md). Child: [review-github-issue](../review-github-issue/SKILL.md) (this wrapper **posts** the review comment; the child skill is interactive about posting when run alone).

## Run

1. Select one `backlog:review` issue.
2. Apply `review-github-issue` in full. Post the consolidated comment with `gh issue comment`.
3. Relabel:
   - **Pass** (no unresolved P0/P1/P2) → `backlog:implementation`
   - **Fail** (any unresolved P0/P1/P2) → `backlog:refinement`
