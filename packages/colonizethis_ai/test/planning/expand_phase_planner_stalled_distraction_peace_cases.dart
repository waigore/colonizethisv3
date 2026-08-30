// Case-library barrel for stalled distraction peace pin (Refs #4310 Slice D).

import 'expand_phase_planner_stalled_distraction_peace_arm_cases.dart';
import 'expand_phase_planner_stalled_distraction_peace_guard_cases.dart';
import 'expand_phase_planner_stalled_distraction_peace_tail_cases.dart';

void registerExpandPhasePlannerStalledDistractionPeaceCases() {
  registerExpandPhasePlannerStalledDistractionPeaceGuardCases();
  registerExpandPhasePlannerStalledDistractionPeaceArmCases();
  registerExpandPhasePlannerStalledDistractionPeaceTailCases();
}
