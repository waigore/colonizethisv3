// Case-library barrel (Refs #4669 Slice B).

import 'expand_phase_planner_focus_minor_target_early_cases_guards.dart';
import 'expand_phase_planner_focus_minor_target_early_cases_fire.dart';
import 'expand_phase_planner_focus_minor_target_early_cases_below_quota_guard.dart';

void registerExpandPhasePlannerFocusMinorTargetEarlyCases() {
  registerExpandPhasePlannerFocusMinorTargetEarlyGuardsCases();
  registerExpandPhasePlannerFocusMinorTargetEarlyFireCases();
  registerExpandPhasePlannerFocusMinorTargetEarlyBelowQuotaGuardCases();
}
