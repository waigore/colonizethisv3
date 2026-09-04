---
name: review-pr
description: Reviews an open pull request against issue alignment, acceptance-criteria test coverage, architecture conventions, and linting compliance with strict YES/NO outcomes. Use when the user asks to review, audit, or gate a PR for merge readiness.
---

# Review PR (ColonizeThis)

User asks to review an open PR (number or URL). Conventions: [shared.md](../shared.md).

## Scoring

Every criterion is exactly `YES`, `CONDITIONAL YES`, or `NO`.

- `YES` = full compliance. Any gap → `NO`, except:
- `CONDITIONAL YES` only when the PR is partial **and** the PR comment documents remaining gaps and follow-up. Eligible: Alignment, AC coverage, and UI visual fidelity **for deferred per-screen polish only**.
- Architecture and Linting: never `CONDITIONAL YES`. Lint allowlist additions/expansions are linting `NO`.
- Material-chrome violations and hardcoded light-theme colors are always UI `NO` (not conditional). Catalog: `SPEC/ui/pixel-art-ui-catalog.md`.

## Checklist (in order)

1. **Alignment with issue** — implementation satisfies the issue.
2. **AC coverage** — tests cover the issue ACs.
3. **Architecture** — `.cursor/rules/` plus standing game-app 1 s full-load + dispose (`colonizethis-ui-surface-budget.mdc`).
4. **Linting compliance** — no allowlist changes.
5. **UI visual fidelity** (only if the PR touches app UI) — Widgetbook under `AppThemes.editorialMonocle`; Ct-* catalog only; palette from the catalog. Per-screen polish belongs in sibling alignment issues. Non-UI PR → `N/A`.
6. **Player manual** (only if player UX/gameplay changed) — `docs/manual/` updated or non-update justified (`colonizethis-game-manual.mdc`). Else `N/A`.

## Workflow

Load PR + linked issue. Inspect code, tests, CI. Start each criterion at `YES`; downgrade on evidence. Undocumented partial work is `NO`. Uncertain → `NO` and say what evidence is missing. **Post the full review as a PR comment** (`gh pr comment`).

```markdown
PR: <number/url>
Issue: <number/url or "not linked">

Checklist:
- Alignment with issue: YES | CONDITIONAL YES | NO
  - Evidence: ...
- AC coverage: YES | CONDITIONAL YES | NO
  - Evidence: ...
- Architecture: YES | NO
  - Evidence: ...
- Linting compliance: YES | NO
  - Evidence: ...
- UI visual fidelity: YES | CONDITIONAL YES | NO | N/A
  - Evidence: ...
- Player manual: YES | CONDITIONAL YES | NO | N/A
  - Evidence: ...

Violations / Gaps:
- ...

Conclusion:
- Merge readiness: READY | NOT READY
- Rationale: <1-3 lines>
```

READY only when every applicable criterion is `YES` (`N/A` counts as compliant).
