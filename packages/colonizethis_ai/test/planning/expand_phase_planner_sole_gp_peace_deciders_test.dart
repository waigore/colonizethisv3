// Thin contract for expand_phase_planner_sole_gp_peace_deciders pin suite (Refs #4291 Slice D).
// Case bodies live in sibling `*_cases.dart` modules.

import 'expand_phase_planner_sole_gp_peace_deciders_unwinnable_cases.dart';
import 'expand_phase_planner_sole_gp_peace_deciders_consolidate_cases.dart';

void main() {
  registerExpandSoleGpPeaceDecidersUnwinnableCases();
  registerExpandSoleGpPeaceDecidersConsolidateCases();
}
