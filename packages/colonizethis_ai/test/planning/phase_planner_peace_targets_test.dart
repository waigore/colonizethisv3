// Thin contract for phase_planner_peace_targets pin suite (Refs #4291 Slice D).
// Case bodies live in sibling `*_cases.dart` modules.

import 'phase_planner_peace_targets_gp_distraction_cases.dart';
import 'phase_planner_peace_targets_production_cases.dart';

void main() {
  registerPhasePlannerPeaceTargetsGpDistractionCases();
  registerPhasePlannerPeaceTargetsProductionCases();
}
