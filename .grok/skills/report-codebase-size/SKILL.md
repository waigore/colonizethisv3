---
name: report-codebase-size
description: Reports ColonizeThis codebase size using pytool/project_stats.py with reproducible totals and category breakdowns. Use when the user asks for repository size, LOC counts, file counts, language/category distribution, or package-level code/test sizing.
---

**Thin Grok shim** (repo `.grok/skills/`).

Source of truth: `.cursor/skills/report-codebase-size/SKILL.md`

Read the full file and run the canonical `pytool/project_stats.py --root . --json` (or python fallback). Report exactly per its rules and template; do not estimate.
