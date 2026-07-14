// Thin contract for phase_planner_priority_weight_resolvers pin suite
// (Refs #3997 Phase 8). Case bodies live in sibling `*_cases.dart` modules.

import 'phase_planner_priority_weight_resolvers_conquest_naval_cases.dart';
import 'phase_planner_priority_weight_resolvers_goal_economy_diplomacy_cases.dart';

void main() {
  registerPhasePlannerPriorityWeightResolversConquestNavalCases();
  registerPhasePlannerPriorityWeightResolversGoalEconomyDiplomacyCases();
}
