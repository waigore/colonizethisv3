// Pins `isStalledOldWorldGpBlockerFocus` in `expand_phase_planner.dart` (Refs #2509 S1).
// Case bodies: `expand_phase_planner_stalled_ow_gp_blocker_focus_*_cases.dart`.

import 'expand_phase_planner_stalled_ow_gp_blocker_focus_false_cases.dart';
import 'expand_phase_planner_stalled_ow_gp_blocker_focus_true_cases.dart';

void main() {
  registerExpandPhasePlannerStalledOwGpBlockerFocusFalseCases();
  registerExpandPhasePlannerStalledOwGpBlockerFocusTrueCases();
}
