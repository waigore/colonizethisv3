// Thin contract for colonial_phase_planner_civilian pin suite (Refs #4291 Slice D).
// Case bodies live in sibling `*_cases.dart` modules.

import 'colonial_phase_planner_civilian_core_cases.dart';
import 'colonial_phase_planner_civilian_edge_cases.dart';

void main() {
  registerColonialPhasePlannerCivilianCoreCases();
  registerColonialPhasePlannerCivilianEdgeCases();
}
