---
name: verify-github-issue
description: Verifies one open GitHub issue against acceptance criteria, specs, tests, and CONTRIBUTING; posts a verification comment via gh. UI issues require passing widget goldens on latest dev with PNG proof uploaded to the issue (hard-fail if goldens cannot be captured or fix is not merged). Never relabels issues.
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

**Never** change labels, milestones, or issue state — **`gh issue comment` only**.

## Workflow

1. `gh issue view <n> --json title,body,labels,state,url` — issue must be open.
2. Extract ACs from body/comments; flag vague ACs before claiming complete.
3. **`git fetch origin && git checkout dev && git pull`** — verify only on **latest `dev`**. Unmerged or local-only work → **Gaps remain**.
4. Map ACs → code, SPEC, tests, merged PR(s) referencing the issue.
5. Run relevant tests (`melos`, `cd app && flutter test …`).
6. **UI issues** (see below): widget golden procedure + gist upload.
7. `gh issue comment <n> --body-file …` using the template below.

### UI issues

**UI** = references `SPEC/ui/` or screen registry / IDs, user-visible ACs (CONTRIBUTING § UI changes), or merged player-app UI code under `app/lib/features|widgets|ui` / `app/lib/features/game/flame/`.

**Exempt:** ctdev-only surfaces (`SPEC/program/ctdev-app.md`).

**Proof:** widget `matchesGoldenFile` only — not integration screenshots, e2e text snapshots, or Widgetbook.

1. `rg 'matchesGoldenFile' app/test --glob '*_test.dart' -l`
2. Map **each visual AC to the letter of the issue** to a passing golden (one golden may cover several ACs). No mappable golden → **Gaps remain**; remedy: add host test in `app/test/` + PNG in `app/test/goldens/` (package UI → host in `app/test/`).
3. `cd app && flutter test test/<file>.dart` — no `--update-goldens`. Fail or missing PNG → **Gaps remain**.
4. Copy passing PNGs to `tmp/verify-issue-<n>/`, upload via **`gh gist create --public`**, embed raw URLs (`https://gist.githubusercontent.com/OWNER/GIST_ID/raw/<file>.png`) in the comment. Upload/embed failure → **Gaps remain**. Delete `tmp/verify-issue-<n>/` after posting.

Follow existing golden patterns: `AppThemes.editorialMonocle`, `suppressLogsForTests()`, deterministic fixtures (`province_build_improvement_shortcut_host_goldens_test.dart`, `region_map_*_test.dart`).

## Comment template

```markdown
**Verification** (ACs / SPEC / tests)

- [AC bullets → code/tests; partial/missing marked]

Implementation: [merged PR on `dev`]. Tests: [commands run].

**Visual proof** (UI only)

| AC | Golden test | PNG |
|----|-------------|-----|
| … | `app/test/<file>.dart` | ![…](https://gist.githubusercontent.com/OWNER/GIST_ID/raw/file.png) |

`dev` @ `<sha>` — golden run **pass**.

Outcome: [Complete | Gaps remain — see above].
```

**Complete** only when ACs are met on **merged `dev`**, tests pass, and UI proof is embedded. Unmerged PR → **Gaps remain**.

## Tools

`gh` (issue view/comment, gist create), `rg`, `cd app && flutter test`, `curl -sfI` (gist URLs). Commands: [reference.md](reference.md).
