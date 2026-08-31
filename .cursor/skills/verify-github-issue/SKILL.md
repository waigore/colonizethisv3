---
name: verify-github-issue
description: Verifies one open GitHub issue against acceptance criteria, specs, tests, and CONTRIBUTING; posts a verification comment via gh. UI issues require passing widget goldens on latest dev with PNG proof uploaded to the issue (hard-fail if goldens cannot be captured or fix is not merged). Game-app UI also has a standing 1 s full-load surface budget + dispose check even when issue ACs omit it. Never relabels issues.
---

# Verify a GitHub issue (ColonizeThis)

## When this applies

Issue **number** or **URL**. If only a GitHub username is given, ask for issue number/URL.

## Policy

Follow **[AGENTS.md](../../../AGENTS.md)** and **[CONTRIBUTING.md](../../../CONTRIBUTING.md)**. SPEC-first. PRs target **`dev`**.

**Hard-fail** (never **Complete**):

- ACs hand-waved or untested (coverage: 90% logic/ai/map, 80% elsewhere).
- Fix not on **`origin/dev`** (local-only or unmerged PR).
- **UI issue** without passing widget golden + PNG proof on the issue comment.
- Any golden test failure, missing golden mapping for a visual AC, or gist upload/embed failure.
- **Game-app UI surface budget** (standing; **not** AC-gated): merged work that **introduces or modifies** a game-app panel, dialog, or overlay (under `app/lib/features|widgets|ui` / Flame host, or that references `SPEC/ui/` / screen IDs) must meet the hard 1 s full-load open budget and unmount unused dialogs/widgets/`FlameGame`s (`colonizethis-ui-surface-budget.mdc`, `SPEC/program/ui-surface-budget.md`) **even if the issue ACs omit it**. Exempt: ctdev-only; untouched surfaces that pre-date the issue (grandfathered overflows). Missing timing/unmount evidence for a **touched** surface → **Gaps remain**.
- Issue that updates the player manual whose merged chapter(s) fail the **style + accuracy** audit below.

**Never** change labels, milestones, or issue state — **`gh issue comment` only**.

## Workflow

1. `gh issue view <n> --json title,body,labels,state,url` — issue must be open.
2. Extract ACs from body/comments; flag vague ACs before claiming complete.
3. **`git fetch origin && git checkout dev && git pull`** — verify only on **latest `dev`**. Unmerged or local-only work → **Gaps remain**.
4. Map ACs → code, SPEC, tests, merged PR(s) referencing the issue.
5. **Manual (player-facing issues):** When the issue changes player UX or gameplay, verify `docs/manual/` chapter updates on merged `dev` (or justified non-update in the PR). Policy: `.cursor/rules/colonizethis-game-manual.mdc`.
6. **Manual audit (when the issue updates the handbook):** If merged work (or the issue ACs) change `docs/manual/[0-9][0-9]-*.md`, audit **each updated chapter** with the same two checks as [`.cursor/skills/review-game-manual-agent/SKILL.md`](../review-game-manual-agent/SKILL.md) § Style review and § Accuracy review. Authority is that skill’s table: **style** = `docs/manual/STYLE_GUIDE.md`; **accuracy** = the chapter’s `## Sources` plus `SPEC/ui/screen-registry.md`. Do not invent extra rules. Skip this step only for a justified non-update (no chapter to audit). Remaining style or accuracy findings → **Gaps remain**.
7. Run relevant tests (`melos`, `cd app && flutter test …`).
8. **UI issues** (see below): widget golden procedure + gist upload.
9. **Game-app UI surface budget** (see below): standing check even when ACs omit it.
10. `gh issue comment <n> --body-file …` using the template below.

### UI issues

**UI** = references `SPEC/ui/` or screen registry / IDs, user-visible ACs (CONTRIBUTING § UI changes), or merged player-app UI code under `app/lib/features|widgets|ui` / `app/lib/features/game/flame/`.

**Exempt:** ctdev-only surfaces (`SPEC/program/ctdev-app.md`).

**Proof:** widget `matchesGoldenFile` only — not integration screenshots, e2e text snapshots, or Widgetbook.

1. `rg 'matchesGoldenFile' app/test --glob '*_test.dart' -l`
2. Map **each visual AC to the letter of the issue** to a passing golden (one golden may cover several ACs). No mappable golden → **Gaps remain**; remedy: add host test in `app/test/` + PNG in `app/test/goldens/` (package UI → host in `app/test/`).
3. `cd app && flutter test test/<file>.dart` — no `--update-goldens`. Fail or missing PNG → **Gaps remain**.
4. Copy passing PNGs to `tmp/verify-issue-<n>/`, upload via **`gh gist create --public`**, embed raw URLs (`https://gist.githubusercontent.com/OWNER/GIST_ID/raw/<file>.png`) in the comment. Upload/embed failure → **Gaps remain**. Delete `tmp/verify-issue-<n>/` after posting.

Follow existing golden patterns: `AppThemes.editorialMonocle`, `suppressLogsForTests()`, deterministic fixtures (`province_build_improvement_shortcut_host_goldens_test.dart`, `region_map_*_test.dart`).

### Game-app UI surface budget (standing)

Apply only when the issue **introduces or modifies** a game-app panel, dialog, or overlay (same UI definition as goldens). **Exempt:** ctdev-only (`SPEC/program/ctdev-app.md`); untouched grandfathered overflows per `SPEC/program/ui-surface-budget.md` § Existing overflows.

The 1 s clock includes **every required load** on that **touched** surface (projections, minimaps, Yarn/Jenny, required assets), not first chrome. Closed surfaces must be **unmounted**. Policy: `.cursor/rules/colonizethis-ui-surface-budget.mdc`; measurement: `SPEC/program/ui-surface-budget.md`.

Evidence (at least one for each touched surface): open-path timing test using `kUiSurfaceOpenBudgetMs`; unmount test (panel/dialog keys / `GameWidget` / Jenny hosts **absent** after dismiss); or a recorded open on `dev` with wall-clock ≤ 1000 ms including required content. No evidence for a touched surface → **Gaps remain**. Non-UI issues or issues that do not touch game-app surfaces → row **`N/A: not game-app UI`**.

## Comment template

```markdown
**Verification** (ACs / SPEC / tests / manual)

- [AC bullets → code/tests; partial/missing marked]
- Game-app UI surface budget (standing, not AC-gated): [pass + evidence | N/A: not game-app UI | gap]
- Manual (if player-facing): [chapters updated on `dev` | justified non-update | gap]
- Manual audit (if handbook updated): [chapter files] style: <n> findings; accuracy: <n> findings [pass | remaining misses listed]

Implementation: [merged PR on `dev`]. Tests: [commands run].

**Visual proof** (UI only)

| AC | Golden test | PNG |
|----|-------------|-----|
| … | `app/test/<file>.dart` | ![…](https://gist.githubusercontent.com/OWNER/GIST_ID/raw/file.png) |

`dev` @ `<sha>` — golden run **pass**.

Outcome: [Complete | Gaps remain — see above].
```

**Complete** only when ACs are met on **merged `dev`**, tests pass, UI proof is embedded when required, the standing game-app UI surface-budget row is **pass** or **N/A**, and any handbook update passes the style + accuracy audit. Unmerged PR → **Gaps remain**.

## Tools

`gh` (issue view/comment, gist create), `rg`, `cd app && flutter test`, `curl -sfI` (gist URLs). Commands: [reference.md](reference.md).
