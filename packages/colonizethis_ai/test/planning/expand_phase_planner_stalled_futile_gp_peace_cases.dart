// Case-library barrel — topic-split for ≤250 physical lines (Refs #4669 Slice B).
// Aggregates sibling modules split from `expand_phase_planner_stalled_futile_gp_peace_cases.dart`.

import 'expand_phase_planner_stalled_futile_gp_peace_cases_guard.dart';
import 'expand_phase_planner_stalled_futile_gp_peace_cases_fire.dart';
import 'expand_phase_planner_stalled_futile_gp_peace_cases_boundary.dart';

void registerExpandPhasePlannerStalledFutileGpPeaceCases() {
  registerExpandPhasePlannerStalledFutileGpPeaceGuardCases();
  registerExpandPhasePlannerStalledFutileGpPeaceFireCases();
  registerExpandPhasePlannerStalledFutileGpPeaceBoundaryCases();
}
