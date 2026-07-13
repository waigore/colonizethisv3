// Case-library barrel (Refs #3997 Phase 8).
// Thin aggregator so existing contracts keep a stable import;
// topic modules stay ≤650 physical lines.

import 'expand_phase_peace_matrix_target_decider_hold_quota_cases.dart';
import 'expand_phase_peace_matrix_target_decider_start_futile_cases.dart';

void registerExpandPeaceTargetDeciderCases() {
  registerExpandPeaceTargetDeciderHoldQuotaCases();
  registerExpandPeaceTargetDeciderStartFutileCases();
}
