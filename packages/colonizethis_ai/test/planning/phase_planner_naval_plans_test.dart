// Thin contract for phase_planner_naval_plans pin suite (Refs #4291 Slice D).
// Case bodies live in sibling `*_cases.dart` modules.

import 'phase_planner_naval_plans_routing_cases.dart';
import 'phase_planner_naval_plans_adapter_cases.dart';

void main() {
  registerPhasePlannerNavalPlansRoutingCases();
  registerPhasePlannerNavalPlansAdapterCases();
}
