// Thin contract for growth-stage Builder relocation pin (Refs #3371, #4310).
// Case bodies live in sibling `*_cases.dart` modules.

import 'growth_stage_planner_relocation_anti_thrash_cases.dart';
import 'growth_stage_planner_relocation_feedstock_cases.dart';

void main() {
  registerGrowthStagePlannerRelocationFeedstockCases();
  registerGrowthStagePlannerRelocationAntiThrashCases();
}
