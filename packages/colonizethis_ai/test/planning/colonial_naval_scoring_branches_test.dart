// Thin contract for colonial naval scoring branch pin suite (Refs #4079 Slice C).
// SPEC: see SPEC/ai/ai-architecture.md § Colonial pressure naval scoring
// and `packages/colonizethis_ai/lib/src/planning/colonial_naval_scoring.dart`.
//
// Pinned contracts (mapped to issue #2509 / colonial-support naval prioritization):
//   1. `colonialNavalMoveScore` dock branches: NW port dock vs OW port dock.
//   2. `colonialNavalMoveScore` non-dock null/empty seaId returns 0.
//   3. `colonialNavalMoveScore` non-dock NW sea priority vs fallback tiers.
//   4. `colonialNavalMoveScore` non-dock OW gateway vs interior seas.
//   5. `colonialNavalMissionScore` NW port / province / beachhead fallthrough.
//   6. `newWorldSeaZonesAdjacentToInvadableProvinces` filters and dedupes.
//   7. `sortNavalMovesForColonialPressure` stable ordering.
//   8. `sortNavalMissionsForColonialPressure` stable ordering.
//
// Case bodies live in sibling `*_cases.dart` modules.

import 'colonial_naval_scoring_branches_scoring_cases.dart';
import 'colonial_naval_scoring_branches_sort_cases.dart';

void main() {
  registerColonialNavalScoringBranchesScoringCases();
  registerColonialNavalScoringBranchesSortCases();
}
