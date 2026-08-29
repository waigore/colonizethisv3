// Case barrel for `planColonialMilitary` priority-arm pins (Refs #2509 S3).

import 'colonial_phase_planner_military_priority_declared_target_cases.dart';
import 'colonial_phase_planner_military_priority_guard_cases.dart';

void registerColonialPhasePlannerMilitaryPriorityCases() {
  registerColonialPhasePlannerMilitaryPriorityGuardCases();
  registerColonialPhasePlannerMilitaryPriorityDeclaredTargetCases();
}
