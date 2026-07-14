// Thin contract for COLONIAL phase planner pin suite (Refs #3977 Phase 6).
// Case bodies live in `colonial_phase_planner_naval_cases.dart`; this file only registers them so
// the `*_test.dart` surface stays under review pressure.

import 'colonial_phase_planner_naval_cases.dart';

void main() {
  registerColonialPhasePlannerNavalCases();
}
