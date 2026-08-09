// Case-library barrel (Refs #3997 Phase 8 / #4291 Slice D).
// Thin aggregator so existing contracts keep a stable import.

import 'expand_phase_peace_matrix_target_decider_futile_cases.dart';
import 'expand_phase_peace_matrix_target_decider_hold_quota_cases.dart';
import 'expand_phase_peace_matrix_target_decider_start_cases.dart';

void registerExpandPeaceTargetDeciderCases() {
  registerExpandPeaceTargetDeciderHoldQuotaCases();
  registerExpandPeaceTargetDeciderStartCases();
  registerExpandPeaceTargetDeciderFutileCases();
}
