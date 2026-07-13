// Thin contract for observer goal-phase pin suite (Refs #3997 Phase 8).
// Case bodies live in sibling `*_cases.dart` modules.

import 'observer_goal_phase_gp_peace_targets_cases.dart';
import 'observer_goal_phase_phase_and_declare_war_cases.dart';

void main() {
  registerObserverGoalPhasePhaseAndDeclareWarCases();
  registerObserverGoalPhaseGpPeaceTargetsCases();
}
