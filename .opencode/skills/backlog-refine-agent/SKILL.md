---
name: backlog-refine-agent
description: Picks one open GitHub issue labeled backlog:refinement, applies refine-github-issue strictly to comment feedback, updates the issue body directly, then relabels to backlog:review if fully resolved or backlog:clarification if uncertainties remain.
---

# Backlog Refine Agent (OpenCode)

## Source of truth

Use `.cursor/skills/backlog-refine-agent/SKILL.md` as the authoritative workflow, uncertainty criteria, and label transition rules.

## OpenCode adaptation

When running in OpenCode:

- Keep the same one-issue-per-run behavior unless the user explicitly requests batching.
- Use `gh issue list` to select from open issues labeled `backlog:refinement`.
- Apply `.cursor/skills/refine-github-issue/SKILL.md` strictly before deciding label transition.
- Update the issue body directly via `gh issue edit --body-file`.
- Before escalating uncertainty, check issue comments, relevant `SPEC/`, and code for resolvable answers.
- If unresolved uncertainties remain, post one consolidated uncertainty comment.
- Replace `backlog:refinement` with exactly one label:
  - Resolved: `backlog:review`
  - Uncertain: `backlog:clarification`
- When relabeled to `backlog:clarification`, the product owner performs clarification decisions while the agent controls label transitions.
- Never close issues in this workflow.

## Required references

Before execution, read:

- `.cursor/skills/backlog-refine-agent/SKILL.md`
- `.cursor/skills/refine-github-issue/SKILL.md`
