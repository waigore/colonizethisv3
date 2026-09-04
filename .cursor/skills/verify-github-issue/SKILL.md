---
name: verify-github-issue
description: Verifies one open GitHub issue against acceptance criteria, specs, tests, and CONTRIBUTING; posts a verification comment via gh. UI issues require passing widget goldens on latest dev with PNG proof uploaded to the issue (hard-fail if goldens cannot be captured or fix is not merged). Game-app UI also has a standing 1 s full-load surface budget + dispose check even when issue ACs omit it. Never relabels issues.
---

# Verify a GitHub issue (ColonizeThis)

Issue **number** or **URL**. If only a GitHub username is given, ask for the issue. Conventions: [shared.md](../shared.md). Commands: [reference.md](reference.md).

## Policy

Verify only on **latest `origin/dev`**. **Never** change labels, milestones, or issue state — `gh issue comment` only (label moves belong to `backlog-verify-agent`).

**Hard-fail** (never **Complete**):

- ACs hand-waved or untested (coverage gates in the testing rule).
- Fix not on `origin/dev`.
- **UI issue** without a passing widget golden mapped to each visual AC, plus PNG proof on the comment (gist upload/embed failure counts).
- **Game-app UI surface budget** for surfaces **introduced or modified** by the issue (`colonizethis-ui-surface-budget.mdc`). Exempt: ctdev-only; untouched grandfathered overflows. Missing evidence for a touched surface → **Gaps remain**.
- Handbook chapter updates that fail the style + accuracy audit in [review-game-manual-agent](../review-game-manual-agent/SKILL.md).

## Workflow

1. `gh issue view <n> --json title,body,labels,state,url` — must be open.
2. Extract ACs; flag vague ones before claiming complete.
3. `git fetch origin && git checkout dev && git pull`. Unmerged/local-only → **Gaps remain**.
4. Map ACs → code, SPEC, tests, merged PR(s).
5. Player-facing: `docs/manual/` updated on `dev` or justified non-update (`colonizethis-game-manual.mdc`).
6. If handbook chapters changed: style + accuracy audit per `review-game-manual-agent`. Remaining findings → **Gaps remain**.
7. Run relevant tests.
8. UI issues: golden procedure below.
9. Game-app UI: standing surface-budget evidence (timing test with `kUiSurfaceOpenBudgetMs`, unmount test, or recorded open ≤ 1000 ms including required content). Non-UI / untouched → `N/A: not game-app UI`.
10. `gh issue comment <n> --body-file …`.

### UI goldens

**UI** = `SPEC/ui/` / screen IDs / user-visible ACs, or merged player-app UI under `app/lib/features|widgets|ui` / Flame host. **Exempt:** ctdev. **Proof:** widget `matchesGoldenFile` only.

1. `rg 'matchesGoldenFile' app/test --glob '*_test.dart' -l`
2. Map each visual AC to a passing golden. None → **Gaps remain** (add host test in `app/test/` + PNG in `app/test/goldens/`).
3. `cd app && flutter test test/<file>.dart` — never `--update-goldens`.
4. Copy PNGs to `tmp/verify-issue-<n>/`, `gh gist create --public`, embed raw gist URLs in the comment. Then delete the tmp dir.

Follow existing golden hosts (`AppThemes.editorialMonocle`, `suppressLogsForTests()`, deterministic fixtures).

## Comment template

```markdown
**Verification** (ACs / SPEC / tests / manual)

- [AC bullets → code/tests; partial/missing marked]
- Game-app UI surface budget (standing, not AC-gated): [pass + evidence | N/A: not game-app UI | gap]
- Manual (if player-facing): [chapters on `dev` | justified non-update | gap]
- Manual audit (if handbook updated): [files] style: <n>; accuracy: <n> [pass | remaining misses]

Implementation: [merged PR on `dev`]. Tests: [commands].

**Visual proof** (UI only)

| AC | Golden test | PNG |
|----|-------------|-----|
| … | `app/test/<file>.dart` | ![…](https://gist.githubusercontent.com/OWNER/GIST_ID/raw/file.png) |

`dev` @ `<sha>` — golden run **pass**.

Outcome: [Complete | Gaps remain — see above].
```
