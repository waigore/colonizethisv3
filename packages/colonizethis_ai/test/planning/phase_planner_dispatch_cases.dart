// Case-library barrel for phase planner dispatch pin (Refs #4310 Slice D).

import 'phase_planner_dispatch_colonial_cases.dart';
import 'phase_planner_dispatch_colonial_lite_cases.dart';
import 'phase_planner_dispatch_develop_cases.dart';
import 'phase_planner_dispatch_expand_cases.dart';
import 'phase_planner_dispatch_routing_cases.dart';

void registerPhasePlannerDispatchCases() {
  registerPhasePlannerDispatchRoutingCases();
  registerPhasePlannerDispatchExpandCases();
  registerPhasePlannerDispatchColonialLiteCases();
  registerPhasePlannerDispatchColonialCases();
  registerPhasePlannerDispatchDevelopCases();
  registerPhasePlannerDispatchDeterminismCases();
  registerPhasePlannerDispatchPriorityWeightsCases();
}
