// Thin contract for expand_phase_planner peace pin suite (Refs #4239 Slice C).
// Case bodies live in sibling `*_cases.dart` modules.

import 'expand_phase_planner_peace_core_cases.dart';
import 'expand_phase_planner_peace_geographic_peer_war_lock_cases.dart';

void main() {
  registerExpandPhasePlannerPeaceCoreCases();
  registerExpandPhasePlannerPeaceGeographicPeerWarLockCases();
}
