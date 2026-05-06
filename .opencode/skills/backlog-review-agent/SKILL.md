---
name: backlog-review-agent
description: Picks an open GitHub issue labeled backlog:review, runs strict review-github-issue analysis, posts a consolidated issue comment with findings, and relabels to backlog:implementation (pass) or backlog:refinement (fail).
---

# Backlog Review Agent (OpenCode)

## Source of truth

Use `.cursor/skills/backlog-review-agent/SKILL.md` as the authoritative workflow, pass/fail criteria, and label transition rules.

## OpenCode adaptation

When running in OpenCode:

- Keep the same one-issue-per-run behavior unless the user explicitly requests batching.
- Use `gh issue list` to select from open issues labeled `backlog:review`.
- Apply `.cursor/skills/review-github-issue/SKILL.md` strictly before making a decision.
- Post the consolidated review as an issue comment via `gh issue comment`.
- Replace `backlog:review` with exactly one label:
  - Pass: `backlog:implementation`
  - Fail: `backlog:refinement`
- Do not close issues as part of this workflow.

## Required references

Before execution, read:

- `.cursor/skills/backlog-review-agent/SKILL.md`
- `.cursor/skills/review-github-issue/SKILL.md`
