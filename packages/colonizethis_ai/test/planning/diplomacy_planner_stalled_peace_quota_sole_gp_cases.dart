// Case bodies for `diplomacy_planner_stalled_peace_test.dart` (Refs #4104 Slice C).
// Registered from the thin contract; pin coverage preserved 1:1 from the
// former inline suite.

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'diplomacy_planner_stalled_peace_quota_sole_gp_branch_cases.dart';
import 'diplomacy_planner_stalled_peace_quota_sole_gp_tail_cases.dart';

void registerDiplomacyPlannerStalledPeaceQuotaSoleGpCases() {
  registerDiplomacyPlannerStalledPeaceQuotaSoleGpPartACases();
  registerDiplomacyPlannerStalledPeaceQuotaSoleGpPartBCases();
}
