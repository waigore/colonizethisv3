// Thin contract for phase_planner_naval_ranking pin suite (Refs #4079 Slice D).
// Unit + integration tests for the tighter colonial naval ranking slice
// (Refs #2509 S5). Case bodies live in sibling `*_cases.dart` modules.
//
// Pinned contracts (mapped to issue #2509 ACs):
//   1. New score tier: phase-priority sea zone returns
//      `kColonialNavalMovePhasePriorityNwSeaZoneScore` (240), strictly
//      higher than `kColonialNavalMovePriorityNwSeaZoneScore` (200).
//   2. Non-priority invadable sea zone still returns the general 200 tier.
//   3. `null` / empty `phasePriorityNwProvinceIdsSorted` preserves legacy
//      two-tier scoring exactly.
//   4. `sortNavalMovesForColonialPressure` orders by the new tier first.
//   5. Phase priority subset members not present in
//      `colonial.invadableNewWorldProvinceIdsSorted` still surface the new tier.
//   6. Determinism (Must-have #7): identical inputs always yield identical
//      score and ordering across repeated calls.
//   7. Integration: `runNavalPlanner` ranks the phase-priority sea zone above
//      an unrelated invadable-NW sea zone; COLONIAL mutual exclusion preserved.

import 'phase_planner_naval_ranking_integration_cases.dart';
import 'phase_planner_naval_ranking_scoring_cases.dart';

void main() {
  registerPhasePlannerNavalRankingScoringCases();
  registerPhasePlannerNavalRankingIntegrationCases();
}
