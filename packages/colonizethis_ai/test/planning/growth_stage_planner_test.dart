// Thin contract for growth-stage planner pin suite (Refs #4104 Slice C).
// Case bodies live in sibling `*_cases.dart` modules.
// Builder relocation / anti-thrash ACs live in
// growth_stage_planner_relocation_test.dart.

import 'growth_stage_planner_core_cases.dart';
import 'growth_stage_planner_routing_cases.dart';

void main() {
  registerGrowthStagePlannerCoreCases();
  registerGrowthStagePlannerRoutingCases();
}
