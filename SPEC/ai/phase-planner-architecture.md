## Phase planner architecture (Refs #2509)

**SPEC/ai** sub-spec for the single-goal phase-planner architecture in Full AI. Companion to [ai-architecture.md](ai-architecture.md) § Observer goal phases; derives from [world-model.md](../game/world-model.md), [victory.md](../game/victory.md), [diplomacy.md](../game/diplomacy.md), [ai-planner.md](../program/ai-planner.md), [ai-systems-impl.md](../program/ai-systems-impl.md).

## Overview

Each Great Power computes a deterministic `ObserverGoalPhase` from its `PlayerView` → `AIWorldSnapshot` once per turn. The phase dispatches to a self-contained **planner module** that makes one primary decision per domain — no cross-phase score aggregation or predicate fan-out.

Phase definitions, suppressions, and COLONIAL-lite stay normative in [ai-architecture.md](ai-architecture.md). This file specifies module contracts, orchestrator dispatch, data flow, and acceptance criteria for the phase-planner replacement of the legacy scoring-ratchet helpers.

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

Phase-specific peace/declare-war targets feed `runDiplomacyPlannerWithResult`; work and army-move plans feed the economy / conquest passes. The `collectStalledGreatPowerPeaceTargets` aggregate is retired by S5. Dispatcher: [phase-planner-dispatch.md](phase-planner-dispatch.md).

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
- Enter **COLONIAL** when OW ≥ 10 and `hasColonialAcquisitionTargets`.
- Enter **DEVELOP** when OW ≥ 10 and no visible colonial targets.
- **COLONIAL-lite** is a parallel entry inside EXPAND (turn ≥ `kObserverColonialLiteMinTurn`, OW ≥ `kObserverColonialLiteNearQuotaOw` and below quota, global `newWorld|` not all GP-owned).

## Acceptance criteria

- Given a GP in EXPAND with non-empty `ConquestSummary.invadableProvinceIdsSorted` and a minor in `adjacentOwnerFactionIdsSorted` owning such a province, when `planExpandDeclareWar(game, snapshot)` runs, then it returns that minor's `factionId` (deterministic).
- Given two structurally identical `(Game, AIWorldSnapshot)` inputs, when any phase-planner runs twice, then both invocations return `==`-equal values (Must-have #7).
- Given a GP in EXPAND with sea-reachable unowned NW provinces, when the EXPAND planner set runs, then merged orders contain zero NW `declareWar`, `establishOverture`, `purchase_land`, or `ArmyMoveOrder` (structural — Refs #2509).
- Given a GP in COLONIAL with embassy `OvertureStage.nap`, Friendly+ relations, and treasury ≥ `joinEmpireCostForMinorOrTribe` toward a tribe owning a visible NW province, when `planColonialAcquisition(game, snapshot)` runs, then the function returns `ColonialAcquisitionTarget(targetFactionId: tribeId, method: AcquisitionMethod.joinEmpire)`.
- Given two COLONIAL-phase snapshots identical except for `personalityId` (`napoleon` vs `henry`) with a tribe owning a NW invadable province where Join Empire gates (embassy nap, Friendly+, treasury) and `declareWar` gates (regiments ≥ 1, treasury ≥ cheapest regiment cost, not at war) both pass, when `planColonialAcquisition` runs, then `napoleon` returns `AcquisitionMethod.declareWar` and `henry` returns `AcquisitionMethod.joinEmpire` for that tribe (per `ai-personalities.md` war vs alliance modifiers).
- Given a GP in COLONIAL with tribe-owned NW invadables `pA` (distance 3) and `pB` (distance 5) where both Join-Empire gates pass and `pB < pA` lex, when `planColonialAcquisition` runs against a distance list placing `pA` first, then it returns the `pA` tribe (adjacency overrides lex).
- Given a GP in COLONIAL at war with two Great Powers where only one owns a province in `ColonialSummary.invadableNewWorldProvinceIdsSorted`, when `planColonialPeace(game, snapshot)` runs, then the returned list includes the non-blocking GP's `factionId` and excludes the blocking GP's `factionId`.
- Given a GP in DEVELOP at war with any Great Powers, when `planDevelopPeace(game, snapshot)` runs, then the returned list contains exactly the at-war GP `factionId`s sorted ascending.
- Given a GP in DEVELOP with idle Builder units and unimproved extractable resource tiles on GP-owned land, when `planDevelopCivilian(game, snapshot)` runs, then the returned `List<WorkOrder>` contains `build_improvement` orders priority-ranked highest by tile yield score before any lexicographic fallback (Refs #2509 § DEVELOP § planDevelopCivilian).
- Given a GP in COLONIAL-lite (turn ≥ `kObserverColonialLiteMinTurn`, OW = `kObserverColonialLiteNearQuotaOw`, global NW not all GP-owned) with embassy to a visible NW tribe, when `planColonialLiteOvertures(game, snapshot)` and `planColonialLiteNaval(game, snapshot)` run, then the returned overture list contains that tribe's `factionId` and the naval plan contains no invasion-transport entry (suppressed in COLONIAL-lite per Refs #2509 § COLONIAL-lite).

## Interactions

- [ai-architecture.md](ai-architecture.md) — phase definitions, suppression rules, COLONIAL-lite safeguard, EXPAND regiment-rebuild trap.
- [ai-personalities.md](ai-personalities.md) — personality bias rules (see § Personality bias).
- [ai-planner.md](../program/ai-planner.md), [ai-systems-impl.md](../program/ai-systems-impl.md) — orchestrator merge semantics and module boundaries.
- [run_observer_game-tool.md](../program/run_observer_game-tool.md) — nightly observer gates (turn-100 OW, turn-150 NW + improvement).
