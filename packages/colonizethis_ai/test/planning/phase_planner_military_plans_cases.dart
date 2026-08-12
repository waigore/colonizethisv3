// Case-library barrel for phase planner military-plans pin (Refs #4310 Slice D).

import 'phase_planner_military_plans_colonial_cases.dart';
import 'phase_planner_military_plans_default_cases.dart';
import 'phase_planner_military_plans_expand_cases.dart';

void registerPhasePlannerMilitaryPlansCases() {
  registerPhasePlannerMilitaryPlansExpandCases();
  registerPhasePlannerMilitaryPlansColonialCases();
  registerPhasePlannerMilitaryPlansDefaultAndDeterminismCases();
}
