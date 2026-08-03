// Thin contract for expand_phase_planner_gp_blocker_focus_peace pin suite (Refs #4239 Slice C).
// Case bodies live in sibling `*_cases.dart` modules.

import 'expand_phase_planner_gp_blocker_focus_peace_determinism_cases.dart';
import 'expand_phase_planner_gp_blocker_focus_peace_guards_cases.dart';
import 'expand_phase_planner_gp_blocker_focus_peace_target_cases.dart';

void main() {
  registerExpandGpBlockerFocusPeaceGuardsCases();
  registerExpandGpBlockerFocusPeaceTargetCases();
  registerExpandGpBlockerFocusPeaceDeterminismCases();
}
