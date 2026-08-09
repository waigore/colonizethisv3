// Thin contract for develop-phase planner pin suite (Refs #3997 Phase 8).
// Case bodies live in sibling `*_cases.dart` modules.
//
// Spec contract (issue #2509 § DEVELOP phase planner) is preserved in the
// case modules; this file only registers them.

import 'develop_phase_planner_civilian_pairing_cases.dart';
import 'develop_phase_planner_civilian_tile_cases.dart';
import 'develop_phase_planner_peace_cases.dart';

void main() {
  registerDevelopPhasePlannerPeaceCases();
  registerDevelopPhasePlannerCivilianTileCases();
  registerDevelopPhasePlannerCivilianPairingCases();
}
