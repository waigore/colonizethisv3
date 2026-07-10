// Unit tests for `planning_phase_predicates.dart` (Refs #3941 topic split).
// Pins colonial/expand-lite gates and PhasePlanOutcome weight projections.
// `resolveFromPhasePlan` remains in `phase_planner_filter_resolution_test.dart`.

import 'package:colonizethis_ai/src/planning/observer_goal_phase.dart';
import 'package:colonizethis_ai/src/planning/phase_planner_dispatch.dart'
    show PhasePlanOutcome;
import 'package:colonizethis_ai/src/planning/phase_priority_weights.dart'
    show PhasePriorityWeights;
import 'package:colonizethis_ai/src/planning/planning_helpers.dart';
import 'package:colonizethis_test/test.dart';
const PhasePriorityWeights _weights = PhasePriorityWeights(
  oldWorldConquest: 0.11,
  newWorldAcquisition: 0.22,
  oldWorldCivilian: 0.33,
  newWorldCivilian: 0.44,
);

void main() {
  group('resolvePhaseColonialPressureActive', () {
    test('true only under COLONIAL', () {
      expect(
        resolvePhaseColonialPressureActive(ObserverGoalPhase.colonial),
        isTrue,
      );
      expect(
        resolvePhaseColonialPressureActive(ObserverGoalPhase.expand),
        isFalse,
      );
      expect(
        resolvePhaseColonialPressureActive(ObserverGoalPhase.colonialLite),
        isFalse,
      );
      expect(
        resolvePhaseColonialPressureActive(ObserverGoalPhase.develop),
        isFalse,
      );
    });
  });

  group('resolvePhaseExpandOrColonialLiteActive', () {
    test('true under EXPAND and COLONIAL-lite only', () {
      expect(
        resolvePhaseExpandOrColonialLiteActive(ObserverGoalPhase.expand),
        isTrue,
      );
      expect(
        resolvePhaseExpandOrColonialLiteActive(ObserverGoalPhase.colonialLite),
        isTrue,
      );
      expect(
        resolvePhaseExpandOrColonialLiteActive(ObserverGoalPhase.colonial),
        isFalse,
      );
      expect(
        resolvePhaseExpandOrColonialLiteActive(ObserverGoalPhase.develop),
        isFalse,
      );
    });
  });

  group('phase-plan weight projections (Refs #3717)', () {
    PhasePlanOutcome outcome({
      ObserverGoalPhase phase = ObserverGoalPhase.expand,
      PhasePriorityWeights weights = _weights,
    }) => PhasePlanOutcome(phase: phase, priorityWeights: weights);

    test('each projection returns exactly its named priorityWeights slot', () {
      final o = outcome();
      expect(
        resolvePhaseNewWorldAcquisitionWeight(o),
        equals(_weights.newWorldAcquisition),
      );
      expect(
        resolvePhaseOldWorldConquestWeight(o),
        equals(_weights.oldWorldConquest),
      );
      expect(
        resolvePhaseOldWorldCivilianWeight(o),
        equals(_weights.oldWorldCivilian),
      );
      expect(
        resolvePhaseNewWorldCivilianWeight(o),
        equals(_weights.newWorldCivilian),
      );
    });

    test('projections do not read sibling slots (no field confusion)', () {
      final o = outcome();
      // Each of the four distinct slot values is returned by exactly one
      // projection; a swapped accessor would match the wrong value here.
      expect(
        resolvePhaseNewWorldAcquisitionWeight(o),
        isNot(equals(_weights.oldWorldConquest)),
      );
      expect(
        resolvePhaseOldWorldConquestWeight(o),
        isNot(equals(_weights.newWorldAcquisition)),
      );
      expect(
        resolvePhaseOldWorldCivilianWeight(o),
        isNot(equals(_weights.newWorldCivilian)),
      );
      expect(
        resolvePhaseNewWorldCivilianWeight(o),
        isNot(equals(_weights.oldWorldCivilian)),
      );
    });

    test('projections are phase-independent and deterministic', () {
      final results = <double>{
        for (final phase in ObserverGoalPhase.values)
          resolvePhaseNewWorldAcquisitionWeight(outcome(phase: phase)),
      };
      expect(results, <double>{_weights.newWorldAcquisition});

      final o = outcome();
      expect(
        resolvePhaseOldWorldConquestWeight(o),
        equals(resolvePhaseOldWorldConquestWeight(o)),
      );
    });

    test('flipping a single slot changes only that slot projection', () {
      const bumped = PhasePriorityWeights(
        oldWorldConquest: 0.99,
        newWorldAcquisition: 0.22,
        oldWorldCivilian: 0.33,
        newWorldCivilian: 0.44,
      );
      final base = outcome();
      final next = outcome(weights: bumped);
      expect(
        resolvePhaseOldWorldConquestWeight(next),
        isNot(equals(resolvePhaseOldWorldConquestWeight(base))),
      );
      expect(
        resolvePhaseNewWorldAcquisitionWeight(next),
        equals(resolvePhaseNewWorldAcquisitionWeight(base)),
      );
      expect(
        resolvePhaseOldWorldCivilianWeight(next),
        equals(resolvePhaseOldWorldCivilianWeight(base)),
      );
      expect(
        resolvePhaseNewWorldCivilianWeight(next),
        equals(resolvePhaseNewWorldCivilianWeight(base)),
      );
    });
  });

}
