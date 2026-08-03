// Barrel for survival-stubs multi-front peace case modules (Refs #4239 Slice C).

import 'expand_phase_planner_survival_stubs_delegating_peace_cases.dart';
import 'expand_phase_planner_survival_stubs_multi_front_canonical_peace_cases.dart';

void registerExpandPhasePlannerSurvivalStubsMultiFrontPeaceCases() {
  registerExpandSurvivalStubsDelegatingPeaceCases();
  registerExpandSurvivalStubsMultiFrontPeaceCases();
}
