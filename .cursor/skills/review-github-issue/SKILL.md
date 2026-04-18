---
name: review-github-issue
description: |-
  Review a GitHub issue against existing code, specs, and tests to identify gaps, inconsistencies, and misalignments. Builds a consolidated comment highlighting each problem, priority, and suggested remedy. Use when user asks to review, audit, or triage an issue; to find gaps before implementation; or to prepare for a fix PR.

  Examples:
  - user: "Review issue #42" → load issue, trace ACs to code/specs/tests, output gap analysis with priorities
  - user: "Audit this bug report for inconsistencies" → identify what issue intends to solve, verify each item aligns
  - user: "Find gaps in issue before starting work" → rigorous review against existing implementation
  - user: "Triage this issue against our specs" → map issue items to SPEC sections, flag contradictions
---

# Review a GitHub Issue (ColonizeThis)

This skill is maintained at [`.opencode/skills/review-github-issue/SKILL.md`](.opencode/skills/review-github-issue/SKILL.md).

The unified skill body contains:
- Full workflow (load issue → identify purpose → trace to code/specs/tests → identify gaps → assess priority → build consolidated comment)
- Output template
- Quality bar
- Related skill references

**Canonical location:** `.opencode/skills/review-github-issue/`

**References:** `.opencode/skills/review-github-issue/references/review-reference.md`
