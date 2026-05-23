## Phase planner architecture (Refs #2509)

**SPEC/ai** sub-spec. Source of truth for the single-goal phase-planner architecture used by Full AI. Companion to [ai-architecture.md](ai-architecture.md) § Observer goal phases. Derives from GDD ([world-model.md](../game/world-model.md), [victory.md](../game/victory.md), [diplomacy.md](../game/diplomacy.md)) and TDD ([ai-planner.md](../program/ai-planner.md), [ai-systems-impl.md](../program/ai-systems-impl.md)).

## Overview

Each Great Power computes a deterministic `ObserverGoalPhase` from its `PlayerView` → `AIWorldSnapshot` once per turn. The phase is the only routing decision the orchestrator needs. Each phase dispatches to a self-contained **planner module** that makes one primary decision per domain. No score aggregation across phases; no cross-phase predicate fan-out.

Phase definitions, suppression rules, and the COLONIAL-lite safeguard are normative in [ai-architecture.md](ai-architecture.md) § Observer goal phases (preserved). This file specifies the **planner module contracts**, **orchestrator dispatch**, **data flow**, and **acceptance criteria** for the phase-planner replacement of the legacy scoring-ratchet helpers (`colonial_pressure.dart`, `diplomacy_planner_peace_targets.dart`).

## Rules

### Planner module contracts

Each function is a **pure** function: same `(Game, AIWorldSnapshot, optional phase-specific input)` → same output. No mutable state beyond the snapshot. Returned plans are value classes or sorted lists. Determinism is required (Must-have #7).

| Phase | Module (`packages/colonizethis_ai/lib/src/planning/`) | Functions |
|-------|------------------------------------------------------|-----------|
| EXPAND | `expand_phase_planner.dart` | `planExpandDeclareWar`, `planExpandPeace`, `planExpandEconomy`, `planExpandMilitary` |
| COLONIAL-lite | `colonial_phase_planner.dart` | `planColonialLiteOvertures`, `planColonialLiteNaval` |
| COLONIAL | `colonial_phase_planner.dart` | `planColonialAcquisition`, `planColonialPeace`, `planColonialMilitary`, `planColonialNaval`, `planColonialCivilian` |
| DEVELOP | `develop_phase_planner.dart` | `planDevelopPeace`, `planDevelopCivilian` |

**Structural suppression:** Each module imports only the perception types and helpers it needs. EXPAND never imports `colonial_phase_planner.dart`, never queries `ColonialSummary`, and never produces NW orders. DEVELOP never produces `declareWar` or NW orders. COLONIAL-lite is the only sanctioned NW exception inside EXPAND. Suppression is an architectural property of the module set, not a runtime predicate check.

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

Phase-specific peace targets and declare-war targets are injected into `runDiplomacyPlannerWithResult` directly; phase-specific work and army-move plans are injected into the economy / conquest army-move passes. The legacy `collectStalledGreatPowerPeaceTargets` aggregate is retired by S5 (Refs #2509 § Files to modify).

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

The planner modules never call into one another. The orchestrator owns the only cross-module coordination — for example, passing `planColonialAcquisition`'s `declareWar` faction id into `planColonialMilitary` and `planColonialNaval` as the priority target argument.

### Phase transition guard

- Enter **EXPAND** when `oldWorldProvincesOwned < kObserverConquestMinOwProvincesPerGp` (10). A province loss immediately restores EXPAND; no hysteresis at quota+1.
- Enter **COLONIAL** when OW ≥ 10 and `hasColonialAcquisitionTargets`.
- Enter **DEVELOP** when OW ≥ 10 and no visible colonial targets.
- **COLONIAL-lite** is a parallel entry inside EXPAND (turn ≥ `kObserverColonialLiteMinTurn`, OW ≥ `kObserverColonialLiteNearQuotaOw` and below quota, global `newWorld|` not all GP-owned).

## Acceptance criteria

- Given a GP in EXPAND with non-empty `ConquestSummary.invadableProvinceIdsSorted` and a minor in `adjacentOwnerFactionIdsSorted` owning at least one such province, when `planExpandDeclareWar(game, snapshot)` runs, then the function returns that minor's `factionId` (deterministic for fixed inputs).
- Given two `(Game, AIWorldSnapshot)` inputs that are structurally identical, when any phase-planner function runs twice, then the two invocations return values that compare equal per the contract type's `==` operator (Must-have #7 determinism).
- Given a GP in EXPAND with one or more sea-reachable unowned NW provinces, when the EXPAND planner set runs, then the merged orders contain zero NW `declareWar`, NW `establishOverture`, NW `purchase_land`, or NW `ArmyMoveOrder` entries (structural suppression — Refs #2509 § EXPAND Suppressions).
- Given a GP in COLONIAL with embassy `OvertureStage.nap`, Friendly+ relations, and treasury ≥ `joinEmpireCostForMinorOrTribe` toward a tribe owning a visible NW province, when `planColonialAcquisition(game, snapshot)` runs, then the function returns `ColonialAcquisitionTarget(targetFactionId: tribeId, method: AcquisitionMethod.joinEmpire)`.
- Given a GP in COLONIAL at war with two Great Powers where only one owns a province in `ColonialSummary.invadableNewWorldProvinceIdsSorted`, when `planColonialPeace(game, snapshot)` runs, then the returned list includes the non-blocking GP's `factionId` and excludes the blocking GP's `factionId`.
- Given a GP in DEVELOP at war with any Great Powers, when `planDevelopPeace(game, snapshot)` runs, then the returned list contains exactly the at-war GP `factionId`s sorted ascending.
- Given a GP in DEVELOP with idle Builder units and unimproved extractable resource tiles on GP-owned land, when `planDevelopCivilian(game, snapshot)` runs, then the returned `List<WorkOrder>` contains `build_improvement` orders priority-ranked highest by tile yield score before any lexicographic fallback (Refs #2509 § DEVELOP § planDevelopCivilian).
- Given a GP in COLONIAL-lite (turn ≥ `kObserverColonialLiteMinTurn`, OW = `kObserverColonialLiteNearQuotaOw`, global NW not all GP-owned) with embassy to a visible NW tribe, when `planColonialLiteOvertures(game, snapshot)` and `planColonialLiteNaval(game, snapshot)` run, then the returned overture list contains that tribe's `factionId` and the naval plan contains no invasion-transport entry (suppressed in COLONIAL-lite per Refs #2509 § COLONIAL-lite).

## Interactions

- [ai-architecture.md](ai-architecture.md) — phase definitions, suppression rules, COLONIAL-lite safeguard, EXPAND regiment-rebuild trap; this file specifies the planner module contracts and orchestrator dispatch the architecture relies on.
- [ai-personalities.md](ai-personalities.md) — personality modifiers bias `planColonialAcquisition` method ordering between Join Empire and declareWar (within structural priority).
- Program: [ai-planner.md](../program/ai-planner.md), [ai-systems-impl.md](../program/ai-systems-impl.md) — orchestrator merge semantics and module boundaries.
- [run_observer_game-tool.md](../program/run_observer_game-tool.md) — nightly observer gates (turn-100 OW, turn-150 NW + improvement) verify the phase-planner architecture converges on canonical seed 42.
