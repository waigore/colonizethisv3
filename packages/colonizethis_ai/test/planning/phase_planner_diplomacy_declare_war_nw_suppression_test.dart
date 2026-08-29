// Behavioural integration pins for Phase 3 diplomacy declare-war NW wiring
// (Refs #2847). Case bodies: `phase_planner_diplomacy_declare_war_nw_suppression_*_cases.dart`.

import 'phase_planner_diplomacy_declare_war_nw_suppression_default_curve_cases.dart';
import 'phase_planner_diplomacy_declare_war_nw_suppression_override_cases.dart';

void main() {
  registerPhasePlannerDiplomacyDeclareWarNwSuppressionDefaultCurveCases();
  registerPhasePlannerDiplomacyDeclareWarNwSuppressionOverrideCases();
}
