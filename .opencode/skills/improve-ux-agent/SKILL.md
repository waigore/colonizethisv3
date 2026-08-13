---
name: improve-ux-agent
description: Autonomously runs suggest-player-ux-improvements then files one GitHub issue via create-github-issue with no user clarifications. Use when asked to improve UX, scout and file a UX issue, or run improve-ux-agent.
---

# Improve UX Agent (OpenCode)

## Source of truth

Use `.cursor/skills/improve-ux-agent/SKILL.md` as the authoritative workflow: no-clarification overrides, suggest-then-file sequence, and chat output.

## OpenCode adaptation

When running in OpenCode:

- Read and follow `.cursor/skills/improve-ux-agent/SKILL.md` end-to-end.
- Apply `.cursor/skills/suggest-player-ux-improvements/SKILL.md` strictly for discovery (with this agent’s no-clarification overrides).
- Apply `.cursor/skills/create-github-issue/SKILL.md` strictly for filing (skip mandatory clarifications; file from the suggest brief).
- Do not ask the user to choose a domain, confirm requirements, or approve filing unless `gh` hard-blocks progress.

## Required references

Before execution, read:

- `.cursor/skills/improve-ux-agent/SKILL.md`
- `.cursor/skills/suggest-player-ux-improvements/SKILL.md`
- `.cursor/skills/create-github-issue/SKILL.md`
