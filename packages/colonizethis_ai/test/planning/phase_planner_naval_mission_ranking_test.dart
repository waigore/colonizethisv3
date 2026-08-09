// Thin contract for phase_planner_naval_mission_ranking pin suite (Refs #4079 Slice D).
// Unit + integration tests for the tighter colonial naval mission ranking
// slice (Refs #2509 S5). Case bodies live in sibling `*_cases.dart` modules.
//
// Pinned contracts (mapped to issue #2509 ACs):
//   1. New port tier: phase-priority NW port mission returns
//      `kColonialNavalMissionPhasePriorityNwPortScore` (200), strictly
//      higher than `kColonialNavalMissionNwPortScore` (160).
//   2. New province tier: phase-priority NW province mission returns
//      `kColonialNavalMissionPhasePriorityNwProvinceScore` (170), strictly
//      higher than `kColonialNavalMissionNwProvinceScore` (130).
//   3. Non-priority NW port / NW province missions still return the legacy
//      tier when the phase priority list does not cover them.
//   4. `null` / empty `phasePriorityNwProvinceIdsSorted` preserves legacy
//      three-tier scoring exactly.
//   5. `sortNavalMissionsForColonialPressure` orders by the new tier first.
//   6. Phase-priority list does not promote OW ports, OW provinces, or
//      beachhead/empty missions.
//   7. Determinism (Must-have #7): identical inputs always yield identical
//      score and ordering across repeated calls.
//   8. Integration: `runNavalPlanner` emits the mission targeting the
//      phase-priority NW port; mutual exclusion preserved.

import 'phase_planner_naval_mission_ranking_integration_cases.dart';
import 'phase_planner_naval_mission_ranking_scoring_cases.dart';

void main() {
  registerPhasePlannerNavalMissionRankingScoringCases();
  registerPhasePlannerNavalMissionRankingIntegrationCases();
}
