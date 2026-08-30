// Pins the canonical home in `observer_goal_phase.dart` for the
// cross-phase critical-collapse and zero-regiment survival peace
// aggregator `survivalGreatPowerPeaceTargets` (Refs #2509 S1).
//
// Sibling deciders the aggregator fans across (each already pinned by
// its own canonical-home suite — this file only pins the aggregator
// composition, not the sub-decider semantics):
//
//   1. `criticalWeakGpSurvivalPeaceTargets` — expand_phase_planner_critical_peace_test.dart
//   2. `stalledZeroRegimentAllFactionPeaceTargets` — expand_phase_planner_zero_regiment_gp_peace_test.dart
//   3. `mutualZeroRegimentGpStalematePeaceTargets` — expand_phase_planner_zero_regiment_gp_peace_test.dart
//   4. `stalledZeroRegimentGpPeaceTargets` — expand_phase_planner_zero_regiment_gp_peace_test.dart
//   5. `mutualExhaustedBelowQuotaGpStalematePeaceTargets` — expand_phase_planner_survival_multi_front_peace_test.dart

import 'observer_goal_phase_survival_great_power_peace_targets_cases.dart';

void main() {
  registerObserverGoalPhaseSurvivalGreatPowerPeaceTargetsCases();
}
