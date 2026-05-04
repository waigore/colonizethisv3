---
name: backlog-verify-agent
description: Picks one open GitHub issue labeled backlog:verification, applies verify-github-issue strictly to verify completion, posts a consolidated verification comment, and relabels to backlog:acceptance (complete) or backlog:implementation (gaps remain).
---

# Backlog Verify Agent (OpenCode)

## Source of truth

Use `.cursor/skills/backlog-verify-agent/SKILL.md` as the authoritative workflow, completion criteria, comment requirements, and label transition rules.

## OpenCode adaptation

When running in OpenCode:

- Keep the same one-issue-per-run behavior unless the user explicitly requests batching.
- Use `gh issue list` to select from open issues labeled `backlog:verification`.
- Apply `.cursor/skills/verify-github-issue/SKILL.md` strictly before deciding.
- Post one consolidated verification comment via `gh issue comment`.
- If complete with no gaps, include that the issue is ready to close.
- Replace `backlog:verification` with exactly one label:
  - Complete: `backlog:acceptance`
  - Incomplete: `backlog:implementation`
- When relabeled to `backlog:acceptance`, the product owner performs final acceptance decisioning while the agent controls label transitions.
- Do not close issues in this workflow.

## Required references

Before execution, read:

- `.cursor/skills/backlog-verify-agent/SKILL.md`
- `.cursor/skills/verify-github-issue/SKILL.md`
