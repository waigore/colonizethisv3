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
      expect(
        gpPeaceTargetsFromPhasePlan(outcome),
        ['gp2', 'gp3'],
      );
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

  group('distractionPeaceTargetsFromPhasePlan (Refs #2847 § H5)', () {
    test('EXPAND routes expandDistractionPeaceTargetFactionIdsSorted', () {
      const outcome = PhasePlanOutcome(
        phase: ObserverGoalPhase.expand,
        expandDistractionPeaceTargetFactionIdsSorted: ['minor_b', 'tribe_a'],
      );
      expect(
        distractionPeaceTargetsFromPhasePlan(outcome),
        ['minor_b', 'tribe_a'],
      );
    });

    test('COLONIAL-lite routes the expand distraction slot', () {
      const outcome = PhasePlanOutcome(
        phase: ObserverGoalPhase.colonialLite,
        expandDistractionPeaceTargetFactionIdsSorted: ['tribe_z'],
      );
      expect(distractionPeaceTargetsFromPhasePlan(outcome), ['tribe_z']);
    });

    test('COLONIAL and DEVELOP carry no distraction peace', () {
      const colonial = PhasePlanOutcome(
        phase: ObserverGoalPhase.colonial,
        // Distraction slot is EXPAND-only; even if populated it is ignored
        // outside EXPAND / COLONIAL-lite.
        expandDistractionPeaceTargetFactionIdsSorted: ['tribe_a'],
      );
      const develop = PhasePlanOutcome(
        phase: ObserverGoalPhase.develop,
        expandDistractionPeaceTargetFactionIdsSorted: ['tribe_a'],
      );
      expect(distractionPeaceTargetsFromPhasePlan(colonial), isEmpty);
      expect(distractionPeaceTargetsFromPhasePlan(develop), isEmpty);
    });

    test('default EXPAND outcome yields an empty distraction list', () {
      expect(
        distractionPeaceTargetsFromPhasePlan(PhasePlanOutcome.defaultExpand),
        isEmpty,
      );
    });

    test('GP peace and distraction peace are carried on separate slots', () {
      const outcome = PhasePlanOutcome(
        phase: ObserverGoalPhase.expand,
        expandPeaceTargetFactionIdsSorted: ['gp3'],
        expandDistractionPeaceTargetFactionIdsSorted: ['tribe_a'],
      );
      expect(gpPeaceTargetsFromPhasePlan(outcome), ['gp3']);
      expect(distractionPeaceTargetsFromPhasePlan(outcome), ['tribe_a']);
    });
  });
}
