---
name: implement-github-issue
description: Implements work from a GitHub issue number or URL after validating the issue for clear problem statement, design or technical approach, and test-targetable acceptance criteria; updates SPEC and ACs when gaps exist; adds positive and negative tests mapped to ACs; runs tests; keeps at most one open PR per issue on dev (stack slices as commits on that PR; if an early merge lands before the issue is finished, open one follow-up PR for the remainder) with a conventional-prefix title; references the issue without closing it. Use when the user gives an issue ID or URL and wants implementation with tests and a non-closing PR.
---

# Implement a fix from a GitHub issue (ColonizeThis)

## When this applies

The user provides a GitHub **issue number** or **issue URL** (and repo context if ambiguous) and wants the agent to **implement** the described work—not only to plan, verify, or file an issue.

**Related skills:** Use [verify-github-issue](../verify-github-issue/SKILL.md) when the goal is verification only; use [plan-feature](../plan-feature/SKILL.md) when the goal is planning and issue creation without code changes.

## Non-negotiables

Follow **[AGENTS.md](../../../AGENTS.md)**, **[CONTRIBUTING.md](../../../CONTRIBUTING.md)**, and `.cursor/rules/` (SPEC-first, logging, coverage, architecture boundaries).

- **SPEC source of truth:** Game behavior → `SPEC/game/`; architecture → `SPEC/program/`; derive `SPEC/ui/`, `SPEC/ai/` as applicable. The repo uses **`SPEC/`** (not a generic `specs/` folder name).
- **PR target:** **`dev`** unless the user explicitly requires another base.
- **One open PR per issue (aim):** For a given issue number, there should be **at most one open pull request** at a time. Multi-slice or phased work is additional **commits** (and clear PR description sections) on that open PR’s branch—not a second simultaneous PR for the same issue. If the first PR is **merged before** all slices or ACs are satisfied, **open a new PR** from current **`dev`** for the remaining work (still only one open PR for that issue afterward). The user may also explicitly replace a broken PR with a single successor; do not run parallel PRs that split the same issue.
- **PR title (conventional prefix):** Use a **lowercase type prefix** consistent with [Conventional Commits](https://www.conventionalcommits.org/) scope style, then a concise description, then the issue reference. Examples: `fix: correct province lookup for dual-region saves (#123)`, `feat: add order-suggestion probe cap (#456)`, `refactor: extract turn-resolution timing helper (#789)`. Prefer **`fix`** for defects (not `bug:` as the type token); use **`feat`** for user-visible capability, **`refactor`** for behavior-preserving structure, **`docs`** / **`chore`** / **`test`** / **`perf`** / **`ci`** when those dominate the change. The title must remain free of GitHub **closing keywords** paired with `#N` (see next bullet).
- **Do not close the issue from the PR:** Avoid GitHub auto-close phrases that pair a closing keyword with the issue number (for example do **not** use `Fixes #123`, `Closes #123`, or `Resolves #123` in the PR title or body). Use **`Refs #123`** in the PR body (and optionally neutral phrasing such as **“Tracked by #123”**) so the issue stays open for manual closure after verification.
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

If the issue implies **very large** change (rule of thumb: **about 20+ files** touched or extensive SPEC rewrites), **do not** attempt the whole thing in one agent pass unless the user explicitly insists—but still keep **one PR per issue**.

1. Prefer boundaries already called out in the issue (**subtasks**, phases, or dependencies).
2. Otherwise choose **one isolatable slice per pass**: minimal vertical slice that delivers testable value and maps to a subset of ACs; **push the slice as commits on the open PR branch** for that issue (or open the **one** PR on first push). Later passes add commits to the **same open** PR until it merges or the issue is fully satisfied. If a prior PR for this issue **already merged** with work still outstanding, branch from up-to-date **`dev`** and open **one** new PR for the next slices (see non-negotiables).
3. In the **PR description**, use sections (for example **Done in this push** / **Remaining for #N**) so scope is honest: state what landed in the latest commits, what is **deferred** to a follow-up commit on the same PR, and **`Refs #N`**. Do not imply the full issue is done until all ACs are met.

## Workflow

1. **Load issue** — `gh issue view <n> --json title,body,state,labels,url` (or web UI). Confirm **open** (or confirm with user if closed).
2. **Run the issue quality gate** — Record gaps; update **SPEC** (and ACs) first; align issue discussion if helpful.
3. **Map ACs → tests** — For each AC: planned **positive** test(s) and **negative** / regression test(s) where meaningful.
4. **Branch** — For the **current** open PR, use **one** branch from up-to-date **`dev`** (naming per team habit; e.g. `fix/issue-123-short-slug` or `feat/issue-456-slug`). Reuse that branch for every subsequent slice **until that PR merges**. After an early merge with remaining scope, create a **new** branch from **`dev`** for the follow-up PR (same or adjusted slug per team habit); avoid having two open PRs for the same issue.
5. **Implement** — Minimal, SPEC-authorized changes; reuse existing patterns; no drive-by refactors.
6. **Tests** — Add or update tests so each targeted AC is covered; run impacted packages and relevant **`melos`** / **`flutter test`** commands until green.
7. **Pre-PR checklist** — CONTRIBUTING items (logging annexes if logging changed, formatting, coverage).
8. **Push and open/update PR** — Base **`dev`**. If **no open PR** exists for this issue (first slice, or prior PR already merged), open **one** PR with a **conventional-prefix title** (see non-negotiables) and body including **`Refs #N`** (no closing keywords before `#N`). If an **open** PR already exists, **push new commits to its branch** and refresh the description as scope advances. Summarize SPEC updates, tests run, and any **deferred** items still planned on that open PR.

## Output to the user

Use a short, factual structure:

```markdown
Issue: #<n> <url>

Issue readiness: <pass | gaps addressed via SPEC/comment>

Scope: <full slice | partial; what was deferred>

SPEC: <files/sections touched>

Implementation: <high-level>

Tests: <what was added/updated; commands run>

PR: <url> (one open PR for issue unless prior merged early—then successor PR; conventional title; targets `dev`, Refs #n, does not auto-close)
```

## Additional resources

- [reference.md](reference.md) — `gh` and test command hints
