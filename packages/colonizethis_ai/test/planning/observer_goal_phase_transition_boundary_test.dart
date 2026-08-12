// Thin contract for observer goal phase transition boundary pin (Refs #2509,
// #4310 Slice D). Case bodies live in sibling `*_cases.dart` modules; Game
// fixtures in shared support.
//
// Pins the **no-hysteresis phase-transition guard** clause from issue #2509
// at the `observerGoalPhaseFor` + `runDomainPlanners` boundary.

import 'observer_goal_phase_transition_boundary_cases.dart';

void main() {
  registerObserverGoalPhaseTransitionBoundaryCases();
}
