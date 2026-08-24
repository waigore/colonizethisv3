// Probabilistic outcome scenarios (Refs #4196 slice C).

import 'package:colonizethis_combat/colonizethis_combat.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'combat_resolver_test_support.dart';
import 'scenario_runner.dart';

List<RunnableScenario> combatResolverProbabilisticOutcomeScenarios() => [
  RunnableScenario(
    scenarioId: 'crp-per-round-details',
    label: 'outcome includes per-round details',
    run: () {
      final attackerUnits = [probResolverUnit(id: 'a1', type: 'grenadiers')];
      final defenderUnits = [
        probResolverUnit(id: 'd1', type: 'peasant_levies', ownerId: 'def'),
      ];

      final outcome = resolveEngagementProbabilistic(
        attackerUnits: attackerUnits,
        defenderUnits: defenderUnits,
        fortLevel: 0,
        terrain: 'plains',
        seed: 123,
      );

      expect(outcome.rounds, isNotEmpty);
      for (final round in outcome.rounds) {
        expect(round.probabilityAttackerHits, inInclusiveRange(0.15, 0.85));
        expect(round.probabilityDefenderHits, inInclusiveRange(0.15, 0.85));
      }
    },
  ),
  RunnableScenario(
    scenarioId: 'crp-mutual-annihilation-possible',
    label: 'can produce mutualAnnihilation when both sides eliminated',
    run: () {
      final attackerUnits = [
        probResolverUnit(id: 'a1', type: 'pikemen'),
        probResolverUnit(id: 'a2', type: 'pikemen'),
      ];
      final defenderUnits = [
        probResolverUnit(id: 'd1', type: 'pikemen', ownerId: 'def'),
        probResolverUnit(id: 'd2', type: 'pikemen', ownerId: 'def'),
      ];
      EngagementResult? mutualAnnihilationResult;
      for (var s = 0; s < 500; s++) {
        final outcome = resolveEngagementProbabilistic(
          attackerUnits: attackerUnits,
          defenderUnits: defenderUnits,
          fortLevel: 0,
          terrain: 'plains',
          seed: s,
        );
        if (outcome.result == EngagementResult.mutualAnnihilation) {
          mutualAnnihilationResult = outcome.result;
          break;
        }
      }
      expect(
        mutualAnnihilationResult,
        EngagementResult.mutualAnnihilation,
        reason: 'some seed should produce mutual annihilation',
      );
    },
  ),
  RunnableScenario(
    scenarioId: 'crp-stalemate-possible',
    label: 'can produce stalemate when rounds end with both sides remaining',
    run: () {
      final attackerUnits = [
        probResolverUnit(id: 'a1', type: 'pikemen'),
        probResolverUnit(id: 'a2', type: 'pikemen'),
        probResolverUnit(id: 'a3', type: 'pikemen'),
      ];
      final defenderUnits = [
        probResolverUnit(id: 'd1', type: 'pikemen', ownerId: 'def'),
        probResolverUnit(id: 'd2', type: 'pikemen', ownerId: 'def'),
        probResolverUnit(id: 'd3', type: 'pikemen', ownerId: 'def'),
      ];
      EngagementResult? stalemateResult;
      for (var s = 0; s < 1000; s++) {
        final outcome = resolveEngagementProbabilistic(
          attackerUnits: attackerUnits,
          defenderUnits: defenderUnits,
          fortLevel: 0,
          terrain: 'plains',
          seed: s,
        );
        if (outcome.result == EngagementResult.stalemate) {
          stalemateResult = outcome.result;
          break;
        }
      }
      expect(
        stalemateResult,
        EngagementResult.stalemate,
        reason: 'some seed should produce stalemate after max rounds',
      );
    },
  ),
];
