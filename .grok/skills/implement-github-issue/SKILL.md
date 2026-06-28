---
name: implement-github-issue
description: Implements work from a GitHub issue number or URL after validating the issue for clear problem statement, design or technical approach, and test-targetable acceptance criteria; updates SPEC and ACs when gaps exist; adds positive and negative tests mapped to ACs; runs tests; keeps at most one open PR per issue on dev (stack slices as commits on that PR; if an early merge lands before the issue is finished, open one follow-up PR for the remainder) with a conventional-prefix title; references the issue without closing it. Use when the user gives an issue ID or URL and wants implementation with tests and a non-closing PR.
---

**Thin Grok shim** (repo `.grok/skills/`).

Source of truth: `.cursor/skills/implement-github-issue/SKILL.md` (plus its sibling `reference.md`).

Read the full SKILL.md and reference.md. Enforce the non-negotiables (SPEC, one PR per issue targeting dev, conventional title with Refs #N, test gates, etc.), issue quality gate, scope triage, and full workflow exactly.
