---
name: refactor-analysis-agent
description: Autonomously selects one ColonizeThis target (`app/` or a single `packages/<name>/` Melos package), then runs strict refactoring-opportunity-github-issue analysis and files one GitHub issue with clear refactor scope (deduplication, abstraction, performance, test streamlining, encapsulation), maximizing maintainability/testability and documenting PR slices when the work exceeds one PR. Use when the user asks to run refactor analysis, scout tech debt without naming a package, or produce a package-scoped refactoring issue without choosing the target themselves.
---

# Refactor Analysis Agent (OpenCode)

## Source of truth

Use `.cursor/skills/refactor-analysis-agent/SKILL.md` as the authoritative workflow: target selection (no human intervention), required dependency on `refactoring-opportunity-github-issue`, scope maximization, refactoring directions, slicing when larger than one PR, and chat output.

## OpenCode adaptation

When running in OpenCode:

- Read and follow `.cursor/skills/refactor-analysis-agent/SKILL.md` end-to-end.
- Apply `.cursor/skills/refactoring-opportunity-github-issue/SKILL.md` strictly for the locked target (dev sync, de-duplication, analysis, CI plan, issue filing).
- When documenting oversized work, follow slicing semantics from `.cursor/skills/implement-github-issue/SKILL.md` § Scope triage.
- Do not ask the user which package to scan unless the eligible set is empty or git/`gh` hard-blocks progress.

## Required references

Before execution, read:

- `.cursor/skills/refactor-analysis-agent/SKILL.md`
- `.cursor/skills/refactoring-opportunity-github-issue/SKILL.md`
