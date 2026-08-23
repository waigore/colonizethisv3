// Case bodies for `phase_planner_priority_weight_resolvers_test.dart`
// (Refs #3997 Phase 8). Registered from the thin contract; pin coverage
// preserved 1:1 from the former inline suite.

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/phase_planner_economy_filter.dart';
import 'package:colonizethis_ai/src/planning/phase_planner_goal_filter.dart';
import 'package:colonizethis_test/test.dart';
import 'phase_planner_priority_weight_resolvers_support.dart';
import 'phase_planner_priority_weight_resolvers_goal_economy_diplomacy_cases_tail_cases.dart';

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
    });
  });

  registerPhasePlannerPriorityWeightResolversGoalEconomyDiplomacyCasesTail();
}
