## Phase planner dispatcher (Refs #2509 S5 foundation)

**SPEC/ai** sub-spec for the `runPhasePlanners` dispatcher and `PhasePlanOutcome` value class. Companion to [phase-planner-architecture.md](phase-planner-architecture.md) § Orchestrator dispatch; derives from [ai-architecture.md](ai-architecture.md) § Observer goal phases.

## Overview

`phase_planner_dispatch.dart` (in `packages/colonizethis_ai/lib/src/planning/`) exposes a single pure function `runPhasePlanners({game, snapshot, personalityId})` that calls `observerGoalPhaseFor(snapshot, game)` once and composes the per-phase planner outputs into a `PhasePlanOutcome` value class.

The dispatcher is the wiring layer between phase resolution and the per-domain pure-function planner modules. It performs no I/O, no logging, no order emission, and is deterministic by construction (Must-have #7). The orchestrator (S5) consumes `PhasePlanOutcome` to feed `runDiplomacyPlannerWithResult`, the economy passes, and the army-move planner without re-checking phase in every call site.

**Orchestrator diplomacy slices (landed):** `domain_planner_orchestrator.dart` calls `runPhasePlanners` once per player turn and threads the result into every `runDiplomacyPlannerWithResult` invocation. `_stalledPeacePlannerResultIfNeeded` uses `gpPeaceTargetsFromPhasePlan` instead of `collectStalledGreatPowerPeaceTargets` when `phasePlan` is set. `_phasePlannerDeclareWarPlannerResultIfNeeded` forces `declareWar` from `gpExpandDeclareWarTargetFromPhasePlan` / `gpColonialDeclareWarTargetFromPhasePlan`; when both return `null` the legacy `colonial_pressure` ratchet runs as fallback to preserve dev-pinned below-quota minor and GP-only invadable frontier blocker contracts during the S5 migration. Legacy helpers retire structurally in S1 once the phase planner fully reproduces their semantics.

**Orchestrator conquest slice (landed):** `runConquestArmyMovePlanner` accepts optional `phasePlan` from the orchestrator. `resolvePhaseConquestInvadable` (`phase_planner_conquest_filter.dart`) restricts the invadable destination set to `expandMilitaryPlanFromPhasePlan` / `colonialMilitaryPlanFromPhasePlan` when either plan is non-default; when both are default it falls back to the legacy invadable union with structural NW suppression under EXPAND / COLONIAL-lite and skips the pass entirely under DEVELOP. Economy wiring remains on the legacy path until a later S5 slice.

**Orchestrator naval slice (landed):** `runNavalPlanner` accepts optional `phasePlan` from the orchestrator. `resolvePhaseNavalDirective` (`phase_planner_naval_filter.dart`) drives the colonial-pressure naval boost + ranking from the active phase: COLONIAL and COLONIAL-lite engage the boost (structural — already gated on `hasColonialAcquisitionTargets` / `globalNewWorldHasNonGpOwnership` at phase entry), while EXPAND and DEVELOP structurally suppress it. When `phasePlan` is `null` the planner keeps the legacy `hasColonialAcquisitionTargets` + `shouldSuppressNewWorldColonialOrders` gate so prior tests stay green; the orchestrator always passes the dispatched plan. The resolver also surfaces the per-phase priority NW province list (`ColonialNavalPlan.priorityInvasionTransportProvinceIdsSorted` under COLONIAL; `ColonialLiteNavalPlan.priorityNwProvinceIdsSorted` under COLONIAL-lite) for future tighter naval ranking slices; today's planner consumes only the boolean.

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

Pure adapter functions extract per-domain orchestrator-ready values from a single `PhasePlanOutcome`. The orchestrator calls `runPhasePlanners` once per player turn and consumes the adapters' outputs repeatedly without re-checking the active phase. All adapters are pure and deterministic (Must-have #7).

| Adapter | Module | Output | EXPAND | COLONIAL-lite | COLONIAL | DEVELOP |
|---|---|---|---|---|---|---|
| `gpPeaceTargetsFromPhasePlan` | `phase_planner_peace_targets.dart` | `List<String>` GP `offerPeace` targets | `expandPeaceTargetFactionIdsSorted` | `expandPeaceTargetFactionIdsSorted` | `colonialPeaceTargetFactionIdsSorted` | `developPeaceTargetFactionIdsSorted` |
| `gpExpandDeclareWarTargetFromPhasePlan` | `phase_planner_declare_war_targets.dart` | `String?` OW declare-war target | `expandDeclareWarTargetFactionId` | `expandDeclareWarTargetFactionId` | `null` | `null` |
| `gpColonialDeclareWarTargetFromPhasePlan` | `phase_planner_declare_war_targets.dart` | `String?` NW declare-war target | `null` | `null` | `colonialAcquisitionTarget.targetFactionId` when method is `declareWar`, else `null` | `null` |
| `civilianWorkOrdersFromPhasePlan` | `phase_planner_civilian_work_orders.dart` | `List<WorkOrder>` civilian work to append to the economy pass | `const <WorkOrder>[]` | `const <WorkOrder>[]` | `colonialCivilianWorkOrders` | `developCivilianWorkOrders` |
| `expandEconomyPlanFromPhasePlan` | `phase_planner_expand_economy.dart` | `ExpandEconomyPlan` regiment-rebuild / cargo-boost directive for the economy build pass | `expandEconomyPlan` | `expandEconomyPlan` | `ExpandEconomyPlan.defaultPlan` | `ExpandEconomyPlan.defaultPlan` |
| `expandMilitaryPlanFromPhasePlan` | `phase_planner_military_plans.dart` | `ExpandMilitaryPlan` OW conquest destination filter | `expandMilitaryPlan` | `expandMilitaryPlan` | `ExpandMilitaryPlan.defaultPlan` | `ExpandMilitaryPlan.defaultPlan` |
| `colonialMilitaryPlanFromPhasePlan` | `phase_planner_military_plans.dart` | `ColonialMilitaryPlan` NW conquest destination filter | `ColonialMilitaryPlan.defaultPlan` | `ColonialMilitaryPlan.defaultPlan` | `colonialMilitaryPlan` | `ColonialMilitaryPlan.defaultPlan` |
| `colonialNavalPlanFromPhasePlan` | `phase_planner_naval_plans.dart` | `ColonialNavalPlan` NW invasion-transport directive | `ColonialNavalPlan.defaultPlan` | `ColonialNavalPlan.defaultPlan` | `colonialNavalPlan` | `ColonialNavalPlan.defaultPlan` |
| `colonialLiteNavalPlanFromPhasePlan` | `phase_planner_naval_plans.dart` | `ColonialLiteNavalPlan` tribe/minor NW naval focus directive | `ColonialLiteNavalPlan.defaultPlan` | `colonialLiteNavalPlan` | `ColonialLiteNavalPlan.defaultPlan` | `ColonialLiteNavalPlan.defaultPlan` |

EXPAND-side adapters pass their slot through under `expand` and `colonialLite` so the OW push continues during the safeguard; COLONIAL / DEVELOP route to default constants so OW directives cannot leak into NW-driven passes. The COLONIAL declare-war adapter returns `null` for `joinEmpire` / `purchase_land` / `null` acquisitions; DEVELOP never declares war. The two naval adapters are mutually exclusive: `colonialNavalPlanFromPhasePlan` populates only under COLONIAL (GP-inclusive invasion transport); `colonialLiteNavalPlanFromPhasePlan` only under COLONIAL-lite (tribe/minor-only exploration + cargo). Structural phase separation per issue #2509 § Phase transition guard.

## Acceptance criteria

- Given a `(Game, AIWorldSnapshot)` routing to `ObserverGoalPhase.expand`, when `runPhasePlanners` runs, then `phase == expand`, the four EXPAND slots equal the corresponding direct planner calls (`planExpandMilitary` paired with `planExpandDeclareWar`'s return), and all COLONIAL-lite / COLONIAL / DEVELOP slots equal their default-plan / empty values.
- Given a pair routing to `ObserverGoalPhase.colonialLite`, when `runPhasePlanners` runs, then the four EXPAND slots and the two COLONIAL-lite slots populate, while every full-COLONIAL and DEVELOP slot equals its default-plan / empty value.
- Given a pair routing to `ObserverGoalPhase.colonial` where `planColonialAcquisition` returns `ColonialAcquisitionTarget(targetFactionId: T, method: declareWar)`, when `runPhasePlanners` runs, then `colonialMilitaryPlan` and `colonialNavalPlan` field-equal direct calls with `colonialDeclaredWarTargetFactionId: T`, and EXPAND / COLONIAL-lite / DEVELOP slots equal their defaults.
- Given a pair routing to `ObserverGoalPhase.colonial` where `planColonialAcquisition` returns `null`, when `runPhasePlanners` runs, then `colonialMilitaryPlan` and `colonialNavalPlan` equal direct calls with `colonialDeclaredWarTargetFactionId: null` (at-war fallback).
- Given a pair routing to `ObserverGoalPhase.develop`, when `runPhasePlanners` runs, then only `developPeaceTargetFactionIdsSorted` and `developCivilianWorkOrders` populate; every other slot equals its default.
- Given identical `(Game, AIWorldSnapshot, personalityId)` inputs, when `runPhasePlanners` runs twice, then both invocations return field-equal `PhasePlanOutcome` instances (Must-have #7).
- Given a `PhasePlanOutcome` with `phase` in {`expand`, `colonialLite`}, when `gpExpandDeclareWarTargetFromPhasePlan(outcome)` runs, then the return equals `expandDeclareWarTargetFactionId`; with `phase` in {`colonial`, `develop`} the return equals `null` even when the EXPAND slot is non-null.
- Given a `PhasePlanOutcome` with `phase == colonial` and `colonialAcquisitionTarget.method == declareWar`, when `gpColonialDeclareWarTargetFromPhasePlan(outcome)` runs, then the return equals `colonialAcquisitionTarget.targetFactionId`; with `method` in {`joinEmpire`, `purchaseLand`} or `colonialAcquisitionTarget == null`, the return equals `null`.
- Given a `PhasePlanOutcome` whose `phase` is `expand`, `colonialLite`, or `develop`, when `gpColonialDeclareWarTargetFromPhasePlan(outcome)` runs, then the return equals `null` even when `colonialAcquisitionTarget` is non-null (structural phase suppression).
- Given a `PhasePlanOutcome` with `phase == colonial`, when `civilianWorkOrdersFromPhasePlan(outcome)` runs, then the return equals `outcome.colonialCivilianWorkOrders` (same order); with `phase == develop` the return equals `outcome.developCivilianWorkOrders`; with `phase` in {`expand`, `colonialLite`} the return equals `const <WorkOrder>[]` even when COLONIAL / DEVELOP slots are non-empty (structural NW-civilian-work suppression).
- Given a `PhasePlanOutcome` with `phase` in {`expand`, `colonialLite`}, when `expandEconomyPlanFromPhasePlan(outcome)` runs, then the return equals `outcome.expandEconomyPlan`; with `phase` in {`colonial`, `develop`} the return equals `ExpandEconomyPlan.defaultPlan` even when the EXPAND slot is non-default (structural phase separation — the EXPAND regiment-rebuild crisis arm must not leak into COLONIAL / DEVELOP).
- Given a `PhasePlanOutcome` with `phase` in {`expand`, `colonialLite`}, when `expandMilitaryPlanFromPhasePlan(outcome)` runs, then the return equals `outcome.expandMilitaryPlan`; with `phase` in {`colonial`, `develop`} the return equals `ExpandMilitaryPlan.defaultPlan` even when the EXPAND slot is non-default (structural separation — OW conquest filter must not leak into COLONIAL / DEVELOP military passes).
- Given a `PhasePlanOutcome` with `phase == colonial`, when `colonialMilitaryPlanFromPhasePlan(outcome)` runs, then the return equals `outcome.colonialMilitaryPlan`; with `phase` in {`expand`, `colonialLite`, `develop`} the return equals `ColonialMilitaryPlan.defaultPlan` even when the COLONIAL slot is non-default (COLONIAL-lite explicitly suppresses NW invasion army moves per § COLONIAL-lite scope summary).
- Given a `PhasePlanOutcome` with `phase == colonial`, when `colonialNavalPlanFromPhasePlan(outcome)` runs, then the return equals `outcome.colonialNavalPlan`; with `phase` in {`expand`, `colonialLite`, `develop`} the return equals `ColonialNavalPlan.defaultPlan` even when the COLONIAL slot is non-default (COLONIAL-lite explicitly suppresses NW invasion transport per § COLONIAL-lite "Never suggest invasion transport or NW army staging here").
- Given a `PhasePlanOutcome` with `phase == colonialLite`, when `colonialLiteNavalPlanFromPhasePlan(outcome)` runs, then the return equals `outcome.colonialLiteNavalPlan`; with `phase` in {`expand`, `colonial`, `develop`} the return equals `ColonialLiteNavalPlan.defaultPlan` even when the COLONIAL-lite slot is non-default (full-COLONIAL drives invasion transport through `colonialNavalPlan`, not the tribe / minor-only COLONIAL-lite filter).

## Interactions

- [phase-planner-architecture.md](phase-planner-architecture.md) — phase definitions, planner-module contracts, orchestrator dispatch table.
- [ai-architecture.md](ai-architecture.md) — phase suppression rules, COLONIAL-lite safeguard.
- [ai-personalities.md](ai-personalities.md) — `personalityId` argument semantics for `planColonialAcquisition`.
