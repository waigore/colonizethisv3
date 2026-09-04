---
name: implement-github-issue
description: Implements work from a GitHub issue number or URL after validating the issue for clear problem statement, design or technical approach, and test-targetable acceptance criteria; updates SPEC and ACs when gaps exist; adds positive and negative tests mapped to ACs; runs tests; keeps at most one open PR per issue on dev (stack slices as commits on that PR; if an early merge lands before the issue is finished, open one follow-up PR for the remainder) with a conventional-prefix title; references the issue without closing it. Use when the user gives an issue ID or URL and wants implementation with tests and a non-closing PR.
---

# Implement a fix from a GitHub issue (ColonizeThis)

The user gives a GitHub **issue number** or **URL** and wants the work **implemented**—not only planned, verified, or filed.

Related: [verify-github-issue](../verify-github-issue/SKILL.md) (verify only); [plan-feature](../plan-feature/SKILL.md) (plan + file, no code). Conventions: [shared.md](../shared.md).

## Non-negotiables

[shared.md](../shared.md). Additional for this skill:

- If the issue is weak, **extend SPEC** (and ACs) so behavior is authoritative before coding. Do not implement from an ambiguous issue alone.
- Game-app panels/dialogs/overlays: standing 1 s full-load + dispose (`colonizethis-ui-surface-budget.mdc`) even when the issue omits it.
- UI: match `SPEC/ui/pixel-art-ui-catalog.md` (editorial-monocle) and any `SPEC/ui/mockups/` for that screen. Player UX/gameplay: [update-game-manual](../update-game-manual/SKILL.md). New/changed surfaces: [document-app-ui](../document-app-ui/SKILL.md).

## Issue quality gate (before coding)

| Check | If missing or weak |
|--------|-------------------|
| **Problem** is clear | Summarize the gap; extend SPEC. Optionally comment on the issue pointing at the new sections. |
| **Design / approach** outlined (or a deliberate minimal path) | Document the approach in SPEC/TDD or an issue comment first. If the issue contradicts GDD/TDD, update SPEC first. |
| **ACs** are test-targetable | Add/tighten ACs in SPEC (`colonizethis-acceptance-criteria.mdc`); mirror in an issue comment if the issue text is stale. Plan positive and negative tests. |
| **Palette** (UI issues only) | Canonical OKLCH table in `SPEC/ui/pixel-art-ui-catalog.md` § Editorial-monocle palette, plus a per-screen mockup if one exists. If the catalog palette is missing/stale, stop. |

If still not actionable after SPEC updates, **stop** and tell the user what decision or AC is missing.

## Scope triage (large issues)

Rule of thumb: **~20+ files** or extensive SPEC rewrites → do not attempt the whole issue in one pass unless the user insists. Still **one PR per issue**.

1. Prefer subtasks/phases already in the issue.
2. Else one isolatable vertical slice per pass (testable, maps to a subset of ACs) as commits on the open PR. After an early merge, one successor PR from current `dev`.
3. PR description: **Done in this push** / **Remaining for #N** / `Refs #N`. Do not claim the full issue is done until all ACs are met.

## Workflow

1. `gh issue view <n> --json title,body,state,labels,url`. Confirm open (or confirm with the user if closed).
2. Quality gate; update SPEC/ACs first.
3. Map each targeted AC → positive + negative tests.
4. One branch from up-to-date `dev` (e.g. `fix/issue-123-slug`). Reuse until that PR merges.
5. Implement: minimal, SPEC-authorized, no drive-by refactors. UI and manual follow-ups as above.
6. Tests until green (`melos` / `flutter test` per testing rule).
7. Pre-PR: CONTRIBUTING checklist. UI renders on `AppThemes.editorialMonocle` with Ct-* widgets only. Manual updated or non-update justified.
8. Open or update **one** PR to `dev` with a conventional-prefix title and `Refs #N`.

`gh` examples: [reference.md](reference.md).

## Output

```markdown
Issue: #<n> <url>
Issue readiness: <pass | gaps addressed via SPEC/comment>
Scope: <full slice | partial; what was deferred>
SPEC: <files/sections>
Manual: <chapters | N/A — justification>
Implementation: <high-level>
Tests: <added/updated; commands>
PR: <url>
```
