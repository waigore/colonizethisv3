// Thin contract for colonial_phase_planner pin suite (Refs #4291 Slice D).
// Case bodies live in sibling `*_cases.dart` modules.

import 'colonial_phase_planner_peace_core_cases.dart';
import 'colonial_phase_planner_peace_edge_cases.dart';

void main() {
  registerColonialPhasePlannerPeaceCoreCases();
  registerColonialPhasePlannerPeaceEdgeCases();
}
