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
- Given a below-quota EXPAND GP with `ColonialSummary.newWorldProvincesOwned == 0`, `ConquestSummary.adjacentOwnerFactionIdsSorted == [peerGpId]` for a Great Power `peerGpId`, `0 < regimentCount < kBelowQuotaPeaceMinRegimentsBeforeDeclareWar`, non-empty `ConquestSummary.invadableProvinceIdsSorted`, and effective treasury strictly below `cheapestRegimentBuildTreasuryCost()`, when `planExpandEconomy(game, snapshot)` runs, then `ExpandEconomyPlan.forceCheapestRegimentBuild` is `true` and `ExpandEconomyPlan.boostTreasuryRecoveryCargo` is `false` (Refs #2847 § H3 + § H5).
- Given the same inputs as the prior AC except `ColonialSummary.newWorldProvincesOwned >= 1`, when `planExpandEconomy(game, snapshot)` runs, then `ExpandEconomyPlan.boostTreasuryRecoveryCargo` is `true` when effective treasury is strictly below `cheapestRegimentBuildTreasuryCost()` (NW ownership restores the treasury-recovery cargo path; Refs #2847 § H5 negative).
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

## Interactions

- [ai-architecture.md](ai-architecture.md) — phase definitions, suppression rules, COLONIAL-lite safeguard, EXPAND regiment-rebuild trap.
- [ai-personalities.md](ai-personalities.md) — personality bias rules (see § Personality bias).
- [ai-planner.md](../program/ai-planner.md), [ai-systems-impl.md](../program/ai-systems-impl.md) — orchestrator merge semantics and module boundaries.
- [run_observer_game-tool.md](../program/run_observer_game-tool.md) — nightly observer gates (turn-100 OW, turn-150 NW + improvement).
