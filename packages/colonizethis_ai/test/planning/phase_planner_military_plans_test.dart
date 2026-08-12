// Unit tests for `phase_planner_military_plans.dart`
// (Refs #2509 S5 orchestrator adapter slice).
//
// Adapter contracts pinned here (from `SPEC/ai/phase-planner-dispatch.md`
// § Adapter helpers — updated by this slice to add the EXPAND and
// COLONIAL military-plan rows):
//
//   expandMilitaryPlanFromPhasePlan(outcome):
//     - EXPAND          -> outcome.expandMilitaryPlan
//     - COLONIAL-lite   -> outcome.expandMilitaryPlan
//     - COLONIAL        -> ExpandMilitaryPlan.defaultPlan
//     - DEVELOP         -> ExpandMilitaryPlan.defaultPlan
//
//   colonialMilitaryPlanFromPhasePlan(outcome):
//     - EXPAND          -> ColonialMilitaryPlan.defaultPlan
//     - COLONIAL-lite   -> ColonialMilitaryPlan.defaultPlan
//     - COLONIAL        -> outcome.colonialMilitaryPlan
//     - DEVELOP         -> ColonialMilitaryPlan.defaultPlan
//
// Fixtures here construct `PhasePlanOutcome` instances directly so the
// tests do not require a `Game` / `AIWorldSnapshot` pair. Outcome
// composition from real `runPhasePlanners` dispatches is already
// covered by `phase_planner_dispatch_test.dart`.
//
// Thin contract for military-plan adapter pin suite (Refs #4310 Slice D).
// Case bodies live in sibling `*_cases.dart` modules.

import 'phase_planner_military_plans_cases.dart';

void main() {
  registerPhasePlannerMilitaryPlansCases();
}
