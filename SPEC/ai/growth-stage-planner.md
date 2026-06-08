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

## Civilian work feedstock routing

When `growthStagePlannerEnabled == true`, the orchestrator passes a per-GP
**feedstock resource-id preference** into `selectFullAiCivilianWorkOrders` so an
idle Builder improves the right feedstock tile first. `growthStageFeedstockPreference(game, playerId, stage)` returns two sets:

| Set | Resources | Active when |
|-----|-----------|-------------|
| fabric feedstock | `wool`, `cotton` | `workerGrowthPriority > 0.3` **and** `fabric < kReserveTarget` |
| infrastructure feedstock | `timber`, `iron`, `coal` | `infrastructurePriority > 0.3` |

Inside `_buildImprovementWorkScore`, an unimproved tile hosting a fabric
feedstock resource gains `kGrowthStageFabricFeedstockScoreBoost` (700); an
infrastructure feedstock tile gains `kGrowthStageInfraFeedstockScoreBoost` (520).
Fabric outranks infrastructure so a bootstrap GP secures the `wool → fabric →
peasant upkeep` chain before castIron/lumber. Both boosts exceed the New World
resource bonuses; the fabric boost also exceeds the H8 extraction boost (600).
Empty sets (flag off, fabric saturated, or no growth need) leave legacy routing
unchanged, so the flag-off default is byte-for-byte identical.

### AC1/AC2 behaviour

- Given a Builder whose candidate set holds an unimproved `wool` tile and an
  unimproved `grain` tile, when selection runs with the fabric feedstock set,
  then the emitted work order targets the `wool` tile (AC1).
- Given both a `wool` and a `timber` unimproved candidate with both feedstock
  sets supplied, when selection runs, then the emitted order targets `wool`
  (fabric outranks infrastructure).
- Given the fabric feedstock set is empty (flag off or `fabric >= kReserveTarget`),
  when selection runs, then routing falls back to the legacy lexicographic /
  extractable-resource scoring (negative case).

### Builder relocation (fabric feedstock)

`build_improvement` candidates are scoped to the **Builder's current province**.
When the fabric feedstock preference is active but no idle Builder sits in a
province with an unimproved `wool`/`cotton` tile, the orchestrator emits one
**growth-stage Builder relocation** [MoveOrder] before civilian work selection:

1. `ownedFabricFeedstockProvinceIdsSorted` lists owned provinces hosting
   unimproved fabric feedstock (ascending province id).
2. `suggestGrowthStageBuilderFeedstockRelocation` picks the lowest-id idle
   Builder not already in such a province (no pending draft move/work) and
   moves it to the lowest-id target province via a validated
   `suggestMoveOrders` candidate, preferring a destination tile that hosts
   `wool`/`cotton` (lexicographic tile key).
3. The relocation is appended to draft orders **before** work selection; work
   candidates for that `unitId` are stripped so move/work XOR holds.

On seed 42, gp3/gp5 start with Builders in a grain-only province while `wool`
tiles sit in other owned provinces; this slice routes a Builder onto the wool
province so the feedstock build routing above can fire on the following turn
(or same turn after the move resolves).

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
| `kGrowthStageFabricFeedstockScoreBoost` | 700 |
| `kGrowthStageInfraFeedstockScoreBoost` | 520 |

## Integration

- `economy_planner.dart` — `_allocateLabour`, optional `growthStagePlannerEnabled` parameter.
- `recruitment_planner.dart` — build suppression, peasant scale helper.
- `recipe_scoring.dart` — `stageScaledRecipeScore`.
- `strategic_ai.dart` / `full_ai_planner.dart` — thread `growthStagePlannerEnabled` into economy and domain planners for end-to-end simulation (AC7).
- `domain_planner_orchestrator.dart` — growth-stage military build suppression in `_appendEconomyBuildOrders`; H8 castIron-labour peasant recruit skipped when the flag is on.
- `growth_stage_work_priorities.dart` — `growthStageFeedstockPreference` computes the fabric / infrastructure feedstock resource-id sets; `prioritizeWorkOrdersForGrowthStage` reorders civilian candidates (superseded by the scoring boost below, retained for ordering stability).
- `growth_stage_builder_relocation.dart` — `ownedFabricFeedstockProvinceIdsSorted`, `suggestGrowthStageBuilderFeedstockRelocation` (orchestrator pre-work slice).
- `full_ai_civilian_work_selection.dart` / `_build_purchase.dart` — `selectFullAiCivilianWorkOrders` accepts the two feedstock sets and applies `kGrowthStageFabricFeedstockScoreBoost` / `kGrowthStageInfraFeedstockScoreBoost` in `_buildImprovementWorkScore` so a co-located Builder selects the fabric (then infrastructure) feedstock tile.

## Acceptance criteria (issue #3371)

AC1–AC6, AC10–AC12: unit tests in `growth_stage_planner_test.dart`. AC7: `seed42_growth_stage_conquest_regression_test.dart` (skipped until calibration). AC9 H8 removal: follow-up after AC7 passes with flag default on.
