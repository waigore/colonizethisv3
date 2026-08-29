// Thin contract for phase_planner_conquest_wiring pin suite (Refs #3997 Phase 8).
// Case bodies live in sibling `*_cases.dart` modules.

import 'phase_planner_conquest_wiring_army_move_cases.dart';
import 'phase_planner_conquest_wiring_invadable_cases.dart';
import 'phase_planner_conquest_wiring_invadable_default_plan_cases.dart';
import 'phase_planner_conquest_wiring_pressure_extra_cases.dart';
import 'phase_planner_conquest_wiring_pressure_partition_cases.dart';

void main() {
  registerPhasePlannerConquestWiringInvadableCases();
  registerPhasePlannerConquestWiringInvadableDefaultPlanCases();
  registerPhasePlannerConquestWiringPressureExtraCases();
  registerPhasePlannerConquestWiringPressurePartitionCases();
  registerPhasePlannerConquestWiringArmyMoveCases();
}
