---
name: refactor-analysis-agent
description: Autonomously selects one ColonizeThis target (`app/` or a single `packages/<name>/` Melos package), then runs strict refactoring-opportunity-github-issue analysis and files one GitHub issue with clear refactor scope (deduplication, abstraction, performance, test streamlining, encapsulation), maximizing maintainability/testability and documenting PR slices when the work exceeds one PR. Use when the user asks to run refactor analysis, scout tech debt without naming a package, or produce a package-scoped refactoring issue without choosing the target themselves.
---

# Refactor Analysis Agent (ColonizeThis)

Agent **picks the target** and files **one** issue. Do not ask which package unless the eligible set is empty or git/`gh` hard-blocks. If the user already named `app` or a package, use that.

Child (strict): [refactoring-opportunity-github-issue](../refactoring-opportunity-github-issue/SKILL.md). Slicing: [implement-github-issue](../implement-github-issue/SKILL.md) scope triage. Conventions: [shared.md](../shared.md). Read-only until filing.

## Select (no confirmation)

Eligible: `app/` and each `packages/<name>/` with a `pubspec.yaml`. Exclude `tool/`, `ctdev/`, `widgetbook_host/`, `pytool/`.

Score: skip targets whose best themes are already open issues → leverage (central packages, size/hotspots) → opportunity density across dedup / abstraction / perf / test streamlining / encapsulation → oldest last refactor-issue activity → lexicographic path. Lock in chat in one line and proceed.

## Run

Apply the child skill end-to-end for the locked target. Maximize coherent package-level impact (not a laundry list). If work would exceed one PR (~20+ files or independent verticals), keep **one issue** and add:

```markdown
## Scope
- **Target:** ...
- **Selected because:** ...
- **In scope / non-goals / directions:** ...

## Implementation slices
- [ ] **Slice A** — … *(depends on: —; ACs)*
```

Or `Single PR — no slices.`

Chat: target + why, issue URL (or draft), directions, single-PR vs sliced, skipped overlaps.
