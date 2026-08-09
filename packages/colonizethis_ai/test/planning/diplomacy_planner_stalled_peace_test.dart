// Thin contract for diplomacy planner stalled-peace pin suite (Refs #4104 Slice C).
// Case bodies live in sibling `*_cases.dart` modules.

import 'diplomacy_planner_stalled_peace_distraction_blocker_cases.dart';
import 'diplomacy_planner_stalled_peace_quota_sole_gp_cases.dart';

void main() {
  registerDiplomacyPlannerStalledPeaceDistractionBlockerCases();
  registerDiplomacyPlannerStalledPeaceQuotaSoleGpCases();
}
