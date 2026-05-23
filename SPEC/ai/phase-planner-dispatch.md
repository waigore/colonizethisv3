## Phase planner dispatcher (Refs #2509 S5 foundation)

**SPEC/ai** sub-spec for the `runPhasePlanners` dispatcher and `PhasePlanOutcome` value class. Companion to [phase-planner-architecture.md](phase-planner-architecture.md) § Orchestrator dispatch; derives from [ai-architecture.md](ai-architecture.md) § Observer goal phases.

## Overview

`phase_planner_dispatch.dart` (in `packages/colonizethis_ai/lib/src/planning/`) exposes a single pure function `runPhasePlanners({game, snapshot, personalityId})` that calls `observerGoalPhaseFor(snapshot, game)` once and composes the per-phase planner outputs into a `PhasePlanOutcome` value class.

The dispatcher is the wiring layer between phase resolution and the per-domain pure-function planner modules. It performs no I/O, no logging, no order emission, and is deterministic by construction (Must-have #7). The orchestrator (S5) consumes `PhasePlanOutcome` to feed `runDiplomacyPlannerWithResult`, the economy passes, and the army-move planner without re-checking phase in every call site.

**Orchestrator diplomacy slices (landed):** `domain_planner_orchestrator.dart` calls `runPhasePlanners` once per player turn and passes the result into every `runDiplomacyPlannerWithResult` invocation. `phase_planner_peace_targets.dart` maps the active phase to the peace-target list (`gpPeaceTargetsFromPhasePlan`); `_stalledPeacePlannerResultIfNeeded` uses that list instead of `collectStalledGreatPowerPeaceTargets` when `phasePlan` is set. `phase_planner_declare_war_targets.dart` exposes `gpExpandDeclareWarTargetFromPhasePlan` and `gpColonialDeclareWarTargetFromPhasePlan`; `_phasePlannerDeclareWarPlannerResultIfNeeded` in `diplomacy_planner.dart` forces `declareWar` from those adapters when `phasePlan` is set. When both adapters return `null` the legacy `colonial_pressure` forced-declare ratchet runs as a fallback so dev-pinned below-quota minor and GP-only invadable frontier blocker declare contracts (e.g. `domain_planner_orchestrator_expand_gp_only_blocker_declare_test.dart`, `war_declaration_target_scoring_warmonger_test.dart`) survive the S5 migration; the legacy helpers are retired structurally in S1 once the phase planner fully reproduces their semantics. Economy, conquest, and naval wiring remain on the legacy path until later S5 slices.

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

### Adapter helpers

Four pure adapter functions extract per-domain orchestrator-ready values from a single `PhasePlanOutcome`. The orchestrator calls `runPhasePlanners` once per player turn and consumes the adapters' outputs repeatedly without re-checking the active phase. All adapters are pure and deterministic (Must-have #7).

| Adapter | Module | Output | EXPAND | COLONIAL-lite | COLONIAL | DEVELOP |
|---|---|---|---|---|---|---|
| `gpPeaceTargetsFromPhasePlan` | `phase_planner_peace_targets.dart` | `List<String>` GP `offerPeace` targets | `expandPeaceTargetFactionIdsSorted` | `expandPeaceTargetFactionIdsSorted` | `colonialPeaceTargetFactionIdsSorted` | `developPeaceTargetFactionIdsSorted` |
| `gpExpandDeclareWarTargetFromPhasePlan` | `phase_planner_declare_war_targets.dart` | `String?` OW declare-war target | `expandDeclareWarTargetFactionId` | `expandDeclareWarTargetFactionId` | `null` | `null` |
| `gpColonialDeclareWarTargetFromPhasePlan` | `phase_planner_declare_war_targets.dart` | `String?` NW declare-war target | `null` | `null` | `colonialAcquisitionTarget.targetFactionId` when method is `declareWar`, else `null` | `null` |
| `civilianWorkOrdersFromPhasePlan` | `phase_planner_civilian_work_orders.dart` | `List<WorkOrder>` civilian work to append to the economy pass | `const <WorkOrder>[]` | `const <WorkOrder>[]` | `colonialCivilianWorkOrders` | `developCivilianWorkOrders` |

EXPAND continues running during COLONIAL-lite, so the EXPAND adapters surface their slot under both `expand` and `colonialLite`. The COLONIAL declare-war adapter returns `null` when the acquisition method is `joinEmpire` / `purchase_land` or the target is `null` (at-war fallback). DEVELOP never declares war. The civilian work-order adapter returns an empty list under EXPAND and COLONIAL-lite (EXPAND publishes only `ExpandEconomyPlan` flags; COLONIAL-lite suppresses NW builds so the OW push is not weakened — issue #2509 § COLONIAL-lite).

## Acceptance criteria

- Given a `(Game, AIWorldSnapshot)` pair whose `observerGoalPhaseFor` resolves to `ObserverGoalPhase.expand`, when `runPhasePlanners(game, snapshot)` runs, then `PhasePlanOutcome.phase == ObserverGoalPhase.expand`, the four EXPAND slots equal the corresponding direct planner calls (with `planExpandMilitary` invoked with the same `declaredWarTargetFactionId` as `planExpandDeclareWar` returned), and all COLONIAL-lite / COLONIAL / DEVELOP slots equal their default-plan or empty values.
- Given a `(Game, AIWorldSnapshot)` pair routing to `ObserverGoalPhase.colonialLite`, when `runPhasePlanners(game, snapshot)` runs, then the EXPAND slots and the two COLONIAL-lite slots populate, while `colonialAcquisitionTarget`, `colonialPeaceTargetFactionIdsSorted`, `colonialMilitaryPlan`, `colonialNavalPlan`, `colonialCivilianWorkOrders`, and the DEVELOP slots equal their default-plan / empty values.
- Given a `(Game, AIWorldSnapshot)` pair routing to `ObserverGoalPhase.colonial` where `planColonialAcquisition` returns `ColonialAcquisitionTarget(targetFactionId: T, method: AcquisitionMethod.declareWar)`, when `runPhasePlanners(game, snapshot)` runs, then `colonialMilitaryPlan` and `colonialNavalPlan` are field-equal to `planColonialMilitary` and `planColonialNaval` invoked with `colonialDeclaredWarTargetFactionId: T`, and the EXPAND / COLONIAL-lite / DEVELOP slots equal their default-plan / empty values.
- Given a `(Game, AIWorldSnapshot)` pair routing to `ObserverGoalPhase.colonial` where `planColonialAcquisition` returns `null`, when `runPhasePlanners(game, snapshot)` runs, then `colonialMilitaryPlan` and `colonialNavalPlan` equal direct calls with `colonialDeclaredWarTargetFactionId: null` (at-war fallback arm).
- Given a `(Game, AIWorldSnapshot)` pair routing to `ObserverGoalPhase.develop`, when `runPhasePlanners(game, snapshot)` runs, then only `developPeaceTargetFactionIdsSorted` and `developCivilianWorkOrders` populate; every other slot equals its default-plan / empty value.
- Given identical `(Game, AIWorldSnapshot, personalityId)` inputs, when `runPhasePlanners` runs twice, then both invocations return field-equal `PhasePlanOutcome` instances (Must-have #7 determinism).
- Given a `PhasePlanOutcome` with `phase == ObserverGoalPhase.expand` or `ObserverGoalPhase.colonialLite`, when `gpExpandDeclareWarTargetFromPhasePlan(outcome)` runs, then the return value equals `outcome.expandDeclareWarTargetFactionId`; given the same outcome with `phase == ObserverGoalPhase.colonial` or `ObserverGoalPhase.develop`, the return value equals `null` even when the EXPAND slot is non-null.
- Given a `PhasePlanOutcome` with `phase == ObserverGoalPhase.colonial` and `colonialAcquisitionTarget.method == AcquisitionMethod.declareWar`, when `gpColonialDeclareWarTargetFromPhasePlan(outcome)` runs, then the return value equals `colonialAcquisitionTarget.targetFactionId`; given the same outcome with `method` set to `joinEmpire` or `purchaseLand`, or with `colonialAcquisitionTarget == null`, the return value equals `null`.
- Given a `PhasePlanOutcome` whose `phase` is `ObserverGoalPhase.expand`, `ObserverGoalPhase.colonialLite`, or `ObserverGoalPhase.develop`, when `gpColonialDeclareWarTargetFromPhasePlan(outcome)` runs, then the return value equals `null` even when `colonialAcquisitionTarget` is non-null (structural phase suppression).
- Given a `PhasePlanOutcome` with `phase == ObserverGoalPhase.colonial`, when `civilianWorkOrdersFromPhasePlan(outcome)` runs, then the return value equals `outcome.colonialCivilianWorkOrders` (same order, same instances); with `phase == ObserverGoalPhase.develop` the return value equals `outcome.developCivilianWorkOrders`; with `phase == ObserverGoalPhase.expand` or `ObserverGoalPhase.colonialLite` the return value equals `const <WorkOrder>[]` even when COLONIAL / DEVELOP slots are non-empty (structural NW-civilian-work suppression).

## Interactions

- [phase-planner-architecture.md](phase-planner-architecture.md) — phase definitions, planner-module contracts, orchestrator dispatch table.
- [ai-architecture.md](ai-architecture.md) — phase suppression rules, COLONIAL-lite safeguard.
- [ai-personalities.md](ai-personalities.md) — `personalityId` argument semantics for `planColonialAcquisition`.
