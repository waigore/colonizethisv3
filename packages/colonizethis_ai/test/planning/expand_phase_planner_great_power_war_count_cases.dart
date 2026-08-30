// Topic-split registrar for `greatPowerWarCountOnTarget` pins (Refs #4669 Slice B).

import 'expand_phase_planner_great_power_war_count_merge_cases.dart';
import 'expand_phase_planner_great_power_war_count_relation_cases.dart';

void registerExpandPhasePlannerGreatPowerWarCountCases() {
  registerExpandPhasePlannerGreatPowerWarCountRelationCases();
  registerExpandPhasePlannerGreatPowerWarCountMergeCases();
}
