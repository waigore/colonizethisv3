// Thin contract for planning_peace_collectors pin suite (Refs #4291 Slice D).
// Case bodies live in sibling `*_cases.dart` modules.

import 'planning_peace_collectors_gp_cases.dart';
import 'planning_peace_collectors_non_gp_cases.dart';

void main() {
  registerPlanningPeaceCollectorsGpCases();
  registerPlanningPeaceCollectorsNonGpCases();
}
