// Unit tests for `planExpandDeclareWar` in
// `packages/colonizethis_ai/lib/src/planning/expand_phase_planner.dart`
// (Refs #2509 S2 / S10).
//
// Spec contract (issue #2509 § EXPAND phase planner § planExpandDeclareWar):
//
//   "Priority-ordered scan of `invadableProvinceIdsSorted` (OW only).
//    Pick the first valid candidate:
//      1. Adjacent minor with uninvaded OW province
//         → Tiebreaker: lowest factionId.
//         → Skip if already at war with all candidates,
//           treasury < cheapestRegimentBuildTreasuryCost,
//           or suggestDeclareWarOrders rejects.
//      2. Already-at-war minor with uninvaded OW province
//      3. Sole GP frontier blocker (GP-only frontiers only):
//         declare on that GP only if mutual-plateau, our regiments
//         ≥ partner's, treasury ≥ regiment build cost.
//      4. null — skip declaring."
//
// Mirrors the test pattern established for `planExpandPeace` in the same
// package (`expand_phase_planner_test.dart`): small synthetic fixtures,
// one branch arm per test, in-module pin (the planner module never
// re-checks phase, so these tests stay scoped to the priority scan
// branches and the deterministic-tiebreak / treasury / regiment gates).
//
// The "suggestDeclareWarOrders rejects" gate noted in the spec is
// enforced at the orchestrator layer (#2509 S5) and is intentionally
// out of scope for this in-module pin.

import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'ai_planner_fixtures.dart';
import 'test_game_factories.dart';

import 'expand_phase_planner_declare_war_priority_cases.dart';
import 'expand_phase_planner_declare_war_sole_gp_cases.dart';

void main() {
  registerExpandPhasePlannerDeclareWarPriorityCases();
  registerExpandPhasePlannerDeclareWarSoleGpCases();
}
