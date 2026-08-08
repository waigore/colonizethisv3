// Thin contract for phase_planner_naval_wiring pin suite (Refs #4291 Slice D).
// Case bodies live in sibling `*_cases.dart` modules.

import 'phase_planner_naval_wiring_directive_cases.dart';
import 'phase_planner_naval_wiring_planner_cases.dart';

void main() {
  registerPhasePlannerNavalWiringDirectiveCases();
  registerPhasePlannerNavalWiringPlannerCases();
}
