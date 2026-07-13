// Case-library barrel (Refs #3997 Phase 8).
// Thin aggregator so existing contracts keep a stable import;
// topic modules stay ≤650 physical lines.

import 'expand_phase_planner_peer_peace_start_hold_cases.dart';
import 'expand_phase_planner_peer_peace_war_focus_cases.dart';

void registerExpandPhasePlannerPeerPeaceBasicCases() {
  registerExpandPhasePlannerPeerPeaceStartHoldCases();
  registerExpandPhasePlannerPeerPeaceWarFocusCases();
}
