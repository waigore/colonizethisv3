// Case bodies for `phase_planner_priority_weight_resolvers_test.dart`
// (Refs #3997 Phase 8). Registered from the thin contract; pin coverage
// preserved 1:1 from the former inline suite.

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/phase_planner_conquest_filter.dart';
import 'package:colonizethis_ai/src/planning/phase_planner_diplomacy_filter.dart';
import 'package:colonizethis_ai/src/planning/phase_planner_economy_filter.dart';
import 'package:colonizethis_ai/src/planning/phase_planner_goal_filter.dart';
import 'package:colonizethis_ai/src/planning/phase_planner_naval_filter.dart'
    show resolvePhaseNavalColonialPressureWeight;
import 'package:colonizethis_test/test.dart';
import 'phase_planner_priority_weight_resolvers_support.dart';

void registerPhasePlannerPriorityWeightResolversGoalEconomyDiplomacyCases() {
group('Phase 2 weight resolvers — goal filter', () {
    group('resolvePhaseGoalColonialPressureWeight', () {
      test('returns weights.newWorldAcquisition exactly', () {
        expect(
          resolvePhaseGoalColonialPressureWeight(kPriorityWeightResolversUnique),
          equals(kPriorityWeightResolversUnique.newWorldAcquisition),
        );
        expect(
          resolvePhaseGoalColonialPressureWeight(kPriorityWeightResolversAlt),
          equals(kPriorityWeightResolversAlt.newWorldAcquisition),
        );
      });

      test('uses earlySprintDefault canonical value', () {
        expect(
          resolvePhaseGoalColonialPressureWeight(
            PhasePriorityWeights.earlySprintDefault,
          ),
          equals(0.05),
        );
      });

      test('deterministic across three calls (Must-have #7)', () {
        final a = resolvePhaseGoalColonialPressureWeight(kPriorityWeightResolversUnique);
        final b = resolvePhaseGoalColonialPressureWeight(kPriorityWeightResolversUnique);
        final c = resolvePhaseGoalColonialPressureWeight(kPriorityWeightResolversUnique);
        expect(a, b);
        expect(b, c);
      });
    });

    group('resolvePhaseGoalOldWorldConquestWeight', () {
      test('returns weights.oldWorldConquest exactly', () {
        expect(
          resolvePhaseGoalOldWorldConquestWeight(kPriorityWeightResolversUnique),
          equals(kPriorityWeightResolversUnique.oldWorldConquest),
        );
        expect(
          resolvePhaseGoalOldWorldConquestWeight(kPriorityWeightResolversAlt),
          equals(kPriorityWeightResolversAlt.oldWorldConquest),
        );
      });

      test('uses earlySprintDefault canonical value', () {
        expect(
          resolvePhaseGoalOldWorldConquestWeight(
            PhasePriorityWeights.earlySprintDefault,
          ),
          equals(0.95),
        );
      });

      test('not confused with the NW acquisition pair', () {
        expect(
          resolvePhaseGoalOldWorldConquestWeight(kPriorityWeightResolversUnique),
          isNot(equals(kPriorityWeightResolversUnique.newWorldAcquisition)),
        );
        expect(
          resolvePhaseGoalOldWorldConquestWeight(kPriorityWeightResolversUnique),
          isNot(
            equals(resolvePhaseGoalColonialPressureWeight(kPriorityWeightResolversUnique)),
          ),
        );
      });
    });
  });

group('Phase 2 weight resolvers — economy filter', () {
    group('resolvePhaseEconomyColonialPressureWeight', () {
      test('returns priorityWeights.newWorldAcquisition exactly', () {
        for (final phase in ObserverGoalPhase.values) {
          expect(
            resolvePhaseEconomyColonialPressureWeight(
              phasePlan: priorityWeightResolversOutcomeWithWeights(
                phase: phase,
                weights: kPriorityWeightResolversUnique,
              ),
            ),
            equals(kPriorityWeightResolversUnique.newWorldAcquisition),
          );
        }
      });

      test('sibling-slot independence', () {
        for (final phase in ObserverGoalPhase.values) {
          final populated = resolvePhaseEconomyColonialPressureWeight(
            phasePlan: priorityWeightResolversOutcomeWithWeights(
              phase: phase,
              weights: kPriorityWeightResolversUnique,
              populateSiblingSlots: true,
            ),
          );
          expect(populated, equals(kPriorityWeightResolversUnique.newWorldAcquisition));
        }
      });
    });

    group('resolvePhaseEconomyOldWorldCivilianWeight', () {
      test('returns priorityWeights.oldWorldCivilian exactly', () {
        for (final phase in ObserverGoalPhase.values) {
          expect(
            resolvePhaseEconomyOldWorldCivilianWeight(
              phasePlan: priorityWeightResolversOutcomeWithWeights(
                phase: phase,
                weights: kPriorityWeightResolversUnique,
              ),
            ),
            equals(kPriorityWeightResolversUnique.oldWorldCivilian),
          );
        }
      });

      test('not confused with oldWorldConquest', () {
        final outcome = priorityWeightResolversOutcomeWithWeights(
          phase: ObserverGoalPhase.expand,
          weights: kPriorityWeightResolversUnique,
        );
        expect(
          resolvePhaseEconomyOldWorldCivilianWeight(phasePlan: outcome),
          isNot(equals(kPriorityWeightResolversUnique.oldWorldConquest)),
        );
      });

      test('deterministic across three calls (Must-have #7)', () {
        final outcome = priorityWeightResolversOutcomeWithWeights(
          phase: ObserverGoalPhase.develop,
          weights: kPriorityWeightResolversAlt,
        );
        final a = resolvePhaseEconomyOldWorldCivilianWeight(
          phasePlan: outcome,
        );
        final b = resolvePhaseEconomyOldWorldCivilianWeight(
          phasePlan: outcome,
        );
        final c = resolvePhaseEconomyOldWorldCivilianWeight(
          phasePlan: outcome,
        );
        expect(a, b);
        expect(b, c);
      });
    });

    group('resolvePhaseEconomyNewWorldCivilianWeight', () {
      test('returns priorityWeights.newWorldCivilian exactly', () {
        for (final phase in ObserverGoalPhase.values) {
          expect(
            resolvePhaseEconomyNewWorldCivilianWeight(
              phasePlan: priorityWeightResolversOutcomeWithWeights(
                phase: phase,
                weights: kPriorityWeightResolversUnique,
              ),
            ),
            equals(kPriorityWeightResolversUnique.newWorldCivilian),
          );
        }
      });

      test('not confused with newWorldAcquisition', () {
        // kPriorityWeightResolversUnique.newWorldCivilian (0.44) != kPriorityWeightResolversUnique.newWorldAcquisition (0.22).
        final outcome = priorityWeightResolversOutcomeWithWeights(
          phase: ObserverGoalPhase.colonial,
          weights: kPriorityWeightResolversUnique,
        );
        expect(
          resolvePhaseEconomyNewWorldCivilianWeight(phasePlan: outcome),
          isNot(equals(kPriorityWeightResolversUnique.newWorldAcquisition)),
        );
      });
    });
  });

group('Phase 2 weight resolvers — diplomacy filter', () {
    group('resolvePhaseDiplomacyDeclareWarColonialPressureWeight', () {
      test('returns priorityWeights.newWorldAcquisition exactly', () {
        for (final phase in ObserverGoalPhase.values) {
          expect(
            resolvePhaseDiplomacyDeclareWarColonialPressureWeight(
              phasePlan: priorityWeightResolversOutcomeWithWeights(
                phase: phase,
                weights: kPriorityWeightResolversUnique,
              ),
            ),
            equals(kPriorityWeightResolversUnique.newWorldAcquisition),
          );
        }
      });

      test('phase-independent — projects only priorityWeights', () {
        final results = <double>{
          for (final phase in ObserverGoalPhase.values)
            resolvePhaseDiplomacyDeclareWarColonialPressureWeight(
              phasePlan: priorityWeightResolversOutcomeWithWeights(phase: phase, weights: kPriorityWeightResolversAlt),
            ),
        };
        expect(results, <double>{kPriorityWeightResolversAlt.newWorldAcquisition});
      });
    });

    group('resolvePhaseDiplomacyDeclareWarOldWorldConquestWeight', () {
      test('returns priorityWeights.oldWorldConquest exactly', () {
        for (final phase in ObserverGoalPhase.values) {
          expect(
            resolvePhaseDiplomacyDeclareWarOldWorldConquestWeight(
              phasePlan: priorityWeightResolversOutcomeWithWeights(
                phase: phase,
                weights: kPriorityWeightResolversUnique,
              ),
            ),
            equals(kPriorityWeightResolversUnique.oldWorldConquest),
          );
        }
      });

      test('not confused with newWorldAcquisition pair', () {
        final outcome = priorityWeightResolversOutcomeWithWeights(
          phase: ObserverGoalPhase.colonial,
          weights: kPriorityWeightResolversUnique,
        );
        expect(
          resolvePhaseDiplomacyDeclareWarOldWorldConquestWeight(
            phasePlan: outcome,
          ),
          isNot(
            equals(
              resolvePhaseDiplomacyDeclareWarColonialPressureWeight(
                phasePlan: outcome,
              ),
            ),
          ),
        );
      });

      test('deterministic across three calls (Must-have #7)', () {
        final outcome = priorityWeightResolversOutcomeWithWeights(
          phase: ObserverGoalPhase.expand,
          weights: kPriorityWeightResolversAlt,
        );
        final a = resolvePhaseDiplomacyDeclareWarOldWorldConquestWeight(
          phasePlan: outcome,
        );
        final b = resolvePhaseDiplomacyDeclareWarOldWorldConquestWeight(
          phasePlan: outcome,
        );
        final c = resolvePhaseDiplomacyDeclareWarOldWorldConquestWeight(
          phasePlan: outcome,
        );
        expect(a, b);
        expect(b, c);
      });
    });
  });

group('cross-filter field-exclusivity sweep', () {
    test('every weight resolver projects exactly its named field', () {
      final outcome = priorityWeightResolversOutcomeWithWeights(
        phase: ObserverGoalPhase.colonial,
        weights: kPriorityWeightResolversUnique,
      );
      // oldWorldConquest projections
      for (final actual in <double>[
        resolvePhaseConquestOldWorldInvasionWeight(phasePlan: outcome),
        resolvePhaseDiplomacyDeclareWarOldWorldConquestWeight(
          phasePlan: outcome,
        ),
        resolvePhaseGoalOldWorldConquestWeight(kPriorityWeightResolversUnique),
      ]) {
        expect(actual, equals(kPriorityWeightResolversUnique.oldWorldConquest));
      }
      // newWorldAcquisition projections
      for (final actual in <double>[
        resolvePhaseConquestNwInvasionWeight(phasePlan: outcome),
        resolvePhaseConquestColonialPressureWeight(phasePlan: outcome),
        resolvePhaseEconomyColonialPressureWeight(phasePlan: outcome),
        resolvePhaseDiplomacyDeclareWarColonialPressureWeight(
          phasePlan: outcome,
        ),
        resolvePhaseGoalColonialPressureWeight(kPriorityWeightResolversUnique),
        resolvePhaseNavalColonialPressureWeight(phasePlan: outcome),
      ]) {
        expect(actual, equals(kPriorityWeightResolversUnique.newWorldAcquisition));
      }
      // oldWorldCivilian projection
      expect(
        resolvePhaseEconomyOldWorldCivilianWeight(phasePlan: outcome),
        equals(kPriorityWeightResolversUnique.oldWorldCivilian),
      );
      // newWorldCivilian projection
      expect(
        resolvePhaseEconomyNewWorldCivilianWeight(phasePlan: outcome),
        equals(kPriorityWeightResolversUnique.newWorldCivilian),
      );
    });

    test('the four fields are read disjointly — flipping a single field '
        'changes only the resolvers that project it', () {
      const baseline = PhasePriorityWeights(
        oldWorldConquest: 0.10,
        newWorldAcquisition: 0.20,
        oldWorldCivilian: 0.30,
        newWorldCivilian: 0.40,
      );
      const owConquestBumped = PhasePriorityWeights(
        oldWorldConquest: 0.99,
        newWorldAcquisition: 0.20,
        oldWorldCivilian: 0.30,
        newWorldCivilian: 0.40,
      );

      final base = priorityWeightResolversOutcomeWithWeights(
        phase: ObserverGoalPhase.expand,
        weights: baseline,
      );
      final bumped = priorityWeightResolversOutcomeWithWeights(
        phase: ObserverGoalPhase.expand,
        weights: owConquestBumped,
      );

      // OW conquest resolvers must change.
      expect(
        resolvePhaseConquestOldWorldInvasionWeight(phasePlan: bumped),
        isNot(
          equals(
            resolvePhaseConquestOldWorldInvasionWeight(phasePlan: base),
          ),
        ),
      );
      expect(
        resolvePhaseDiplomacyDeclareWarOldWorldConquestWeight(
          phasePlan: bumped,
        ),
        isNot(
          equals(
            resolvePhaseDiplomacyDeclareWarOldWorldConquestWeight(
              phasePlan: base,
            ),
          ),
        ),
      );
      // Other resolvers must NOT change.
      expect(
        resolvePhaseConquestNwInvasionWeight(phasePlan: bumped),
        equals(resolvePhaseConquestNwInvasionWeight(phasePlan: base)),
      );
      expect(
        resolvePhaseEconomyOldWorldCivilianWeight(phasePlan: bumped),
        equals(
          resolvePhaseEconomyOldWorldCivilianWeight(phasePlan: base),
        ),
      );
      expect(
        resolvePhaseEconomyNewWorldCivilianWeight(phasePlan: bumped),
        equals(
          resolvePhaseEconomyNewWorldCivilianWeight(phasePlan: base),
        ),
      );
      expect(
        resolvePhaseEconomyColonialPressureWeight(phasePlan: bumped),
        equals(
          resolvePhaseEconomyColonialPressureWeight(phasePlan: base),
        ),
      );
    });
  });
}
