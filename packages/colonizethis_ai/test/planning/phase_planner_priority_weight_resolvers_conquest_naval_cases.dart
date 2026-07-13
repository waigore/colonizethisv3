// Case bodies for `phase_planner_priority_weight_resolvers_test.dart`
// (Refs #3997 Phase 8). Registered from the thin contract; pin coverage
// preserved 1:1 from the former inline suite.

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/phase_planner_conquest_filter.dart';
import 'package:colonizethis_ai/src/planning/phase_planner_naval_filter.dart'
    show resolvePhaseNavalColonialPressureWeight;
import 'package:colonizethis_test/test.dart';
import 'phase_planner_priority_weight_resolvers_support.dart';

void registerPhasePlannerPriorityWeightResolversConquestNavalCases() {
group('Phase 2 weight resolvers — conquest filter', () {
    group('resolvePhaseConquestNwInvasionWeight', () {
      test('returns priorityWeights.newWorldAcquisition exactly', () {
        for (final phase in ObserverGoalPhase.values) {
          expect(
            resolvePhaseConquestNwInvasionWeight(
              phasePlan: priorityWeightResolversOutcomeWithWeights(
                phase: phase,
                weights: kPriorityWeightResolversUnique,
              ),
            ),
            equals(kPriorityWeightResolversUnique.newWorldAcquisition),
            reason:
                'phase $phase: resolver must project '
                'newWorldAcquisition (${kPriorityWeightResolversUnique.newWorldAcquisition})',
          );
        }
      });

      test('phase-independent — same weights, different phases', () {
        final results = <double>{
          for (final phase in ObserverGoalPhase.values)
            resolvePhaseConquestNwInvasionWeight(
              phasePlan: priorityWeightResolversOutcomeWithWeights(phase: phase, weights: kPriorityWeightResolversAlt),
            ),
        };
        expect(
          results,
          <double>{kPriorityWeightResolversAlt.newWorldAcquisition},
          reason:
              'weight resolver must depend only on priorityWeights, '
              'not outcome.phase',
        );
      });

      test('sibling-slot independence — populated COLONIAL / EXPAND '
          'slots do not affect result', () {
        for (final phase in ObserverGoalPhase.values) {
          final populated = resolvePhaseConquestNwInvasionWeight(
            phasePlan: priorityWeightResolversOutcomeWithWeights(
              phase: phase,
              weights: kPriorityWeightResolversUnique,
              populateSiblingSlots: true,
            ),
          );
          final empty = resolvePhaseConquestNwInvasionWeight(
            phasePlan: priorityWeightResolversOutcomeWithWeights(phase: phase, weights: kPriorityWeightResolversUnique),
          );
          expect(populated, equals(empty));
          expect(populated, equals(kPriorityWeightResolversUnique.newWorldAcquisition));
        }
      });

      test('deterministic across three calls (Must-have #7)', () {
        final outcome = priorityWeightResolversOutcomeWithWeights(
          phase: ObserverGoalPhase.expand,
          weights: kPriorityWeightResolversAlt,
        );
        final a = resolvePhaseConquestNwInvasionWeight(phasePlan: outcome);
        final b = resolvePhaseConquestNwInvasionWeight(phasePlan: outcome);
        final c = resolvePhaseConquestNwInvasionWeight(phasePlan: outcome);
        expect(a, b);
        expect(b, c);
      });
    });

    group('resolvePhaseConquestOldWorldInvasionWeight', () {
      test('returns priorityWeights.oldWorldConquest exactly', () {
        for (final phase in ObserverGoalPhase.values) {
          expect(
            resolvePhaseConquestOldWorldInvasionWeight(
              phasePlan: priorityWeightResolversOutcomeWithWeights(
                phase: phase,
                weights: kPriorityWeightResolversUnique,
              ),
            ),
            equals(kPriorityWeightResolversUnique.oldWorldConquest),
          );
        }
      });

      test('not confused with NW acquisition field', () {
        // kPriorityWeightResolversUnique.oldWorldConquest (0.11) != kPriorityWeightResolversUnique.newWorldAcquisition (0.22).
        final outcome = priorityWeightResolversOutcomeWithWeights(
          phase: ObserverGoalPhase.colonial,
          weights: kPriorityWeightResolversUnique,
        );
        expect(
          resolvePhaseConquestOldWorldInvasionWeight(phasePlan: outcome),
          isNot(equals(kPriorityWeightResolversUnique.newWorldAcquisition)),
        );
      });

      test('deterministic across three calls (Must-have #7)', () {
        final outcome = priorityWeightResolversOutcomeWithWeights(
          phase: ObserverGoalPhase.colonial,
          weights: kPriorityWeightResolversUnique,
        );
        final a = resolvePhaseConquestOldWorldInvasionWeight(
          phasePlan: outcome,
        );
        final b = resolvePhaseConquestOldWorldInvasionWeight(
          phasePlan: outcome,
        );
        final c = resolvePhaseConquestOldWorldInvasionWeight(
          phasePlan: outcome,
        );
        expect(a, b);
        expect(b, c);
      });
    });

    group('resolvePhaseConquestColonialPressureWeight', () {
      test('returns priorityWeights.newWorldAcquisition exactly', () {
        for (final phase in ObserverGoalPhase.values) {
          expect(
            resolvePhaseConquestColonialPressureWeight(
              phasePlan: priorityWeightResolversOutcomeWithWeights(
                phase: phase,
                weights: kPriorityWeightResolversUnique,
              ),
            ),
            equals(kPriorityWeightResolversUnique.newWorldAcquisition),
          );
        }
      });

      test('matches resolvePhaseConquestNwInvasionWeight on the same '
          'PhasePlanOutcome (both project newWorldAcquisition)', () {
        for (final phase in ObserverGoalPhase.values) {
          final outcome = priorityWeightResolversOutcomeWithWeights(phase: phase, weights: kPriorityWeightResolversAlt);
          expect(
            resolvePhaseConquestColonialPressureWeight(phasePlan: outcome),
            equals(
              resolvePhaseConquestNwInvasionWeight(phasePlan: outcome),
            ),
          );
        }
      });
    });
  });

group('Phase 3 weight resolvers — naval filter', () {
    group('resolvePhaseNavalColonialPressureWeight', () {
      test('returns priorityWeights.newWorldAcquisition exactly', () {
        for (final phase in ObserverGoalPhase.values) {
          expect(
            resolvePhaseNavalColonialPressureWeight(
              phasePlan: priorityWeightResolversOutcomeWithWeights(
                phase: phase,
                weights: kPriorityWeightResolversUnique,
              ),
            ),
            equals(kPriorityWeightResolversUnique.newWorldAcquisition),
            reason:
                'phase $phase: resolver must project '
                'newWorldAcquisition (${kPriorityWeightResolversUnique.newWorldAcquisition})',
          );
        }
      });

      test('phase-independent — same weights, different phases', () {
        final results = <double>{
          for (final phase in ObserverGoalPhase.values)
            resolvePhaseNavalColonialPressureWeight(
              phasePlan: priorityWeightResolversOutcomeWithWeights(phase: phase, weights: kPriorityWeightResolversAlt),
            ),
        };
        expect(
          results,
          <double>{kPriorityWeightResolversAlt.newWorldAcquisition},
          reason:
              'naval colonial-pressure weight resolver must depend only '
              'on priorityWeights, not outcome.phase',
        );
      });

      test('sibling-slot independence — populated COLONIAL / EXPAND '
          'slots do not affect result', () {
        for (final phase in ObserverGoalPhase.values) {
          final populated = resolvePhaseNavalColonialPressureWeight(
            phasePlan: priorityWeightResolversOutcomeWithWeights(
              phase: phase,
              weights: kPriorityWeightResolversUnique,
              populateSiblingSlots: true,
            ),
          );
          final empty = resolvePhaseNavalColonialPressureWeight(
            phasePlan: priorityWeightResolversOutcomeWithWeights(phase: phase, weights: kPriorityWeightResolversUnique),
          );
          expect(populated, equals(empty));
          expect(populated, equals(kPriorityWeightResolversUnique.newWorldAcquisition));
        }
      });

      test('matches resolvePhaseConquestNwInvasionWeight on the same '
          'PhasePlanOutcome (both project newWorldAcquisition)', () {
        for (final phase in ObserverGoalPhase.values) {
          final outcome = priorityWeightResolversOutcomeWithWeights(phase: phase, weights: kPriorityWeightResolversAlt);
          expect(
            resolvePhaseNavalColonialPressureWeight(phasePlan: outcome),
            equals(
              resolvePhaseConquestNwInvasionWeight(phasePlan: outcome),
            ),
            reason:
                'naval / conquest NW projection must agree on the same '
                'newWorldAcquisition field',
          );
        }
      });

      test('deterministic across three calls (Must-have #7)', () {
        final outcome = priorityWeightResolversOutcomeWithWeights(
          phase: ObserverGoalPhase.expand,
          weights: kPriorityWeightResolversAlt,
        );
        final a = resolvePhaseNavalColonialPressureWeight(phasePlan: outcome);
        final b = resolvePhaseNavalColonialPressureWeight(phasePlan: outcome);
        final c = resolvePhaseNavalColonialPressureWeight(phasePlan: outcome);
        expect(a, b);
        expect(b, c);
      });
    });
  });
}
