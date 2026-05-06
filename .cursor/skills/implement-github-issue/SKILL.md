---
name: implement-github-issue
description: Implements a fix from a GitHub issue number or URL after validating the issue for clear problem statement, design or technical approach, and test-targetable acceptance criteria; updates SPEC and ACs when gaps exist; adds positive and negative tests mapped to ACs; runs tests; opens a PR targeting dev that references the issue without closing it. For very large issues (about 20+ files or broad spec churn), implements one isolatable slice only. Use when the user gives an issue ID or URL and wants end-to-end implementation with tests and a non-closing PR.
---

# Implement a fix from a GitHub issue (ColonizeThis)

## When this applies

The user provides a GitHub **issue number** or **issue URL** (and repo context if ambiguous) and wants the agent to **implement** the described work—not only to plan, verify, or file an issue.

**Related skills:** Use [verify-github-issue](../verify-github-issue/SKILL.md) when the goal is verification only; use [plan-feature](../plan-feature/SKILL.md) when the goal is planning and issue creation without code changes.

## Non-negotiables

Follow **[AGENTS.md](../../../AGENTS.md)**, **[CONTRIBUTING.md](../../../CONTRIBUTING.md)**, and `.cursor/rules/` (SPEC-first, logging, coverage, architecture boundaries).

- **SPEC source of truth:** Game behavior → `SPEC/game/`; architecture → `SPEC/program/`; derive `SPEC/ui/`, `SPEC/ai/` as applicable. The repo uses **`SPEC/`** (not a generic `specs/` folder name).
- **PR target:** **`dev`** unless the user explicitly requires another base.
- **Do not close the issue from the PR:** Avoid GitHub auto-close phrases that pair a closing keyword with the issue number (for example do **not** use `Fixes #123`, `Closes #123`, or `Resolves #123` in the PR title or body). Use **`Refs #123`** (or equivalent neutral references such as **“Part of #123”** / **“Implements slice for #123”**) so the issue stays open for manual closure or follow-up PRs.
- **Tests and coverage:** Meet gates in `colonizethis-testing.mdc` and CONTRIBUTING (**90%** logic/ai/map; **80%** elsewhere). Prefer **`flutter test`** / **`melos`** patterns from AGENTS; do not use `dart test` for app widget tests where the testing rule forbids it.

## Issue quality gate (before coding)

Confirm the issue body (and high-signal comments) gives enough to implement safely:

| Check | If missing or weak |
|--------|-------------------|
| **Problem** is clear (symptom, scope, user-visible or system outcome) | Summarize the gap, then **extend the relevant SPEC** (and UI/AI specs if needed) so behavior is authoritative. Optionally add a short **issue comment** pointing to the new SPEC sections—do not rely on an ambiguous issue alone. |
| **Design / technical approach** is outlined (or a deliberate “minimal change” path) | Document the chosen approach in SPEC/TDD or the issue comment before large code changes; if the issue contradicts GDD/TDD, **resolve via SPEC updates first**. |
| **Acceptance criteria** are **test-targetable** (observable outcomes, not vague “works well”) | Add or tighten ACs in SPEC (`colonizethis-acceptance-criteria.mdc`) and mirror them in the issue via comment if the issue text is stale. Each AC should support **positive** and, where relevant, **negative** test cases. |

If the issue is still not actionable after SPEC updates, **stop** and tell the user what decision or AC text is missing rather than guessing.

## Scope triage (large or multi-part issues)

If the issue implies **very large** change (rule of thumb: **about 20+ files** touched or extensive SPEC rewrites), **do not** attempt the whole thing in one pass unless the user explicitly insists.

1. Prefer boundaries already called out in the issue (**subtasks**, phases, or dependencies).
2. Otherwise choose **one isolatable slice**: minimal vertical slice that delivers testable value and maps to a subset of ACs.
3. In the **PR description**, state **exactly** what is in scope, what is **deferred**, and **Refs #N** to the parent issue. Do not imply the full issue is done.

## Workflow

1. **Load issue** — `gh issue view <n> --json title,body,state,labels,url` (or web UI). Confirm **open** (or confirm with user if closed).
2. **Run the issue quality gate** — Record gaps; update **SPEC** (and ACs) first; align issue discussion if helpful.
3. **Map ACs → tests** — For each AC: planned **positive** test(s) and **negative** / regression test(s) where meaningful.
4. **Branch** — Create a feature branch from up-to-date **`dev`** (naming per team habit; e.g. `fix/issue-123-short-slug`).
5. **Implement** — Minimal, SPEC-authorized changes; reuse existing patterns; no drive-by refactors.
6. **Tests** — Add or update tests so each targeted AC is covered; run impacted packages and relevant **`melos`** / **`flutter test`** commands until green.
7. **Pre-PR checklist** — CONTRIBUTING items (logging annexes if logging changed, formatting, coverage).
8. **Push and open PR** — Base **`dev`**; body includes **Refs #N** (no closing keywords before `#N`); summarize scope, SPEC updates, tests run, and any **intentional out-of-scope** items for large issues.

## Output to the user

Use a short, factual structure:

```markdown
Issue: #<n> <url>

Issue readiness: <pass | gaps addressed via SPEC/comment>

Scope: <full slice | partial; what was deferred>

SPEC: <files/sections touched>

Implementation: <high-level>

Tests: <what was added/updated; commands run>

PR: <url> (targets `dev`, Refs #n, does not auto-close)
```

## Additional resources

- [reference.md](reference.md) — `gh` and test command hints
