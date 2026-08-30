// Probabilistic engagement scenarios (Refs #4196 slice C).

import 'package:colonizethis_combat/colonizethis_combat.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'combat_resolver_test_support.dart';
import 'scenario_runner.dart';

List<RunnableScenario> combatResolverProbabilisticCoreScenarios() => [
  RunnableScenario(
    scenarioId: 'crp-same-seed-identical',
    label: 'same seed produces identical outcome',
    run: () {
      final attackerUnits = [
        probResolverUnit(id: 'a1', type: 'grenadiers', medals: 1),
        probResolverUnit(id: 'a2', type: 'grenadiers'),
      ];
      final defenderUnits = [
        probResolverUnit(id: 'd1', type: 'peasant_levies', ownerId: 'def'),
        probResolverUnit(id: 'd2', type: 'peasant_levies', ownerId: 'def'),
      ];

      final r1 = resolveEngagementProbabilistic(
        attackerUnits: attackerUnits,
        defenderUnits: defenderUnits,
        fortLevel: 0,
        terrain: 'plains',
        seed: 42,
      );
      final r2 = resolveEngagementProbabilistic(
        attackerUnits: attackerUnits,
        defenderUnits: defenderUnits,
        fortLevel: 0,
        terrain: 'plains',
        seed: 42,
      );

      expect(r1.result, r2.result);
      expect(r1.attackerCasualties, r2.attackerCasualties);
      expect(r1.defenderCasualties, r2.defenderCasualties);
      expect(r1.rounds.length, r2.rounds.length);
      for (var i = 0; i < r1.rounds.length; i++) {
        expect(
          r1.rounds[i].defenderCasualties,
          r2.rounds[i].defenderCasualties,
        );
        expect(
          r1.rounds[i].attackerCasualties,
          r2.rounds[i].attackerCasualties,
        );
      }
    },
  ),
  RunnableScenario(
    scenarioId: 'crp-rounds-bounded',
    label: 'rounds bounded by maxCombatRounds',
    run: () {
      final attackerUnits = [
        probResolverUnit(id: 'a1', type: 'pikemen'),
        probResolverUnit(id: 'a2', type: 'pikemen'),
      ];
      final defenderUnits = [
        probResolverUnit(id: 'd1', type: 'pikemen', ownerId: 'def'),
        probResolverUnit(id: 'd2', type: 'pikemen', ownerId: 'def'),
      ];

      final outcome = resolveEngagementProbabilistic(
        attackerUnits: attackerUnits,
        defenderUnits: defenderUnits,
        fortLevel: 0,
        terrain: 'plains',
        seed: 999,
      );

      expect(outcome.rounds.length, lessThanOrEqualTo(maxCombatRounds));
    },
  ),
  RunnableScenario(
    scenarioId: 'crp-strong-attacker-wins-majority',
    label: 'strong attacker tends to win over many trials',
    run: () {
      final attackerUnits = [
        probResolverUnit(id: 'a1', type: 'grenadiers', medals: 2),
        probResolverUnit(id: 'a2', type: 'grenadiers', medals: 1),
      ];
      final defenderUnits = [
        probResolverUnit(id: 'd1', type: 'peasant_levies', ownerId: 'def'),
      ];

      var attWins = 0;
      for (var i = 0; i < 100; i++) {
        final r = resolveEngagementProbabilistic(
          attackerUnits: attackerUnits,
          defenderUnits: defenderUnits,
          fortLevel: 0,
          terrain: 'plains',
          seed: 1000 + i,
        );
        if (r.result == EngagementResult.attackerVictory) attWins++;
      }
      expect(
        attWins,
        greaterThan(50),
        reason: 'Strong attacker should win majority',
      );
    },
  ),
];
