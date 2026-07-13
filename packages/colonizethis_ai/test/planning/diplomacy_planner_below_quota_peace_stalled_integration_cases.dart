// Case-library barrel (Refs #3997 Phase 8).
// Thin aggregator so existing contracts keep a stable import;
// topic modules stay ≤650 physical lines.

import 'diplomacy_planner_below_quota_peace_stalled_targets_cases.dart';
import 'diplomacy_planner_below_quota_peace_stalled_planner_cases.dart';

void registerDiplomacyBelowQuotaPeaceStalledIntegrationCases() {
  registerDiplomacyBelowQuotaPeaceStalledTargetsCases();
  registerDiplomacyBelowQuotaPeaceStalledPlannerCases();
}
