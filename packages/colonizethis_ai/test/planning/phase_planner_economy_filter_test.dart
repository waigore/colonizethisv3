// Thin contract for phase_planner_economy_filter pin suite (Refs #3997 Phase 8).
// Case bodies live in sibling `*_cases.dart` modules.

import 'phase_planner_economy_filter_build_order_blocker_cases.dart';
import 'phase_planner_economy_filter_colonial_develop_cases.dart';

void main() {
  registerPhasePlannerEconomyFilterColonialDevelopCases();
  registerPhasePlannerEconomyFilterBuildOrderBlockerCases();
}
