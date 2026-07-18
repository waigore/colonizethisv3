---
name: refactor-analysis-agent
description: Autonomously selects one ColonizeThis target (`app/` or a single `packages/<name>/` Melos package), then runs strict refactoring-opportunity-github-issue analysis and files one GitHub issue with clear refactor scope (deduplication, abstraction, performance, test streamlining, encapsulation), maximizing maintainability/testability and documenting PR slices when the work exceeds one PR. Use when the user asks to run refactor analysis, scout tech debt without naming a package, or produce a package-scoped refactoring issue without choosing the target themselves.
---

**Thin Grok shim** (repo `.grok/skills/`).

Source of truth: `.cursor/skills/refactor-analysis-agent/SKILL.md`

Read the full file and strictly follow its target-selection policy and required dependency on refactoring-opportunity-github-issue (plus cross-references).
