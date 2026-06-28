# E2E wall-clock evidence for GitHub #2336 (AC8–AC9)

This document records the **baseline vs post-refactor** wall-clock comparison required by issue #2336 AC8 and AC9. CI does not execute `integration_test/`; measurements were captured on **Linux desktop** under **xvfb** with `--dart-define=CT_E2E=true` per [SPEC/program/e2e-integration-tests.md](../SPEC/program/e2e-integration-tests.md).

## Methodology

1. **Baseline (pre-refactor):** `tool/run_e2e_timing.sh 3` with `CT_REPO_ROOT` pointing at a git worktree checked out at commit `b1488584` (parent of the first shared-helpers slice #2486). Captured in PR #2515.
2. **Post-refactor (current):** Three consecutive green runs per scenario on current `dev` after fleet-reach fixes (#3265, #3275, #3324, #3329). Latest medians from PR #3329 verification (Linux desktop, 1280×1024 xvfb).
3. **Comparison:** `tool/compare_e2e_timing.sh` on the summary markdown files (see `test/fixtures/e2e_timing/`).

## AC8 table (median wall-clock per test)

| Test | Baseline median (s) | After median (s) | Delta % |
|------|---------------------|------------------|---------|
| `new_game_capital_panel_e2e_test` | 94.13 | 10.00 | +89.4% |
| `new_game_full_turn_e2e_test` | 208.11 | 32.50 | +84.4% |
| `new_game_fleet_reaches_new_world_e2e_test` | 252.41 | 34.70 | +86.3% |

**Aggregate (sum of medians):** 554.65s → 77.20s (**+86.1%** reduction).

Baseline source: PR #2515 (`b1488584` worktree, 3 runs/test). After source: PR #3329 (3/3 pass per scenario; medians are midpoints of reported run ranges: capital 9.5–10.4s, full_turn 31.2–33.8s, fleet 34.6–34.8s).

## AC9

**PASS** — aggregate median reduction **86.1%** exceeds the **≥25%** threshold.

## AC6 / AC7 / AC10

PR #3329 recorded **3 consecutive passes** for all three scenarios on Linux desktop (AC6, AC7, AC10). Intermediate capture PR #3255 showed `full_turn` and `capital_panel` green 3/3 while `fleet_reach` was still failing; subsequent slices (#3265, #3275, #3324) fixed fleet move detection and topology BFS routing.

## Reproducing

```bash
# Baseline (needs full git history + worktree at b1488584)
git worktree add /tmp/ct-e2e-baseline b1488584
CT_REPO_ROOT=/tmp/ct-e2e-baseline FLUTTER_BIN=~/development/flutter/bin/flutter tool/run_e2e_timing.sh 3

# After (current dev)
FLUTTER_BIN=~/development/flutter/bin/flutter tool/run_e2e_timing.sh 3

tool/compare_e2e_timing.sh test/fixtures/e2e_timing/baseline_summary.md test/fixtures/e2e_timing/after_summary.md
```
