// Case-library barrel (Refs #3997 Phase 8).
// Thin aggregator so existing contracts keep a stable import;
// topic modules stay ≤650 physical lines.

import 'expand_phase_peace_matrix_sole_gp_identity_cases.dart';
import 'expand_phase_peace_matrix_sole_gp_blocker_cases.dart';

void registerExpandPeaceSoleGpCases() {
  registerExpandPeaceSoleGpIdentityCases();
  registerExpandPeaceSoleGpBlockerCases();
}
