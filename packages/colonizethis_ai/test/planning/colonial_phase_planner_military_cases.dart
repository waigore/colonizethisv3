// Case-library barrel (Refs #3997 Phase 8).
// Thin aggregator so existing contracts keep a stable import;
// topic modules stay ≤650 physical lines.

import 'colonial_phase_planner_military_priority_cases.dart';
import 'colonial_phase_planner_military_suppression_core_cases.dart';
import 'colonial_phase_planner_military_suppression_path_e_waiver_cases.dart';

void registerColonialPhasePlannerMilitaryCases() {
  registerColonialPhasePlannerMilitaryPriorityCases();
  registerColonialPhasePlannerMilitarySuppressionCoreCases();
  registerColonialPhasePlannerMilitarySuppressionPathEWaiverCases();
}
