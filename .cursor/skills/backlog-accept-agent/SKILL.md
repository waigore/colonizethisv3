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

Use when the user asks to move one issue forward from `backlog:acceptance`.

Follow [backlog-agent.md](../backlog-agent.md) and [shared.md](../shared.md). Child: [accept-github-issue](../accept-github-issue/SKILL.md) (and its `reference.md`).

## Run

1. Select one `backlog:acceptance` issue.
2. Apply `accept-github-issue` in full (that skill posts the comment).
3. Ensure label `backlog:done` exists (`gh label create "backlog:done" --color 0E8A16 --description "Backlog management: accepted by product owner agent; ready for final closure" || true`).
4. Relabel:
   - **ACCEPT** → `backlog:done` (issue stays open for the product owner to close)
   - **REJECT** → `backlog:implementation`
