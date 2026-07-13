// Case-library barrel (Refs #3997 Phase 8).
// Thin aggregator so existing contracts keep a stable import;
// topic modules stay ≤650 physical lines.

import 'expand_phase_planner_below_quota_multi_minor_distraction_guards_cases.dart';
import 'expand_phase_planner_below_quota_multi_minor_distraction_fire_cases.dart';

void registerExpandPhasePlannerBelowQuotaMultiMinorDistractionPeaceCases() {
  registerExpandPhasePlannerBelowQuotaMultiMinorDistractionGuardsCases();
  registerExpandPhasePlannerBelowQuotaMultiMinorDistractionFireCases();
}
