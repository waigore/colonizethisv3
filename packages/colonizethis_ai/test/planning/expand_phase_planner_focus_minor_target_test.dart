// Thin contract for expand_phase_planner_focus_minor_target pin suite
// (Refs #3997 Phase 8). Case bodies live in sibling `*_cases.dart` modules.

import 'expand_phase_planner_focus_minor_target_early_cases.dart';
import 'expand_phase_planner_focus_minor_target_later_cases.dart';

void main() {
  registerExpandPhasePlannerFocusMinorTargetEarlyCases();
  registerExpandPhasePlannerFocusMinorTargetLaterCases();
}
