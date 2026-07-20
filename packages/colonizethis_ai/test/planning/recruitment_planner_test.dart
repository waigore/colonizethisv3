// Thin contract for runRecruitmentPlanner(RecruitmentPlannerInput(Refs #2692 S8)) pin
// suite (Refs #4104 Slice C). SPEC/ai/economy-planner.md § Recruitment planner.
// Case bodies live in sibling `*_cases.dart` modules.

import 'recruitment_planner_emit_edge_cases.dart';
import 'recruitment_planner_peasant_luxury_cases.dart';

void main() {
  registerRecruitmentPlannerPeasantLuxuryCases();
  registerRecruitmentPlannerEmitEdgeCases();
}
