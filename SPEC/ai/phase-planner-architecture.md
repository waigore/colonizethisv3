## Phase planner architecture (Refs #2509)

**SPEC/ai** sub-spec for the single-goal phase-planner architecture in Full AI. Companion to [ai-architecture.md](ai-architecture.md) § Observer goal phases; derives from [world-model.md](../game/world-model.md), [victory.md](../game/victory.md), [diplomacy.md](../game/diplomacy.md), [ai-planner.md](../program/ai-planner.md), [ai-systems-impl.md](../program/ai-systems-impl.md).

## Overview

Each Great Power computes a deterministic `ObserverGoalPhase` from its `PlayerView` → `AIWorldSnapshot` once per turn. The phase dispatches to a self-contained **planner module** that makes one primary decision per domain — no cross-phase score aggregation or predicate fan-out.

Phase definitions, suppressions, and COLONIAL-lite stay normative in [ai-architecture.md](ai-architecture.md). This file specifies module contracts, orchestrator dispatch, data flow, and acceptance criteria.

## Rules

### Planner module contracts

Each function is **pure**: same `(Game, AIWorldSnapshot, optional phase-specific input)` → same output. Returned plans are value classes or sorted lists. Determinism is required (Must-have #7).

| Phase | Module (`packages/colonizethis_ai/lib/src/planning/`) | Functions |
|-------|------------------------------------------------------|-----------|
| EXPAND | `expand_phase_planner.dart` | `planExpandDeclareWar`, `planExpandPeace`, `planExpandEconomy`, `planExpandMilitary` |
| COLONIAL-lite | `colonial_phase_planner.dart` | `planColonialLiteOvertures`, `planColonialLiteNaval` |
| COLONIAL | `colonial_phase_planner.dart` | `planColonialAcquisition`, `planColonialPeace`, `planColonialMilitary`, `planColonialNaval`, `planColonialCivilian` |
| DEVELOP | `develop_phase_planner.dart` | `planDevelopPeace`, `planDevelopCivilian` |

**Structural suppression:** Each module imports only what it needs. EXPAND never imports `colonial_phase_planner.dart` or queries `ColonialSummary` and produces no NW orders. DEVELOP never produces `declareWar` or NW orders. COLONIAL-lite is the only sanctioned NW exception inside EXPAND. Suppression is architectural, not predicate-based.

### Orchestrator dispatch

`runDomainPlanners()` in `domain_planner_orchestrator.dart` (S5 target) computes the phase once per active player, then routes:

```
runDomainPlanners(ctx)
  phase = observerGoalPhaseFor(snapshot, game)
  if EXPAND:
    declareWar = planExpandDeclareWar(game, snapshot)
    peace      = planExpandPeace(game, snapshot)
    economy    = planExpandEconomy(game, snapshot)
    military   = planExpandMilitary(game, snapshot, declareWar)
    if COLONIAL-lite gate fires:
      ltOvertures = planColonialLiteOvertures(game, snapshot)
      ltNaval     = planColonialLiteNaval(game, snapshot)
  if COLONIAL:
    target     = planColonialAcquisition(game, snapshot)
    peace      = planColonialPeace(game, snapshot)
    military   = planColonialMilitary(game, snapshot, target?.declareWarFactionId)
    naval      = planColonialNaval(game, snapshot, target?.declareWarFactionId)
    civilian   = planColonialCivilian(game, snapshot)
  if DEVELOP:
    peace      = planDevelopPeace(game, snapshot)
    civilian   = planDevelopCivilian(game, snapshot)
  # Common tail (every phase):
  runResearchPlanner(ctx)
  runMovePlanner(ctx)
```

Phase-specific peace/declare-war targets feed `runDiplomacyPlannerWithResult`; work and army-move plans feed the economy / conquest passes. The S5 orchestrator wiring is in place: `domain_planner_orchestrator.dart` threads `PhasePlanOutcome` into every diplomacy / conquest / economy call site via the adapter helpers in `phase_planner_peace_targets.dart` / `phase_planner_declare_war_targets.dart` / `phase_planner_military_plans.dart`. `collectStalledGreatPowerPeaceTargets` (canonical home: `observer_goal_phase.dart`) remains the fallback path for callers that omit `phasePlan` (tests, legacy entry points) and keeps the EXPAND ratchet aggregator on the production hot path. Dispatcher: [phase-planner-dispatch.md](phase-planner-dispatch.md).

### Data flow

```
Game + PlayerView
  → AIWorldSnapshot.fromPlayerView(view)
      (ConquestSummary, ColonialSummary, ThreatSummary, EconomySummary)
  → observerGoalPhaseFor(snapshot, game)  → ObserverGoalPhase
  → Phase planner module(s)               → PhaseOrders / Plan / Target
  → suggestionAPI                         → Validated Orders
  → Merged turn orders                    (S5 orchestrator)
```

Planner modules never call each other. The orchestrator passes `planColonialAcquisition`'s `declareWar` faction id into `planColonialMilitary` / `planColonialNaval` as the priority target.

**Adjacency-distance iteration:** `planColonialAcquisition` iterates `ColonialSummary.invadableNewWorldProvinceIdsByDistance` (BFS distance ascending, lex tiebreak), falling back to the lex-sorted list when distance is empty. Bulk-NW planners stay on the lex-sorted list (subset filters, not first-match selectors).

**Personality bias (Must-have #4):** `planColonialAcquisition` accepts an optional `personalityId`. When the personality's `warLikelihood > allianceTendency` per `personalityThresholds` (today: `napoleon`, `isabella`, `frederick`, `gustavus`), the planner prefers `declareWar` over `joinEmpire` for the same tribe within the structural priority order; otherwise `joinEmpire` keeps top rank (`ai-personalities.md`). The per-province `purchase_land` arm is unchanged; outer gates (regiments, treasury, sea reachability) still apply.

### Phase transition guard

- Enter **EXPAND** when `oldWorldProvincesOwned < kObserverConquestMinOwProvincesPerGp` (10). A province loss immediately restores EXPAND; no hysteresis at quota+1.
- Enter **COLONIAL** when OW ≥ 10 and `hasColonialAcquisitionTargets` holds. The goal-scoring sibling `isEarlyColonialExpansion` (= `hasColonialAcquisitionTargets(colonial) && colonial.newWorldProvincesOwned < kColonialFewNwProvincesThreshold`) is consumed by `goal_manager.dart` for the early-colonial conquer-score bonus.
- Enter **DEVELOP** when OW ≥ 10 and no visible colonial targets.
- **COLONIAL-lite** is a parallel entry inside EXPAND (turn ≥ `kObserverColonialLiteMinTurn`, OW ≥ `kObserverColonialLiteNearQuotaOw` and below quota, global `newWorld|` not all GP-owned).

### Soft-phase priority weights (Refs #2847 — scaffolding)

`PhasePlanOutcome` carries an additive `priorityWeights` slot ([PhasePriorityWeights] value class in `phase_priority_weights.dart`) computed once per dispatch by `runPhasePlanners` from `(AIWorldSnapshot, Game, ExpandEconomyPlan)`. The slot exists so downstream slices can migrate scoring sites from hard structural suppression to soft weight multipliers without further dispatcher changes (Refs #2847).

The four normative domain weights model "how much should the planner bias toward this domain right now" as deterministic `double` values in `[0.0, 1.0]`:

| Domain | OW=0..6 | OW=7 | OW=8 | OW=9 | OW=10 | OW=11 | OW=12 | OW=13+ |
|--------|---------|------|------|------|-------|-------|-------|--------|
| `oldWorldConquest` | 0.95 | 0.95 | 0.90 | 0.80 | 0.60 | 0.40 | 0.20 | 0.10 |
| `newWorldAcquisition` | 0.05 | 0.05 | 0.10 | 0.20 | 0.40 | 0.60 | 0.80 | 0.90 |
| `oldWorldCivilian` | 0.90 | 0.90 | 0.85 | 0.75 | 0.55 | 0.35 | 0.15 | 0.05 |
| `newWorldCivilian` | 0.10 | 0.10 | 0.15 | 0.25 | 0.45 | 0.65 | 0.85 | 0.95 |

Curve values are **starting hypotheses** per issue #2847 § Tuning methodology — never zero in either domain so no module is structurally suppressed, OW-vs-NW pair crosses near OW=10 to mirror the current EXPAND→COLONIAL hard transition, and 0.05 NW priority at OW≤7 keeps the early-game OW sprint dominant (19:1 ratio at OW=0..7).

#### Resource-need overrides

Override predicates raise weight floors when the snapshot indicates a GP cannot reach OW conquest without an income/regiment bootstrap. Floors apply only when the predicate evaluates `true`; otherwise the curve value stands.

| Predicate (all must hold) | Floor raised to |
|---------------------------|-----------------|
| `economy.treasury == 0` **and** `colonial.newWorldProvincesOwned == 0` **and** `expandEconomyPlan.boostTreasuryRecoveryCargo == true` | `newWorldAcquisition` floor = `0.60` |
| `regimentCountForPlayer(game, snapshot.playerId) == 0` **and** `conquest.invadableProvinceIdsSorted.isNotEmpty` | `newWorldAcquisition` floor = `0.30` |

When both predicates fire on the same dispatch, the larger floor (`0.60`) wins. `oldWorldConquest` is **never weakened** by an override — overrides only lift NW weights, so a GP with viable OW targets keeps its full OW priority.

#### Determinism and SPEC-first contract

`computePhasePriorityWeights({snapshot, game, expandEconomyPlan})` is pure on its inputs (`Refs #2509` Must-have #7): identical inputs always yield field-equal `PhasePriorityWeights`. The function performs no I/O and no logging.

#### Phase 3 consumer wiring — conquest NW invasion (Refs #2847)

`runConquestArmyMovePlanner` and [resolvePhaseConquestInvadable] consume `resolvePhaseConquestNwInvasionWeight` as the production NW invasion multiplier:

- Legacy invadable unions include `snapshot.colonial.invadableNewWorldProvinceIdsSorted` when the weight is `> 0.0` (continuous curve — early sprint keeps a `0.05` floor so NW provinces remain reachable at low priority).
- NW army-move destination scoring multiplies the NW invadable bonus by the weight; weights `<= 0.0` zero the destination (legacy hard-suppress equivalent).

#### Phase 3 consumer wiring — diplomacy declare-war NW scoring (Refs #2847)

`_scoreDeclareWarDiplomaticOrder` (`diplomatic_candidate_scoring_declare_war.dart`) consumes `resolvePhaseDiplomacyDeclareWarColonialPressureWeight` as the production NW colonial declare-war multiplier through a single `nwAcquisitionWeight` slot on `_DeclareWarTargetContext`:

- `_declareWarSuppressedExpandColonialScore` and `_declareWarSuppressedColonialLiteScore` collapse NW colonial declare-war candidates (tribe / NW invadable / colonial-adjacent owner) to `kDeclareWarNonAdjacentSuppressedScore` iff `nwAcquisitionWeight <= 0.0` (legacy hard-suppress equivalent). The default soft-phase curve never emits `0.0` (min `0.05` at OW≤7) so EXPAND and COLONIAL-lite turns now keep NW declare-war reachable at low priority instead of structurally collapsing.
- The `_declareWarSuppressedWarConcentrationScore` colonial-pressure carve-out (`!(ctx.colonialPressure && ctx.ownsInvadableNw)`) derives `colonialPressure` from `nwAcquisitionWeight > 0.0` instead of the boolean `resolvePhaseDiplomacyDeclareWarColonialPressureActive`. The carve-out therefore scales continuously with the soft-phase NW priority rather than switching on/off at the EXPAND→COLONIAL boundary.
- Callers without a `PhasePlanOutcome` (tests, legacy entry points) fall back to a `1.0 / 0.0` weight derived from `shouldSuppressNewWorldColonialOrders` / `hasColonialAcquisitionTargets` / `isStalledOldWorldGpBlockerFocus` — preserving pre-soft-phase behaviour for the null-phase-plan path.
- `_declareWarSuppressedDevelopPhaseScore` continues to route off the boolean `resolvePhaseDiplomacyDeclareWarDevelopSuppressionActive` (DEVELOP collapses every declare-war candidate regardless of NW weight; the Phase 3 slice targets EXPAND / COLONIAL-lite only).

#### Phase 3 consumer wiring — goal-score colonial-pressure floors (Refs #2847)

`evaluateStrategicGoalScores` (`goal_manager.dart`) and `selectPrimaryGoal` consume `colonialPressureWeight` (sourced from `computePhasePriorityWeights(...).newWorldAcquisition` on the production dispatch path in `strategic_ai.dart`) as the production colonial-pressure multiplier:

- The colonial-pressure penalty/floor pass activates iff `colonialPressureWeight > 0.0` (legacy hard-suppress equivalent at `<= 0.0`).
- When active, the diplomacy/trade penalties (`kColonialDiplomacyGoalPenaltyWhenPressure`, `kColonialTradeGoalPenaltyWhenPressure`) and the conquer/expand score floors (`kMinimumColonialConquerScoreWhenPressure`, `kMinimumColonialExpandScoreWhenPressure`) scale linearly with `colonialPressureWeight` clamped to `[0.0, 1.0]` via `round()`. At `colonialPressureWeight == 1.0` the pass is identity-equal to the legacy COLONIAL-phase boolean path.
- At the early-sprint default curve (`newWorldAcquisition = 0.05` for OW ≤ 7) the floors collapse to a token nudge (`round(0.05 × 95) = 5`) so the OW conquest sprint is not dominated by colonial pressure.
- Callers that omit `colonialPressureWeight` (tests, legacy entry points) keep the legacy boolean resolution: `observerGoalPhase` routes off `resolvePhaseGoalColonialPressureActive`; callers without either parameter fall through to the `!suppressColonialPressure && hasColonialAcquisitionTargets && !shouldSuppressNewWorldColonialOrders` compose.
- When both `colonialPressureWeight` and `observerGoalPhase` are supplied, the weight takes precedence over the boolean phase gate.

#### Phase 3 consumer wiring — economy build-pick cargo bonus (Refs #2847)

`pickBuildOrder` (`build_planner.dart`) consumes `resolvePhaseEconomyColonialPressureWeight` through a new optional `BuildPickInput.colonialPressureWeight` slot as the production multiplier for the colonial cargo bonus the build pipeline applies to cargo-capable ships:

- The cargo-bonus pass activates iff the effective scale is `> 0.0`. When `BuildPickInput.colonialPressureWeight` is non-null the effective scale equals the weight clamped to `[0.0, 1.0]`. When the weight is `null` the effective scale falls back to the legacy boolean `BuildPickInput.colonialPressure` (`true -> 1.0`, `false -> 0.0`).
- When active, the cargo nudge applied in `pickBuildOrder` (`+2.5` to ships with `cargoHold > 0`) scales linearly with the effective scale. At `colonialPressureWeight == 1.0` the bonus is identity-equal to the legacy `colonialPressure == true` path (`+2.5`); at `colonialPressureWeight == 0.0` the bonus is identity-equal to `colonialPressure == false` (no bonus).
- At the early-sprint default curve (`newWorldAcquisition = 0.05` for OW ≤ 7) the cargo bonus collapses to a token nudge (`+2.5 × 0.05 = +0.125`) — well below the `kBuildRegimentBonusWhenStalledExpansion = +4.0` regiment bias under stalled-expansion pressure so the early OW conquest sprint is not dominated by colonial cargo cargo.
- `domain_planner_orchestrator.dart` sources the weight via `resolvePhaseEconomyColonialPressureWeight(phasePlan: phasePlan)` and threads both the legacy boolean (for the null-weight fallback path) and the weight (production source of truth) into `BuildPickInput`.
- Callers that construct `BuildPickInput` directly without supplying `colonialPressureWeight` (tests, legacy entry points) keep the legacy boolean behaviour exactly.

Other scoring sites (economy civilian threshold cap) still use the Phase 2 boolean resolvers until their Phase 3 slices land. Hard structural suppression for planner-module dispatch (which modules run per phase) remains unchanged in this slice.

#### Phase 3 consumer wiring — conquest army-move colonial-pressure floor (Refs #2847)

`runConquestArmyMovePlanner` (`conquest_planner.dart`) consumes the helper `conquestColonialPressureMinWeightFloor(colonialPressureWeight: ...)` (`phase_planner_conquest_filter.dart`) as the production source of truth for the colonial-pressure minimum army-move weight floor that previously activated as a hard `weight = kConquestArmyMoveMinWeightWhenColonialPressure` step under the boolean `resolvePhaseConquestColonialPressureActive`:

- The floor pass activates iff `colonialPressureWeight > 0.0`. When the planner is invoked with a `PhasePlanOutcome` the weight is `resolvePhaseConquestColonialPressureWeight(phasePlan: phasePlan)` (sourced from `priorityWeights.newWorldAcquisition`). When the planner is invoked without a `PhasePlanOutcome` the weight falls back to `1.0` if `hasColonialAcquisitionTargets(snapshot.colonial)` is `true` (legacy `colonialPressureActive` truthy path) and `0.0` otherwise — preserving pre-Phase-3 behaviour for the null-phase-plan path.
- When active, the floor magnitude scales linearly: `floor = round(kConquestArmyMoveMinWeightWhenColonialPressure × clamp(colonialPressureWeight, 0.0, 1.0))`. At `colonialPressureWeight == 1.0` the floor is identity-equal to the legacy COLONIAL hard-phase value (`45` today); at `colonialPressureWeight == 0.0` no floor applies and the upstream weight (which may already have been raised by the stalled-expansion / critically-weak floors) carries forward unchanged.
- At the early-sprint default curve (`newWorldAcquisition = 0.05` for OW ≤ 7) the floor collapses to `round(45 × 0.05) = 2` — well below the `kConquestArmyMoveMinWeightWhenStalled` floor under stalled-expansion pressure so the OW conquest sprint is not dominated by colonial-pressure pulls.
- Phase-plan-aware callers always source the weight from the dispatched plan; non-phase-plan callers (tests, legacy entry points) keep the legacy boolean behaviour exactly via the `1.0 / 0.0` fallback.

#### Phase 2 weight resolvers (Refs #2847 scaffolding)

The phase-planner filter modules (`phase_planner_conquest_filter.dart`, `phase_planner_goal_filter.dart`, `phase_planner_economy_filter.dart`, `phase_planner_diplomacy_filter.dart`) host the per-domain advisory weight resolvers consumed by future scoring-site migrations. Each resolver is a **pure, deterministic projection** of `phasePlan.priorityWeights` (or a directly supplied `PhasePriorityWeights` value when the call site has no `PhasePlanOutcome`); resolvers perform no I/O, no logging, and no order emission.

The Phase 2 resolvers ship **side by side** with the existing boolean structural-suppression resolvers (`resolvePhaseConquestSuppressNwInvasionScoring`, `resolvePhaseConquestColonialPressureActive`, ...). `resolvePhaseConquestNwInvasionWeight` is wired into conquest army-move scoring (Phase 3); the remaining booleans stay the production source of truth at their legacy sites until subsequent Phase 3 slices migrate them.

| Domain | Weight resolver | Maps to `priorityWeights` field |
|--------|-----------------|---------------------------------|
| Conquest — NW invasion scoring (declare-war / invasion army moves) | `resolvePhaseConquestNwInvasionWeight` | `newWorldAcquisition` |
| Conquest — OW invasion scoring (declare-war / army moves) | `resolvePhaseConquestOldWorldInvasionWeight` | `oldWorldConquest` |
| Conquest — colonial pressure minimum weight floor | `resolvePhaseConquestColonialPressureWeight` | `newWorldAcquisition` |
| Goal — colonial pressure score floors | `resolvePhaseGoalColonialPressureWeight` | `newWorldAcquisition` |
| Goal — OW conquest goal-score | `resolvePhaseGoalOldWorldConquestWeight` | `oldWorldConquest` |
| Economy — colonial cargo/civilian boost | `resolvePhaseEconomyColonialPressureWeight` | `newWorldAcquisition` |
| Economy — OW civilian work bias | `resolvePhaseEconomyOldWorldCivilianWeight` | `oldWorldCivilian` |
| Economy — NW civilian work bias | `resolvePhaseEconomyNewWorldCivilianWeight` | `newWorldCivilian` |
| Diplomacy — NW declare-war colonial-pressure exception | `resolvePhaseDiplomacyDeclareWarColonialPressureWeight` | `newWorldAcquisition` |
| Diplomacy — OW declare-war scoring bias | `resolvePhaseDiplomacyDeclareWarOldWorldConquestWeight` | `oldWorldConquest` |

Each resolver reads only `phasePlan.priorityWeights` (or its `PhasePriorityWeights` parameter) and never inspects sibling `PhasePlanOutcome` slots. Identical `PhasePlanOutcome` (or `PhasePriorityWeights`) inputs always yield identical `double` results in `[0.0, 1.0]` (Refs #2509 Must-have #7). The Phase 3 orchestrator-wiring slice may consume these resolvers as drop-in multipliers at scoring sites where the legacy boolean resolved to "weight = 0 or 1"; the Phase 4 SPEC alignment will retire booleans rendered redundant by that migration.

### Canonical helper homes

S1 deleted the legacy `colonial_pressure.dart` and `diplomacy_planner_peace_targets.dart` files. The predicates, deciders, and aggregators previously hosted there are now canonical in the phase-planner modules and `observer_goal_phase.dart`. No thin delegating stubs remain.

| Canonical home | Helpers (non-exhaustive — see file dartdoc for the full list) |
|----------------|----------------------------------------------------------------|
| `expand_phase_planner.dart` (+ its `expand_phase_planner_peer_peace.dart`, `expand_phase_planner_gp_blocker_peace.dart` part files) | EXPAND OW frontier helpers (`hasUninvadedOldWorldMinor`, `isOldWorldGpOnlyInvadableFrontier`, `isMutualBelowQuotaPlateauPeer`, `primaryInvadableOldWorldGpBlocker`, `isStalledOldWorldGpBlockerFocus`); below-quota regiment-rebuild predicates (`isBelowQuotaPeaceZeroRegimentsRebuild`, `isBelowQuotaPeaceInsufficientRegiments`, `isBelowQuotaPeaceTreasuryRecovery`) and the `cheapestRegimentBuildTreasuryCost` affordability gate; declare-war coordination helpers (`greatPowerWarCountOnTarget`, `pendingDeclareWarFrom`); sole-GP-war helpers (`soleAtWarGreatPowerId`, `canPivotFromSoleGpWarAfterPeace`); the EXPAND sole-GP peace deciders (`unwinnableSoleGpFrontierPeaceTarget`, `consolidateGainsSoleGpPeaceTarget`); the default-start / near-quota / futile-minor / quota-met / zero-regiment / mutual-exhausted / multi-front / GP-blocker-focus / critically-weak-blocker / stalled-distraction peace deciders; the focused-minor selectors (`stalledFocusMinorTarget`, `belowQuotaActiveMinorWarTarget`, `belowQuotaMultiMinorDistractionPeaceTargets`); and the EXPAND-stalled composite `stalledOwExpansionNeedsPeacePass`. |
| `observer_goal_phase.dart` | The cross-phase composite peace aggregators `survivalGreatPowerPeaceTargets`, `expandRatchetGreatPowerPeaceTargets`, `collectStalledGreatPowerPeaceTargets` (the single public entry consumed by `runDiplomacyPlanner` for the stalled-GP peace-target `Set<String>`), and `supplementMutualStalledGreatPowerPeaceOrders`. Per-phase GP-peace-target helpers (`expandPhaseGpPeaceTargets`, `colonialPhaseGpPeaceTargets`, `developPhaseGpPeaceTargets`) and the `observerGoalPhaseFor` phase-dispatcher live alongside. The transition guard `hasColonialAcquisitionTargets` and its goal-scoring sibling `isEarlyColonialExpansion` are also hosted here. |

The EXPAND-phase sub-deciders that the cross-phase aggregators in `observer_goal_phase.dart` fan across remain canonical in `expand_phase_planner.dart` and its part files. Tests that previously pinned the deleted-file delegating stubs now exercise the canonical helpers directly through the public ai-package API.

## Acceptance criteria

- Given a GP in EXPAND with non-empty `ConquestSummary.invadableProvinceIdsSorted` and a minor in `adjacentOwnerFactionIdsSorted` owning such a province, when `planExpandDeclareWar(game, snapshot)` runs, then it returns that minor's `factionId` (deterministic).
- Given a stalled-expansion EXPAND GP (`ow` ≤ `kStalledOldWorldProvinceThreshold`) whose field-army candidates from `suggestArmyMoveOrders` land only on own-territory provinces (none in the phase plan's authoritative invadable set), and one of those own-territory destinations is adjacent to an at-war minor/tribe-owned invadable OW province, when `runConquestArmyMovePlanner` runs with the EXPAND phase plan, then it emits an army-move targeting that own-territory frontier province (multi-turn march). Non-stalled callers (COLONIAL/DEVELOP) keep the strict invadable-only prefilter; foreign non-invadable destinations remain blocked.
- Given an EXPAND GP at war with exactly one Great Power foe whose `ConquestSummary.adjacentOwnerFactionIdsSorted` is `[peerGpId]` (the foe is the only Old World adjacent owner), both sides below `kObserverConquestMinOwProvincesPerGp` and within the mutual-plateau band (`isMutualBelowQuotaPlateauPeer` returns `true`), and at least one uninvaded Old World minor still owns provinces elsewhere on the map (`hasUninvadedOldWorldMinor` returns `true`) but no such minor owns any province adjacent to the active player, when `planExpandPeace(game, snapshot)` runs, then it returns `[peerGpId]` (geographic peer-war lock peace fires even with uninvaded minors remaining — the minor pivot is unreachable from this player's anchors; Refs #2847 § H4).
- Given an EXPAND GP `A` not currently at war with peer Great Power `B`, with `B` as the sole owner of every province in `ConquestSummary.invadableProvinceIdsSorted` (frontier is GP-only, no minor invadable), `A.treasury >= cheapestRegimentBuildTreasuryCost()`, `A`'s regiment count `>=` `B`'s regiment count, both sides in the mutual-plateau below-quota band (`isMutualBelowQuotaPlateauPeer(ownOw: A.ow, partnerOw: B.ow)` returns `true`), **and** `Game.diplomaticHistoryEvents` contains a `DiplomaticEventType.peace` event with `participants` `{A, B}` and `event.turn == currentTurn - cooldownDelta` for some `cooldownDelta` strictly less than `kExpandPeerWarPeaceCooldownTurns` (4), when `planExpandDeclareWar(game, snapshot)` runs for player `A`, then it returns `null` (priority-3 sole-GP-blocker arm is suppressed by the peer-war peace cooldown so the H4-a carve-out peace is not undone the very next turn; Refs #2847 § H2).
- Given the same inputs as the prior AC except the most-recent `DiplomaticEventType.peace` event between `{A, B}` is at least `kExpandPeerWarPeaceCooldownTurns` (4) turns old (`currentTurn - event.turn >= 4`), when `planExpandDeclareWar(game, snapshot)` runs for player `A`, then it returns `B` (cooldown lapsed; arm 3 fires; Refs #2847 § H2 boundary).
- Given a below-quota EXPAND GP with `ColonialSummary.newWorldProvincesOwned == 0`, `ConquestSummary.adjacentOwnerFactionIdsSorted == [peerGpId]` for a Great Power `peerGpId`, `0 < regimentCount < kBelowQuotaPeaceMinRegimentsBeforeDeclareWar`, non-empty `ConquestSummary.invadableProvinceIdsSorted`, and effective treasury strictly below `cheapestRegimentBuildTreasuryCost()`, when `planExpandEconomy(game, snapshot)` runs, then `ExpandEconomyPlan.forceCheapestRegimentBuild` is `true` (Arm D under the geographic peer-war lock; Refs #2847 § H3) and `ExpandEconomyPlan.boostTreasuryRecoveryCargo` is `true` (Arm C fires whenever effective treasury is below the cheapest regiment build cost, regardless of the geographic peer-war lock — the cargo signal is what the resource-need NW=0.60 weight floor in `phase_priority_weights.dart` consumes per § Resource-need overrides, so suppressing it under the lock would also disable the override the soft-phase design depends on).
- Given the same inputs as the prior AC except `ColonialSummary.newWorldProvincesOwned >= 1`, when `planExpandEconomy(game, snapshot)` runs, then `ExpandEconomyPlan.boostTreasuryRecoveryCargo` is `true` when effective treasury is strictly below `cheapestRegimentBuildTreasuryCost()` (NW ownership preserves the treasury-recovery cargo path through the standard arm-C compose).
- Given two structurally identical `(Game, AIWorldSnapshot)` inputs, when any phase-planner runs twice, then both invocations return `==`-equal values (Must-have #7).
- Given a GP in EXPAND with sea-reachable unowned NW provinces, when the EXPAND planner set runs, then merged orders contain zero NW `declareWar`, `establishOverture`, `purchase_land`, or `ArmyMoveOrder` (structural — Refs #2509).
- Given a GP in COLONIAL with embassy `OvertureStage.nap`, Friendly+ relations, and treasury ≥ `joinEmpireCostForMinorOrTribe` toward a tribe owning a visible NW province, when `planColonialAcquisition(game, snapshot)` runs, then the function returns `ColonialAcquisitionTarget(targetFactionId: tribeId, method: AcquisitionMethod.joinEmpire)`.
- Given two COLONIAL-phase snapshots identical except for `personalityId` (`napoleon` vs `henry`) with a tribe owning a NW invadable province where Join Empire gates (embassy nap, Friendly+, treasury) and `declareWar` gates (regiments ≥ 1, treasury ≥ cheapest regiment cost, not at war) both pass, when `planColonialAcquisition` runs, then `napoleon` returns `AcquisitionMethod.declareWar` and `henry` returns `AcquisitionMethod.joinEmpire` for that tribe (per `ai-personalities.md` war vs alliance modifiers).
- Given a GP in COLONIAL with tribe-owned NW invadables `pA` (distance 3) and `pB` (distance 5) where both Join-Empire gates pass and `pB < pA` lex, when `planColonialAcquisition` runs against a distance list placing `pA` first, then it returns the `pA` tribe (adjacency overrides lex).
- Given a GP in COLONIAL at war with two Great Powers where only one owns a province in `ColonialSummary.invadableNewWorldProvinceIdsSorted` and **both** at-war GPs own ≥ `kObserverConquestMinOwProvincesPerGp` OW provinces, when `planColonialPeace(game, snapshot)` runs, then the returned list includes the non-blocking GP's `factionId` and excludes the blocking GP's `factionId`.
- Given a GP in COLONIAL at war with a Great Power peer whose OW province count is **below** `kObserverConquestMinOwProvincesPerGp`, when `planColonialPeace(game, snapshot)` runs, then the returned list excludes that below-quota peer's `factionId` (Refs #2509 § Must-have #5 — "OW pressure preserved while below quota"). The COLONIAL planner must not propose `offerPeace` toward a peer still in EXPAND, otherwise the war resolver's one-sided GP peace conditions in `war_resolver.dart` (collapsed survival / consolidation arms) would end the peer's only OW frontier-blocker war before the peer reaches the quota.
- Given a GP in DEVELOP at war with any Great Powers, when `planDevelopPeace(game, snapshot)` runs, then the returned list contains exactly the at-war GP `factionId`s sorted ascending.
- Given a GP in DEVELOP with idle Builder units and unimproved extractable resource tiles on GP-owned land, when `planDevelopCivilian(game, snapshot)` runs, then the returned `List<WorkOrder>` contains `build_improvement` orders priority-ranked highest by tile yield score before any lexicographic fallback (Refs #2509 § DEVELOP § planDevelopCivilian). For each tile in priority order, `planDevelopCivilian` pairs it with the closest unassigned same-region idle Builder by Manhattan distance over the `regionId|localId|x|y` tile-key coordinates, tiebreaking by ascending Builder `id`; cross-region Builders are excluded (no naval Builder transport in DEVELOP), so a tile whose region has no remaining idle Builder is left out of the returned list (Refs #2848 § S2).
- Given a GP in COLONIAL-lite (turn ≥ `kObserverColonialLiteMinTurn`, OW = `kObserverColonialLiteNearQuotaOw`, global NW not all GP-owned) with embassy to a visible NW tribe, when `planColonialLiteOvertures(game, snapshot)` and `planColonialLiteNaval(game, snapshot)` run, then the returned overture list contains that tribe's `factionId` and the naval plan contains no invasion-transport entry (suppressed in COLONIAL-lite per Refs #2509 § COLONIAL-lite).
- Given an `AIWorldSnapshot` with `conquest.oldWorldProvincesOwned` set to any integer `ow` in `[0, 7]`, `computePhasePriorityWeights` returns a `PhasePriorityWeights` whose `oldWorldConquest == 0.95`, `newWorldAcquisition == 0.05`, `oldWorldCivilian == 0.90`, and `newWorldCivilian == 0.10` (curve plateau below the early-sprint inflection per Refs #2847 § Soft-phase priority weights curve table).
- Given an `AIWorldSnapshot` with `conquest.oldWorldProvincesOwned == 10` and the resource-need override predicates both `false` (non-zero treasury, NW provinces > 0, no boost cargo, regiment count ≥ 1), when `computePhasePriorityWeights({snapshot, game, expandEconomyPlan: ExpandEconomyPlan.defaultPlan})` runs, then the result has `oldWorldConquest == 0.60`, `newWorldAcquisition == 0.40`, `oldWorldCivilian == 0.55`, and `newWorldCivilian == 0.45` (cross-over row per Refs #2847 § Soft-phase priority weights curve table; no override floor applied).
- Given an `AIWorldSnapshot` with `conquest.oldWorldProvincesOwned == 7`, `economy.treasury == 0`, `colonial.newWorldProvincesOwned == 0`, an `ExpandEconomyPlan` whose `boostTreasuryRecoveryCargo == true`, and `regimentCountForPlayer(game, snapshot.playerId) >= 1`, when `computePhasePriorityWeights({snapshot, game, expandEconomyPlan: plan})` runs, then the result has `newWorldAcquisition == 0.60` (treasury-recovery override floor) and `oldWorldConquest == 0.95` (curve value unchanged — overrides never weaken OW conquest; Refs #2847 § Resource-need overrides).
- Given an `AIWorldSnapshot` with `conquest.oldWorldProvincesOwned == 7`, `conquest.invadableProvinceIdsSorted` non-empty, an `ExpandEconomyPlan` whose `boostTreasuryRecoveryCargo == false`, and `regimentCountForPlayer(game, snapshot.playerId) == 0`, when `computePhasePriorityWeights({snapshot, game, expandEconomyPlan: plan})` runs, then the result has `newWorldAcquisition == 0.30` (zero-regiment override floor) and `oldWorldConquest == 0.95` (curve value unchanged; Refs #2847 § Resource-need overrides).
- Given an `AIWorldSnapshot` and `Game` where both override predicates evaluate `true` on the same dispatch (`treasury == 0`, `newWorldProvincesOwned == 0`, `boostTreasuryRecoveryCargo == true`, `regimentCount == 0`, non-empty `invadableProvinceIdsSorted`), when `computePhasePriorityWeights` runs, then `newWorldAcquisition == 0.60` (the larger of the two floors wins; Refs #2847 § Resource-need overrides "When both predicates fire on the same dispatch, the larger floor wins").
- Given identical `(AIWorldSnapshot, Game, ExpandEconomyPlan)` inputs, when `computePhasePriorityWeights` runs twice, then both invocations return field-equal `PhasePriorityWeights` instances (Refs #2509 Must-have #7).
- Given any `(Game, AIWorldSnapshot, personalityId)` routing to any `ObserverGoalPhase`, when `runPhasePlanners` runs, then the returned `PhasePlanOutcome.priorityWeights` field-equals `computePhasePriorityWeights({snapshot, game, expandEconomyPlan: outcome.expandEconomyPlan})` (the dispatcher computes the weight slot from the same EXPAND plan it stores on the outcome; Refs #2847 Phase 1 scaffolding contract).
- Given a `PhasePlanOutcome` for any `ObserverGoalPhase` with any `PhasePriorityWeights` instance `w` on its `priorityWeights` slot, when `resolvePhaseConquestNwInvasionWeight({phasePlan: outcome})` runs, then the result equals `w.newWorldAcquisition` exactly (no clamping, no transformation; Refs #2847 Phase 2 scaffolding).
- Given a `PhasePlanOutcome` for any `ObserverGoalPhase` with any `PhasePriorityWeights` instance `w` on its `priorityWeights` slot, when `resolvePhaseConquestOldWorldInvasionWeight({phasePlan: outcome})` runs, then the result equals `w.oldWorldConquest` exactly (Refs #2847 Phase 2 scaffolding).
- Given a `PhasePlanOutcome` for any `ObserverGoalPhase` with any `PhasePriorityWeights` instance `w` on its `priorityWeights` slot, when `resolvePhaseConquestColonialPressureWeight({phasePlan: outcome})` runs, then the result equals `w.newWorldAcquisition` exactly (Refs #2847 Phase 2 scaffolding).
- Given a `PhasePriorityWeights` instance `w`, when `resolvePhaseGoalColonialPressureWeight(w)` runs, then the result equals `w.newWorldAcquisition` exactly (Refs #2847 Phase 2 scaffolding).
- Given a `PhasePriorityWeights` instance `w`, when `resolvePhaseGoalOldWorldConquestWeight(w)` runs, then the result equals `w.oldWorldConquest` exactly (Refs #2847 Phase 2 scaffolding).
- Given a `PhasePlanOutcome` for any `ObserverGoalPhase` with any `PhasePriorityWeights` instance `w` on its `priorityWeights` slot, when `resolvePhaseEconomyColonialPressureWeight({phasePlan: outcome})` runs, then the result equals `w.newWorldAcquisition` exactly (Refs #2847 Phase 2 scaffolding).
- Given a `PhasePlanOutcome` for any `ObserverGoalPhase` with any `PhasePriorityWeights` instance `w` on its `priorityWeights` slot, when `resolvePhaseEconomyOldWorldCivilianWeight({phasePlan: outcome})` runs, then the result equals `w.oldWorldCivilian` exactly (Refs #2847 Phase 2 scaffolding).
- Given a `PhasePlanOutcome` for any `ObserverGoalPhase` with any `PhasePriorityWeights` instance `w` on its `priorityWeights` slot, when `resolvePhaseEconomyNewWorldCivilianWeight({phasePlan: outcome})` runs, then the result equals `w.newWorldCivilian` exactly (Refs #2847 Phase 2 scaffolding).
- Given a `PhasePlanOutcome` for any `ObserverGoalPhase` with any `PhasePriorityWeights` instance `w` on its `priorityWeights` slot, when `resolvePhaseDiplomacyDeclareWarColonialPressureWeight({phasePlan: outcome})` runs, then the result equals `w.newWorldAcquisition` exactly (Refs #2847 Phase 2 scaffolding).
- Given a `PhasePlanOutcome` for any `ObserverGoalPhase` with any `PhasePriorityWeights` instance `w` on its `priorityWeights` slot, when `resolvePhaseDiplomacyDeclareWarOldWorldConquestWeight({phasePlan: outcome})` runs, then the result equals `w.oldWorldConquest` exactly (Refs #2847 Phase 2 scaffolding).
- Given two `PhasePlanOutcome` (or `PhasePriorityWeights`) inputs that are field-equal on the read field, when any of the Phase 2 weight resolvers above runs twice on each input, then both invocations return the same `double` value (Refs #2509 Must-have #7 — determinism for the Phase 2 weight-resolver scaffolding).
- Given a `PhasePlanOutcome` with `priorityWeights.newWorldAcquisition > 0.0` and a declare-war candidate targeting a tribe that owns a province in `ColonialSummary.invadableNewWorldProvinceIdsSorted`, when `_scoreDeclareWarDiplomaticOrder` runs with this `phasePlan` and a snapshot whose `oldWorldProvincesOwned >= kObserverConquestMinOwProvincesPerGp` (so the stalled-OW frontier suppression branch cannot fire) and `provincesToVictory <= kConquerScoreFloorProvincesToVictoryThreshold` (so `behindVictoryPace == false`), then the returned score is strictly greater than `kDeclareWarNonAdjacentSuppressedScore` — the EXPAND / COLONIAL-lite NW-colonial suppression branches no longer collapse the candidate, and the tribe earns at least the `kDeclareWarColonialAdjacentTribeBonus` (Refs #2847 Phase 3 diplomacy declare-war wiring).
- Given the same inputs as the previous AC except `priorityWeights.newWorldAcquisition == 0.0`, when `_scoreDeclareWarDiplomaticOrder` runs with `phase = ObserverGoalPhase.expand`, then the returned score equals `kDeclareWarNonAdjacentSuppressedScore` (the legacy hard-suppress contract is preserved exactly at `nwAcquisitionWeight <= 0.0`; Refs #2847 Phase 3 diplomacy declare-war wiring regression guard).
- Given the same inputs as the previous AC except `phase = ObserverGoalPhase.colonialLite` with `priorityWeights.newWorldAcquisition == 0.0`, when `_scoreDeclareWarDiplomaticOrder` runs, then the returned score equals `kDeclareWarNonAdjacentSuppressedScore` (COLONIAL-lite NW collapse preserved at the same weight gate; Refs #2847 Phase 3 diplomacy declare-war wiring).
- Given an `AIWorldSnapshot` with visible NW invadable targets (`hasColonialAcquisitionTargets = true`) and `conquest.provincesToVictory` below `kConquerScoreFloorProvincesToVictoryThreshold`, when `evaluateStrategicGoalScores({colonialPressureWeight: 1.0})` runs, then `conquer >= kMinimumColonialConquerScoreWhenPressure` and `expand >= kMinimumColonialExpandScoreWhenPressure` (identity-equal to the legacy COLONIAL-phase boolean path at full weight; Refs #2847 Phase 3 goal-score wiring).
- Given the same snapshot as the previous AC, when `evaluateStrategicGoalScores({colonialPressureWeight: 0.0})` runs, then `diplomacy` is strictly greater than the score returned by `evaluateStrategicGoalScores({colonialPressureWeight: null})` (the colonial-pressure pass is gated off at `<= 0.0`; legacy hard-suppress equivalent; Refs #2847 Phase 3 goal-score wiring regression guard).
- Given the same snapshot as the previous AC, when `evaluateStrategicGoalScores({colonialPressureWeight: 0.5})` runs, then `diplomacy` is strictly between the scores returned at `colonialPressureWeight: 1.0` and `colonialPressureWeight: 0.0` (continuous scaling of the colonial-pressure penalty magnitudes; Refs #2847 Phase 3 goal-score wiring).
- Given the same snapshot as the previous AC, when `evaluateStrategicGoalScores({colonialPressureWeight: 0.05})` runs, then `diplomacy` is strictly greater than the score returned at `colonialPressureWeight: 1.0` (early-sprint curve weight must not dominate the diplomacy penalty; Refs #2847 Phase 3 goal-score wiring).
- Given the same snapshot as the previous AC, when `evaluateStrategicGoalScores({observerGoalPhase: ObserverGoalPhase.colonial, colonialPressureWeight: 0.0})` runs, then `conquer < kMinimumColonialConquerScoreWhenPressure` (weight takes precedence over the COLONIAL phase boolean; Refs #2847 Phase 3 goal-score wiring).
- Given the same snapshot as the previous AC, when `evaluateStrategicGoalScores({observerGoalPhase: ObserverGoalPhase.expand, colonialPressureWeight: 1.0})` runs, then `conquer >= kMinimumColonialConquerScoreWhenPressure` (weight takes precedence over the EXPAND phase boolean suppress; Refs #2847 Phase 3 goal-score wiring).
- Given identical `(AIWorldSnapshot, AIConfig, colonialPressureWeight)` inputs, when `evaluateStrategicGoalScores` runs twice, then both invocations return field-equal `Map<StrategicGoal, int>` instances (Refs #2509 Must-have #7 — determinism for the Phase 3 goal-score wiring).
- Given a `BuildPickInput` whose `buildCandidates` includes a cargo-capable ship (`cargoHold > 0`) and a regiment, with `colonialPressure: false`, `cargoPreference: CargoPreference.none`, and `colonialPressureWeight: 1.0`, when `pickBuildOrder` runs against that input, then the ship candidate receives a `+2.5` cargo bonus identity-equal to the legacy `colonialPressure: true` path (the weight takes precedence over the legacy boolean at full weight; Refs #2847 Phase 3 economy build-pick wiring).
- Given the same input as the previous AC except `colonialPressureWeight: 0.0`, when `pickBuildOrder` runs, then the ship candidate receives no colonial-pressure cargo bonus identity-equal to the legacy `colonialPressure: false` path (the weight gates the bonus off at `<= 0.0` regardless of the legacy boolean; Refs #2847 Phase 3 economy build-pick wiring regression guard).
- Given the same input as the previous AC except `colonialPressureWeight: 0.5`, when `pickBuildOrder` runs, then the ship candidate's cargo bonus equals `+2.5 × 0.5 = +1.25` (continuous linear scaling between the legacy hard-on / hard-off magnitudes; Refs #2847 Phase 3 economy build-pick wiring).
- Given the same input as the previous AC except `colonialPressureWeight: 0.05` (early-sprint default curve), when `pickBuildOrder` runs, then the ship candidate's cargo bonus equals `+2.5 × 0.05 = +0.125` — strictly less than the regiment's `kBuildRegimentBonusWhenStalledExpansion = +4.0` under stalled-expansion pressure so the OW conquest sprint is not dominated by the colonial cargo nudge (Refs #2847 Phase 3 economy build-pick wiring).
- Given a `BuildPickInput` with `colonialPressure: true` and `colonialPressureWeight: null`, when `pickBuildOrder` runs, then the cargo bonus is `+2.5` identity-equal to the pre-Phase-3 legacy path (null-weight callers keep the legacy boolean activation/scale; Refs #2847 Phase 3 economy build-pick wiring legacy fallback).
- Given identical `(PlannerContext, BuildPickInput)` inputs with `colonialPressureWeight` pinned to any `[0.0, 1.0]` value, when `pickBuildOrder` runs twice, then both invocations return the same `BuildUnitOrder?` (Refs #2509 Must-have #7 — determinism for the Phase 3 economy build-pick wiring).
- Given `conquestColonialPressureMinWeightFloor(colonialPressureWeight: 1.0)`, when the helper runs, then the result equals `kConquestArmyMoveMinWeightWhenColonialPressure` exactly (identity-equal to the legacy COLONIAL hard-phase floor; Refs #2847 Phase 3 conquest army-move colonial-pressure floor wiring).
- Given `conquestColonialPressureMinWeightFloor(colonialPressureWeight: 0.0)`, when the helper runs, then the result equals `0` (no floor applied — legacy `colonialPressure: false` equivalent; Refs #2847 Phase 3 regression guard).
- Given `conquestColonialPressureMinWeightFloor(colonialPressureWeight: w)` for any `w` strictly between `0.0` and `1.0` (e.g. `0.5`), when the helper runs, then the result equals `round(kConquestArmyMoveMinWeightWhenColonialPressure × w)` exactly — continuous linear scaling between the legacy hard-on / hard-off magnitudes (Refs #2847 Phase 3 conquest army-move colonial-pressure floor wiring).
- Given `conquestColonialPressureMinWeightFloor(colonialPressureWeight: 0.05)` matching the early-sprint default curve `newWorldAcquisition = 0.05` for OW ≤ 7, when the helper runs, then the result equals `2` (`round(45 × 0.05)`) — strictly less than the `kConquestArmyMoveMinWeightWhenStalled` floor under stalled-expansion pressure so the OW conquest sprint is not dominated by the colonial-pressure pull (Refs #2847 Phase 3 conquest army-move colonial-pressure floor wiring).
- Given identical `colonialPressureWeight` inputs, when `conquestColonialPressureMinWeightFloor` runs twice, then both invocations return the same `int` value (Refs #2509 Must-have #7 — determinism for the Phase 3 conquest army-move colonial-pressure floor wiring).
- Given a `PlannerContext` with a `PhasePlanOutcome` whose `priorityWeights.newWorldAcquisition == 1.0`, an `AIWorldSnapshot` with `oldWorldProvincesOwned == 12` (above quota, not stalled-expansion), `provincesToVictory == 5` (below `kConquerScoreFloorProvincesToVictoryThreshold`), `primaryGoal == StrategicGoal.trade`, a base military-economy weight strictly below `kConquestArmyMoveMinWeightWhenColonialPressure`, a non-empty diplomacy-passed army-move candidate set with the active player at war with at least one Great Power owning a province in `invadableProvinceIdsSorted`, when `runConquestArmyMovePlanner` runs with this `phasePlan`, then the army-move pass emits at least one army move (the colonial-pressure floor at `weight = 1.0` raises the base weight to `kConquestArmyMoveMinWeightWhenColonialPressure`, above the `weight < 10` short-circuit threshold; Refs #2847 Phase 3 conquest army-move colonial-pressure floor wiring positive pin).
- Given the same inputs as the previous AC except the `PhasePlanOutcome.priorityWeights.newWorldAcquisition == 0.0`, when `runConquestArmyMovePlanner` runs with this `phasePlan`, then the army-move pass emits zero army moves (no colonial-pressure floor applied; base weight stays below the `weight < 10` short-circuit; Refs #2847 Phase 3 conquest army-move colonial-pressure floor wiring regression guard).

## Interactions

- [ai-architecture.md](ai-architecture.md) — phase definitions, suppression rules, COLONIAL-lite safeguard, EXPAND regiment-rebuild trap.
- [ai-personalities.md](ai-personalities.md) — personality bias rules (see § Personality bias).
- [ai-planner.md](../program/ai-planner.md), [ai-systems-impl.md](../program/ai-systems-impl.md) — orchestrator merge semantics and module boundaries.
- [run_observer_game-tool.md](../program/run_observer_game-tool.md) — nightly observer gates (turn-100 OW, turn-150 NW + improvement).
