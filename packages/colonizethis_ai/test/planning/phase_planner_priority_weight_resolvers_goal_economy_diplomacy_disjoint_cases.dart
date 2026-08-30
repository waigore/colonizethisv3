// Disjoint-field projection pins for phase priority weight resolvers.

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/phase_planner_conquest_filter.dart';
import 'package:colonizethis_ai/src/planning/phase_planner_diplomacy_filter.dart';
import 'package:colonizethis_ai/src/planning/phase_planner_economy_filter.dart';
import 'package:colonizethis_test/test.dart';

import 'phase_planner_priority_weight_resolvers_support.dart';

void registerPhasePlannerPriorityWeightResolversGoalEconomyDiplomacyDisjointCases() {
  group('cross-filter field-exclusivity sweep', () {
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
