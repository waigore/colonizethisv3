// Unit tests for `planExpandMilitary` in
// `packages/colonizethis_ai/lib/src/planning/expand_phase_planner.dart`
// (Refs #2509 S2 / S10).
//
// Spec contract (issue #2509 § EXPAND phase planner § planExpandMilitary):
//
//   "Conquest army moves toward OW invadable provinces only.
//      → Source: invadableProvinceIdsSorted, filtered to provinces owned
//        by the declare-war target (or any at-war owner if no target).
//      → Use existing runConquestArmyMovePlanner with EXPAND-only
//        destination filter.
//      → No NW army moves (structural — planner never queries colonial
//        summary)."
//
// Mirrors the test pattern established for the other EXPAND-phase
// planner contracts (`expand_phase_planner_test.dart`,
// `expand_phase_planner_declare_war_test.dart`,
// `expand_phase_planner_economy_test.dart`): small synthetic fixtures,
// one branch arm per test, in-module pin (the planner module never
// re-checks phase, so these tests stay scoped to the priority-arm
// branches plus the structural NW suppression).
//
// The "runConquestArmyMovePlanner" wiring + actual ArmyMoveOrder
// emission live at the orchestrator layer (#2509 S5) and are
// intentionally out of scope for this in-module pin — the unit pins
// the deterministic destination filter that the orchestrator consumes.

import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'test_game_factories.dart';

import 'expand_phase_planner_military_priority_cases.dart';
import 'expand_phase_planner_military_suppression_cases.dart';

void main() {
  registerExpandPhasePlannerMilitaryPriorityCases();
  registerExpandPhasePlannerMilitarySuppressionCases();
}
