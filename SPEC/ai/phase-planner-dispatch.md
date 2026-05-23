## Phase planner dispatcher (Refs #2509 S5 foundation)

**SPEC/ai** sub-spec for the `runPhasePlanners` dispatcher and `PhasePlanOutcome` value class. Companion to [phase-planner-architecture.md](phase-planner-architecture.md) § Orchestrator dispatch; derives from [ai-architecture.md](ai-architecture.md) § Observer goal phases.

## Overview

`phase_planner_dispatch.dart` (in `packages/colonizethis_ai/lib/src/planning/`) exposes a single pure function `runPhasePlanners({game, snapshot, personalityId})` that calls `observerGoalPhaseFor(snapshot, game)` once and composes the per-phase planner outputs into a `PhasePlanOutcome` value class.

The dispatcher is the wiring layer between phase resolution and the per-domain pure-function planner modules. It performs no I/O, no logging, no order emission, and is deterministic by construction (Must-have #7). The orchestrator (S5 target) consumes `PhasePlanOutcome` to feed `runDiplomacyPlannerWithResult`, the economy passes, and the army-move planner without re-checking phase in every call site.

## Rules

### Dispatch matrix

| Phase | Calls (in order) |
|-------|------------------|
| `expand` | `planExpandDeclareWar`, `planExpandPeace`, `planExpandEconomy`, `planExpandMilitary(declaredWarTargetFactionId)` |
| `colonialLite` | All four EXPAND calls, plus `planColonialLiteOvertures`, `planColonialLiteNaval` |
| `colonial` | `planColonialAcquisition(personalityId)`, `planColonialPeace`, `planColonialMilitary(colonialDeclaredWarTargetFactionId)`, `planColonialNaval(colonialDeclaredWarTargetFactionId)`, `planColonialCivilian` |
| `develop` | `planDevelopPeace`, `planDevelopCivilian` |

### Argument pairing

- The EXPAND `declareWarTargetFactionId` argument to `planExpandMilitary` is the same value `planExpandDeclareWar` returned in this dispatch call (may be `null`).
- The COLONIAL `colonialDeclaredWarTargetFactionId` argument to both `planColonialMilitary` and `planColonialNaval` is `colonialAcquisitionTarget.targetFactionId` only when the resolved acquisition method is `AcquisitionMethod.declareWar`. For `joinEmpire`, `purchase_land`, or `null` acquisitions the argument is `null`, so the military/naval pair falls back to the at-war arm.
- The `personalityId` argument is forwarded to `planColonialAcquisition`; it is dead for non-COLONIAL phases.

### Suppression matrix (PhasePlanOutcome slots)

`PhasePlanOutcome` carries one slot per planner output. Slots unused by the active phase carry default-plan or empty values so callers may read every slot unconditionally.

| Phase | Slots populated with non-default content |
|-------|------------------------------------------|
| `expand` | `expandDeclareWarTargetFactionId`, `expandPeaceTargetFactionIdsSorted`, `expandEconomyPlan`, `expandMilitaryPlan` |
| `colonialLite` | All EXPAND slots above, plus `colonialLiteOverturesSorted`, `colonialLiteNavalPlan` |
| `colonial` | `colonialAcquisitionTarget`, `colonialPeaceTargetFactionIdsSorted`, `colonialMilitaryPlan`, `colonialNavalPlan`, `colonialCivilianWorkOrders` |
| `develop` | `developPeaceTargetFactionIdsSorted`, `developCivilianWorkOrders` |

Full-COLONIAL slots stay default under COLONIAL-lite. This is the structural NW-acquisition suppression for the colonial-lite safeguard — the dispatcher never calls `planColonialAcquisition`, `planColonialMilitary`, `planColonialNaval`, or `planColonialCivilian` in `colonialLite`, so `declareWar` / `joinEmpire` / `purchase_land` / invasion-transport are unreachable per spec.

### Default outcome constants

`PhasePlanOutcome.defaultExpand`, `.defaultColonialLite`, `.defaultColonial`, `.defaultDevelop` provide const-shared all-default instances per phase for short-circuit returns when every planner in the set reaches its outer guard.

## Acceptance criteria

- Given a `(Game, AIWorldSnapshot)` pair whose `observerGoalPhaseFor` resolves to `ObserverGoalPhase.expand`, when `runPhasePlanners(game, snapshot)` runs, then `PhasePlanOutcome.phase == ObserverGoalPhase.expand`, the four EXPAND slots equal the corresponding direct planner calls (with `planExpandMilitary` invoked with the same `declaredWarTargetFactionId` as `planExpandDeclareWar` returned), and all COLONIAL-lite / COLONIAL / DEVELOP slots equal their default-plan or empty values.
- Given a `(Game, AIWorldSnapshot)` pair routing to `ObserverGoalPhase.colonialLite`, when `runPhasePlanners(game, snapshot)` runs, then the EXPAND slots and the two COLONIAL-lite slots populate, while `colonialAcquisitionTarget`, `colonialPeaceTargetFactionIdsSorted`, `colonialMilitaryPlan`, `colonialNavalPlan`, `colonialCivilianWorkOrders`, and the DEVELOP slots equal their default-plan / empty values.
- Given a `(Game, AIWorldSnapshot)` pair routing to `ObserverGoalPhase.colonial` where `planColonialAcquisition` returns `ColonialAcquisitionTarget(targetFactionId: T, method: AcquisitionMethod.declareWar)`, when `runPhasePlanners(game, snapshot)` runs, then `colonialMilitaryPlan` and `colonialNavalPlan` are field-equal to `planColonialMilitary` and `planColonialNaval` invoked with `colonialDeclaredWarTargetFactionId: T`, and the EXPAND / COLONIAL-lite / DEVELOP slots equal their default-plan / empty values.
- Given a `(Game, AIWorldSnapshot)` pair routing to `ObserverGoalPhase.colonial` where `planColonialAcquisition` returns `null`, when `runPhasePlanners(game, snapshot)` runs, then `colonialMilitaryPlan` and `colonialNavalPlan` equal direct calls with `colonialDeclaredWarTargetFactionId: null` (at-war fallback arm).
- Given a `(Game, AIWorldSnapshot)` pair routing to `ObserverGoalPhase.develop`, when `runPhasePlanners(game, snapshot)` runs, then only `developPeaceTargetFactionIdsSorted` and `developCivilianWorkOrders` populate; every other slot equals its default-plan / empty value.
- Given identical `(Game, AIWorldSnapshot, personalityId)` inputs, when `runPhasePlanners` runs twice, then both invocations return field-equal `PhasePlanOutcome` instances (Must-have #7 determinism).

## Interactions

- [phase-planner-architecture.md](phase-planner-architecture.md) — phase definitions, planner-module contracts, orchestrator dispatch table.
- [ai-architecture.md](ai-architecture.md) — phase suppression rules, COLONIAL-lite safeguard.
- [ai-personalities.md](ai-personalities.md) — `personalityId` argument semantics for `planColonialAcquisition`.
