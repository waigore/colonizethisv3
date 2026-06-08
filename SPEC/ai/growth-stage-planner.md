# Growth-stage planner

Refs #3371. Replaces reactive H8 production boosts with proactive, state-derived priority weights when `growthStagePlannerEnabled` is true.

## Purpose

The economy planner scores every feasible recipe each turn. Without growth-stage awareness, shortage-dominated static weights cause bootstrap Great Powers to allocate labour to military inputs before fabric and castIron infrastructure. The growth-stage planner computes a **priority vector** from game state each turn and modulates recipe scores, recruitment, build suppression, and (follow-up) civilian work routing.

## Priority vector

```dart
class GrowthStage {
  final double workerGrowthPriority;       // 0..1
  final double infrastructurePriority;   // 0..1
  final double resourceProductionPriority; // 0..1
  final double militaryPriority;           // 0..1
}
```

Pure function: `GrowthStage.compute(game, playerId, {snapshot})`. No hidden state, no RNG.

### Worker growth

`workerGrowthPriority = max(0, 1 - effectiveLabour / targetLabourForMaturity)`. Halved when `fabric >= kReserveTarget`.

### Infrastructure

`infrastructurePriority = max(0, 1 - prospectedImprovedFeedstockTileCount / targetFeedstockTileCount)`. Halved when `castIron >= kReserveTarget` **and** `lumber >= kReserveTarget`.

Feedstock tiles: owned tiles hosting `wool`, `cotton`, `timber`, `iron`, or `coal` with `improvementLevel >= 1`; mineral tiles must also be prospected.

### Resource production

```
maturityFactor = min(1, effectiveLabour / targetLabourForMaturity)
reserveShortfall(r) = max(0, 1 - stockpile[r] / kReserveTarget)  for r in {fabric, lumber, castIron}
reserveShortfall = max over r
resourceProductionPriority = maturityFactor × reserveShortfall
```

### Military

```
computed = clamp((effectiveLabour - minLabourForMilitary) / labourRangeForMilitary, 0, 1)
militaryPriority = isAtWar ? max(kAtWarMilitaryFloor, computed) : computed
```

`isAtWar`: active diplomacy war **or** invadable Old World frontier (`ThreatSummary.atWarWith` non-empty or `invadableProvinceIdsSorted` non-empty when snapshot supplied; else `Game.diplomacyRelations`).

## Recipe scoring (dampen-and-bias)

```
categoryPriority = mapped priority for output commodity, floored at kMinCategoryFloor
stageScaledScore = categoryPriority × (scoreRecipe(...) + kStagePriorityBias)
```

| Output | categoryPriority |
|--------|------------------|
| `fabric` | `max(workerGrowthPriority, resourceProductionPriority)` |
| `castIron`, `lumber` | `max(infrastructurePriority, resourceProductionPriority)` |
| `steel`, `bronze` | `militaryPriority` |
| `refinedSugar`, `cigars`, `furHats` | `militaryPriority` |
| other | `max(workerGrowth, infrastructure, resourceProduction, military)` |

When `growthStagePlannerEnabled == true`, `_allocateLabour` ranks by `stageScaledScore` and **disables** all H8 reactive boosts (`kRegimentBuildInputProductionScoreBoost`, supplier release, castIron-labour fabric pre-pass).

## Recruitment modulation

Peasant-recruit scaling: `max(kRecruitmentFloor, workerGrowthPriority)`. Exported as `peasantRecruitScoreScale(stage)` for tests.

## Build suppression

When `militaryPriority < kMilitaryBuildSuppressionThreshold`, `runRecruitmentPlanner` rejects all regiment and naval build candidates. At-war floor (0.3) keeps at-war GPs above the threshold.

## Coexistence flag

`growthStagePlannerEnabled` (default **false**). When false, legacy H8 behaviour in `economy-planner.md` is unchanged. When true, growth-stage scoring replaces H8 boosts; H8 code removal is AC9 after AC7 calibration.

## Tunable constants

| Constant | Default |
|----------|---------|
| `targetLabourForMaturity` | 12 |
| `targetFeedstockTileCount` | 6 |
| `minLabourForMilitary` | 6 |
| `labourRangeForMilitary` | 6 |
| `kReserveTarget` | 20 |
| `kAtWarMilitaryFloor` | 0.3 |
| `kStagePriorityBias` | 16.0 |
| `kMinCategoryFloor` | 0.1 |
| `kRecruitmentFloor` | 0.25 |
| `kMilitaryBuildSuppressionThreshold` | 0.2 |

## Integration

- `economy_planner.dart` — `_allocateLabour`, optional `growthStagePlannerEnabled` parameter.
- `recruitment_planner.dart` — build suppression, peasant scale helper.
- `recipe_scoring.dart` — `stageScaledRecipeScore`.
- `strategic_ai.dart` / `full_ai_planner.dart` — thread `growthStagePlannerEnabled` into economy and domain planners for end-to-end simulation (AC7).
- `domain_planner_orchestrator.dart` — growth-stage military build suppression in `_appendEconomyBuildOrders`; H8 castIron-labour peasant recruit skipped when the flag is on.
- Civilian work priority modulation: follow-up slice (not in initial flag-off default path).

## Acceptance criteria (issue #3371)

AC1–AC6, AC10–AC12: unit tests in `growth_stage_planner_test.dart`. AC7: `seed42_growth_stage_conquest_regression_test.dart` (skipped until calibration). AC9 H8 removal: follow-up after AC7 passes with flag default on.
