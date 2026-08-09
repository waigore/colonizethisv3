// Case-library barrel (Refs #4079 Slice D / #4104 Slice C).
// Thin aggregator; topic modules stay under 600 physical lines.

import 'expand_phase_planner_economy_core_cases.dart';
import 'expand_phase_planner_economy_peer_war_lock_cases.dart';

void registerExpandPhasePlannerEconomyCases() {
  registerExpandPhasePlannerEconomyCoreCases();
  registerExpandPhasePlannerEconomyPeerWarLockCases();
}
