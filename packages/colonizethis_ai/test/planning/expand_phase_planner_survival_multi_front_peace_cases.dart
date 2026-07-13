// Case-library barrel (Refs #3997 Phase 8).
// Thin aggregator so existing contracts keep a stable import;
// topic modules stay ≤650 physical lines.

import 'expand_phase_planner_survival_zero_regiment_peace_cases.dart';
import 'expand_phase_planner_survival_stubs_multi_front_peace_cases.dart';

void registerExpandPhasePlannerSurvivalMultiFrontPeaceCases() {
  registerExpandPhasePlannerSurvivalZeroRegimentPeaceCases();
  registerExpandPhasePlannerSurvivalStubsMultiFrontPeaceCases();
}
