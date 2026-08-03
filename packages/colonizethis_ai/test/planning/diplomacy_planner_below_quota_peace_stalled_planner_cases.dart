// Barrel for below-quota stalled planner case modules (Refs #4239 Slice C).

import 'diplomacy_planner_below_quota_peace_stalled_planner_declare_cases.dart';
import 'diplomacy_planner_below_quota_peace_stalled_planner_scoring_cases.dart';

void registerDiplomacyBelowQuotaPeaceStalledPlannerCases() {
  registerDiplomacyBelowQuotaPeaceStalledPlannerDeclareCases();
  registerDiplomacyBelowQuotaPeaceStalledPlannerScoringCases();
}
