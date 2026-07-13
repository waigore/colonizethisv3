// Thin contract for colonial acquisition purchase_land pin suite
// (Refs #3997 Phase 8). Case bodies live in sibling `*_cases.dart` modules.

import 'colonial_phase_planner_acquisition_purchase_land_guard_cases.dart';
import 'colonial_phase_planner_acquisition_purchase_land_happy_path_cases.dart';

void main() {
  registerColonialAcquisitionPurchaseLandGuardCases();
  registerColonialAcquisitionPurchaseLandHappyPathCases();
}
