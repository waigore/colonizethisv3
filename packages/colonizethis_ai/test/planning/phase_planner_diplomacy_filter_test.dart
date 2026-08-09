// Thin contract for phase_planner_diplomacy_filter pin suite (Refs #4239 Slice C).
// Case bodies live in sibling `*_cases.dart` modules.

import 'phase_planner_diplomacy_filter_colonial_pressure_cases.dart';
import 'phase_planner_diplomacy_filter_partition_cases.dart';
import 'phase_planner_diplomacy_filter_phase_suppression_cases.dart';

void main() {
  registerPhasePlannerDiplomacyFilterColonialPressureCases();
  registerPhasePlannerDiplomacyFilterPhaseSuppressionCases();
  registerPhasePlannerDiplomacyFilterPartitionCases();
}
