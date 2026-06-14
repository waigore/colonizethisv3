---
name: create-github-issue
description: |-
  Turns an informal issue report into a structured GitHub issue with reproduction steps, expected vs actual behavior, read-only SPEC/code investigation, and a proposed fix scope—without modifying the repository.

  Always clarify requirements with the user first by reading relevant specs/code, analyzing the report against current behavior, and presenting requirement clarifications as a numbered list.

  Attempts to open the issue via GitHub CLI (gh); falls back to a paste-ready draft if gh is missing, unauthenticated, or creation fails.

  Use when the user describes a bug, regression, or gap and wants a filed issue, triage narrative, or fix direction before implementation.
---

**Thin Grok shim** (repo `.grok/skills/`).

Source of truth: `.cursor/skills/create-github-issue/SKILL.md`

Read the complete file and follow its strict read-only scope, mandatory clarification step, investigation, drafting, and gh creation/fallback workflow exactly.
