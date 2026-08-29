// Thin contract for diplomacy_planner_mutual_exhausted_peace pin suite (Refs #4291 Slice D).
// Case bodies live in sibling `*_cases.dart` modules.

import 'diplomacy_planner_mutual_exhausted_peace_targets_cases.dart';
import 'diplomacy_planner_mutual_exhausted_peace_targets_tail_cases.dart';
import 'diplomacy_planner_mutual_exhausted_peace_wiring_cases.dart';

void main() {
  registerMutualExhaustedPeaceTargetsCases();
  registerMutualExhaustedPeaceTargetsTailCases();
  registerMutualExhaustedPeaceWiringCases();
}
