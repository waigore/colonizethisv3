---
name: review-game-manual-agent
description: Reviews one ColonizeThis player game-manual chapter for STYLE_GUIDE conformance and SPEC-accurate instructions/UI references, then files one GitHub issue listing every required alignment change. Picks a chapter if none is named. Use when asked to review the game manual or a handbook chapter, or to run review-game-manual-agent.
---

# Review game-manual agent (OpenCode)

## Source of truth

Use `.cursor/skills/review-game-manual-agent/SKILL.md` as the authoritative workflow: one chapter, style vs `docs/manual/STYLE_GUIDE.md`, accuracy vs cited SPECs and `SPEC/ui/screen-registry.md`, then one GitHub issue.

## OpenCode adaptation

When running in OpenCode:

- Read and follow `.cursor/skills/review-game-manual-agent/SKILL.md` end-to-end.
- Apply `.cursor/skills/create-github-issue/SKILL.md` for filing only (skip mandatory clarifications).
- Do not ask which chapter to review unless no numbered chapter remains without an open alignment issue.
- Do not edit the handbook in this run. Point implementers at `.cursor/skills/update-game-manual/SKILL.md`.

## Required references

Before execution, read:

- `.cursor/skills/review-game-manual-agent/SKILL.md`
- `docs/manual/STYLE_GUIDE.md`
- `.cursor/skills/create-github-issue/SKILL.md`
