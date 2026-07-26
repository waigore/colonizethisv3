---
name: backlog-accept-agent
description: Picks one open GitHub issue labeled backlog:acceptance, applies accept-github-issue strictly to execute acceptance, posts the consolidated acceptance comment, and relabels to backlog:done (accept) or backlog:implementation (reject).
---

# Backlog Accept Agent (OpenCode)

## Source of truth

Use **`.cursor/skills/backlog-accept-agent/SKILL.md`** as the authoritative workflow, completion criteria, comment requirements, and label transition rules.

## OpenCode adaptation

When running in OpenCode:

- Keep the same one-issue-per-run behavior unless the user explicitly requests batching.
- Use `gh issue list --label "backlog:acceptance"` to select (oldest `updatedAt` first), or take a user-supplied issue number/URL.
- Apply `.cursor/skills/accept-github-issue/SKILL.md` strictly before deciding (in OpenCode, drive the app via the `dart_*` MCP tools with the `flutter test integration_test -d macos|linux` fallback it describes).
- Post one consolidated acceptance comment via `gh issue comment`.
- Replace `backlog:acceptance` with exactly one label:
  - Accept: `backlog:done` (create the label on first use)
  - Reject: `backlog:implementation`
- Do not close issues in this workflow.

## Required references

Before execution, read:

- `.cursor/skills/backlog-accept-agent/SKILL.md`
- `.cursor/skills/accept-github-issue/SKILL.md`
- `.cursor/skills/accept-github-issue/reference.md`
