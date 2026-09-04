---
name: backlog-accept-agent
description: |-
  Picks one open GitHub issue labeled backlog:acceptance, applies accept-github-issue strictly to execute acceptance, posts the consolidated acceptance comment, and relabels to backlog:done (accept) or backlog:implementation (reject). Use when asked to run acceptance on the backlog, sign off ready issues, or move backlog:acceptance issues to a terminal state.

  Examples:
  - user: "Run acceptance on the backlog" → pick oldest backlog:acceptance issue, apply accept-github-issue, relabel
  - user: "Accept everything that's ready" → one issue per run; repeat runs for further issues
  - user: "Move the acceptance queue forward" → select, execute acceptance, post comment, move label
---

**Thin Grok shim** (repo `.grok/skills/`).

Source of truth: `.cursor/skills/backlog-accept-agent/SKILL.md`

Read the full file and follow it exactly.
