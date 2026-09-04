---
name: refactoring-opportunity-github-issue
description: Analyzes `app/` or one `packages/*` workspace package on the latest `origin/dev` baseline for refactoring opportunities using ColonizeThis `.cursor/rules` (plus sound Dart/Flutter practice), de-duplicates against open GitHub issues, proposes focused CI enforcement (AST-first; extend existing gates before adding new ones), and produces a structured GitHub issue another developer can implement. Use when the user asks for refactor scouting, package-level tech-debt triage, or a filing-ready issue from evidence-based findings scoped to app or a package.
---

# Refactoring opportunity → GitHub issue (ColonizeThis)

Target: `app/` **or** one `packages/<name>/`. Not `tool/`, `widgetbook_host/`, `ctdev/`, `pytool/`, or multi-root sweeps. If the user names something else, ask them to pick (interactive). [refactor-analysis-agent](../refactor-analysis-agent/SKILL.md) picks autonomously.

Read-only until filing. Issue shape and `gh` create: [create-github-issue](../create-github-issue/SKILL.md). Conventions: [shared.md](../shared.md). CI pointers: [references/ci-and-rules.md](references/ci-and-rules.md).

## Workflow

**1. Lock scope** — `app` or `packages/<package>` (+ optional motivation).

**1b. Baseline** — analysis revision is `dev` fast-forwarded to `origin/dev`. Record `HEAD` SHA in investigation notes. If fast-forward fails, stop: reset only with user consent, or analyze detached `origin/dev` and record the SHA. Do not start step 3 until this succeeds or the user accepts a documented non-`dev` baseline.

**1c. De-duplicate** — `gh issue list` / `gh search issues` for the target path. Drop or narrow themes already open; cite `#n`. If `gh` fails, say so and give search strings.

**2. Governance** — matching `.cursor/rules/*.mdc` via [routing-index.md](../../rules/routing-index.md). Spot-check `SPEC/` read-only.

**3. Analyze** — cite `file:symbol`. Tie findings to a rule file or label **general practice**. Flag architecture-boundary leaks. Preserve stable screen IDs; note `document-app-ui` if structure changes. Note test-risk gaps.

**4. CI** — extend existing gates before new jobs (see ci-and-rules.md). One concern per check. Say “extend X” vs “add new”.

**5. File** — `create-github-issue` §§ create/fallback.

## Issue body

```markdown
## Summary
[target + outcome]

## Scope
- **Target:** `app` or `packages/<name>`
- **Non-goals:** ...

## Steps to reproduce
Not applicable (refactoring / maintainability improvement).

## Current behavior
[structure / coupling / risk — paths]

## Expected behavior / target state
...

## Investigation notes
- **Analysis baseline:** `dev` @ `<sha>`
- **Open issues / de-duplication:** ...
- **Rules / SPEC / Code / Tests:** ...

## Proposed work (not implemented)
- **Refactors:** ...
- **CI / enforcement:** extend vs new; files
- **SPEC follow-up:** none | clarification | new section
- **UI docs:** `document-app-ui` if player-app UI structure changes

## Risks / edge cases
- ...

## Suggested acceptance criteria
- [ ] ...
```
