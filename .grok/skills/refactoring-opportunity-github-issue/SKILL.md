---
name: refactoring-opportunity-github-issue
description: Analyzes `app/` or one `packages/*` workspace package on the latest `origin/dev` baseline for refactoring opportunities using ColonizeThis `.cursor/rules` (plus sound Dart/Flutter practice), de-duplicates against open GitHub issues, proposes focused CI enforcement (AST-first; extend existing gates before adding new ones), and produces a structured GitHub issue another developer can implement. Use when the user asks for refactor scouting, package-level tech-debt triage, or a filing-ready issue from evidence-based findings scoped to app or a package.
---

**Thin Grok shim** (repo `.grok/skills/`).

Source of truth: `.cursor/skills/refactoring-opportunity-github-issue/SKILL.md` (plus its `references/ci-and-rules.md`).

Read the SKILL.md in full plus the references file it cites. Follow the strict scope (app/ or single packages/*), dev baseline sync, de-dupe, rule loading, analysis, CI proposal, and issue drafting/filing process exactly. Related skills (create-github-issue, document-app-ui, review-github-issue, verify-github-issue) are called out inside the authoritative copy.
