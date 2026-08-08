// Thin contract for colonial_phase_planner_colonial_lite_overtures pin suite (Refs #4291 Slice D).
// Case bodies live in sibling `*_cases.dart` modules.

import 'colonial_phase_planner_colonial_lite_overtures_filter_cases.dart';
import 'colonial_phase_planner_colonial_lite_overtures_sort_cases.dart';

void main() {
  registerColonialLiteOverturesFilterCases();
  registerColonialLiteOverturesSortCases();
}
