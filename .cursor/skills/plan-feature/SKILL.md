---
name: plan-feature
description: Plans a user-provided feature idea by reading SPEC and code (read-only), analyzing scope, proposing a design aligned with existing architecture, optionally clarifying underspecified requirements with focused questions, and opening a GitHub issue that documents requirements, assumptions, design, subtasks with dependencies, and acceptance criteria—without modifying the repository. Use when the user wants a feature scoped and filed as an issue before any implementation, spec edits, or PR work.
---

# Plan a feature and open a capturing GitHub issue (read-only)

Conventions: [shared.md](../shared.md). Filing mechanics: [create-github-issue](../create-github-issue/SKILL.md) §§ 6–7 (`gh issue create --body-file`, fallback).

## Scope

- Do not change the repo. Read SPEC/code. Ask focused clarification questions when requirements are underspecified, ambiguous, or contradictory (interactive by design).
- Create one GitHub issue with the plan. If the user asks to implement or edit SPEC, stop and use the normal implementation workflow.

## Design alignment

Reuse existing modules/UI patterns. Cite GDD (`SPEC/game/`) / TDD (`SPEC/program/`). Flutter UI vs Flame simulation stay separated; cross-panel via AppEventBus (`SPEC/program/app-ui-wiring.md`). New/changed screens: subtasks/ACs for [document-app-ui](../document-app-ui/SKILL.md). Player UX/gameplay: [update-game-manual](../update-game-manual/SKILL.md) (name chapters). Province identity is `(regionId, provinceId)` or prefixed ids. New abstractions only when nothing fits; flag SPEC impact.

## Workflow

1. **Capture** problem/outcome, constraints, inputs, open questions (mark unknowns).
2. **Clarify** only what unblocks planning. Spell out why it matters and options/tradeoffs. Do not invent product decisions.
3. **Investigate** SPEC gaps, concrete code owners (paths/types), existing tests to extend.
4. **Design** into the issue: requirements (must vs nice-to-have), assumptions, non-goals, design proposal (reuse first; proposed screen IDs or “TBD via `document-app-ui`”), SPEC impact, manual impact, dependency-aware subtasks, risks.
5. **ACs** Given/When/Then tied to requirements and cited SPEC.
6. **File** via `create-github-issue` create/fallback. Title imperative, ≤ ~80 chars.

## Body template

```markdown
## Summary
[Outcome and scope]

## Requirements
1. ...

## Assumptions
- ...

## Non-goals
- ...

## Spec and code context
- SPEC: ...
- Code: ...
- Tests: ...

## Design proposal
[...]

## Subtasks and dependencies
- [ ] **S1** — ... *(depends on: —)*

## SPEC impact (planning only — no edits in this issue’s workflow)
- ...

## Manual impact (planning only — no edits in this issue’s workflow)
- Chapters: ...
- Subtask: **Manual** — update `docs/manual/...` via `update-game-manual` (or justify non-update)

## Risks and edge cases
- ...

## Acceptance criteria
- [ ] Given ..., when ..., then ...
- [ ] Manual: Given player-visible behavior changes, when implementation merges, then `docs/manual/` chapter(s) [list] are updated (or non-update is justified in the PR).
```

Small features may drop subtasks; keep ACs. Facts vs inference: label hypotheses. The issue must be implementable without repeating discovery.
