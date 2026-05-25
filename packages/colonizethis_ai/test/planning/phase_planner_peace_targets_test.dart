// Unit tests for `phase_planner_peace_targets.dart` (Refs #2509 S5 orchestrator slice).

import 'package:colonizethis_ai/src/planning/observer_goal_phase.dart';
import 'package:colonizethis_ai/src/planning/phase_planner_dispatch.dart';
import 'package:colonizethis_ai/src/planning/phase_planner_peace_targets.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('gpPeaceTargetsFromPhasePlan', () {
    test('EXPAND routes expandPeaceTargetFactionIdsSorted', () {
      const outcome = PhasePlanOutcome(
        phase: ObserverGoalPhase.expand,
        expandPeaceTargetFactionIdsSorted: ['gp2', 'gp3'],
      );
      expect(gpPeaceTargetsFromPhasePlan(outcome), ['gp2', 'gp3']);
    });

    test('COLONIAL-lite routes expand peace slots', () {
      const outcome = PhasePlanOutcome(
        phase: ObserverGoalPhase.colonialLite,
        expandPeaceTargetFactionIdsSorted: ['gp4'],
      );
      expect(gpPeaceTargetsFromPhasePlan(outcome), ['gp4']);
    });

    test('COLONIAL routes colonialPeaceTargetFactionIdsSorted', () {
      const outcome = PhasePlanOutcome(
        phase: ObserverGoalPhase.colonial,
        colonialPeaceTargetFactionIdsSorted: ['gp5'],
      );
      expect(gpPeaceTargetsFromPhasePlan(outcome), ['gp5']);
    });

    test('DEVELOP routes developPeaceTargetFactionIdsSorted', () {
      const outcome = PhasePlanOutcome(
        phase: ObserverGoalPhase.develop,
        developPeaceTargetFactionIdsSorted: ['gp1', 'gp6'],
      );
      expect(gpPeaceTargetsFromPhasePlan(outcome), ['gp1', 'gp6']);
    });

    test('default-plan slots yield empty lists', () {
      expect(
        gpPeaceTargetsFromPhasePlan(PhasePlanOutcome.defaultColonial),
        isEmpty,
      );
    });
  });

  group('gpPeaceTargetsFromPhasePlan determinism', () {
    test('identical outcomes yield identical lists', () {
      const outcome = PhasePlanOutcome(
        phase: ObserverGoalPhase.colonial,
        colonialPeaceTargetFactionIdsSorted: ['gp2'],
      );
      expect(
        gpPeaceTargetsFromPhasePlan(outcome),
        gpPeaceTargetsFromPhasePlan(outcome),
      );
    });
  });
}
