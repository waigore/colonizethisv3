// Thin contract for phase_planner_conquest_frontier_march pin suite (Refs #4079 Slice D).
// Unit tests for `runConquestArmyMovePlanner` stalled-expansion own-territory
// frontier-march behaviour (Refs #2509 EXPAND) and geographic peer-lock minor
// transit (Refs #2847 H4-b). Case bodies live in sibling `*_cases.dart` modules.

import 'phase_planner_conquest_frontier_march_peer_lock_cases.dart';
import 'phase_planner_conquest_frontier_march_stalled_cases.dart';

void main() {
  registerPhasePlannerConquestFrontierMarchStalledCases();
  registerPhasePlannerConquestFrontierMarchPeerLockCases();
}
