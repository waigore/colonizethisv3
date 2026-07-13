// Case-library barrel (Refs #3997 Phase 8).
// Thin aggregator so existing contracts keep a stable import;
// topic modules stay ≤650 physical lines.

import 'expand_phase_planner_zero_regiment_gp_guards_fire_cases.dart';
import 'expand_phase_planner_zero_regiment_gp_stalemate_stub_cases.dart';

void registerExpandPhasePlannerZeroRegimentGpPeaceCases() {
  registerExpandPhasePlannerZeroRegimentGpGuardsFireCases();
  registerExpandPhasePlannerZeroRegimentGpStalemateStubCases();
}
