// Case-library barrel for below-quota peer GP peace pin (Refs #4310 Slice D).

import 'expand_phase_planner_below_quota_peer_gp_peace_gap_cases.dart';
import 'expand_phase_planner_below_quota_peer_gp_peace_guard_cases.dart';
import 'expand_phase_planner_below_quota_peer_gp_peace_tail_cases.dart';

void registerExpandPhasePlannerBelowQuotaPeerGpPeaceCases() {
  registerExpandPhasePlannerBelowQuotaPeerGpPeaceGuardCases();
  registerExpandPhasePlannerBelowQuotaPeerGpPeaceGapCases();
  registerExpandPhasePlannerBelowQuotaPeerGpPeaceTailCases();
}
