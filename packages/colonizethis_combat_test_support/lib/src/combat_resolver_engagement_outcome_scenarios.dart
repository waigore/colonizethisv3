// Table-driven land resolveEngagement / resolveBattleContext scenarios (Refs #3865, #4196 slice B).

import 'package:colonizethis_combat/colonizethis_combat.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'combat_resolver_test_support.dart';
import 'scenario_runner.dart';

List<RunnableScenario> combatResolverEngagementOutcomeScenarios() => [
  RunnableScenario(
    scenarioId: 'cre-attacker-wins-decisively',
    label: 'attacker wins decisively when much stronger',
    run: () {
      final attackerUnits = [
        Unit(
          id: 'a1',
          type: 'grenadiers',
          ownerId: 'att',
          locationProvinceId: 'p',
          medals: 3,
        ),
        Unit(
          id: 'a2',
          type: 'grenadiers',
          ownerId: 'att',
          locationProvinceId: 'p',
          medals: 2,
        ),
      ];
      final defenderUnits = [
        Unit(
          id: 'd1',
          type: 'peasant_levies',
          ownerId: 'def',
          locationProvinceId: 'p',
          medals: 0,
        ),
      ];

      final outcome = resolveEngagement(
        attackerUnits: attackerUnits,
        defenderUnits: defenderUnits,
        fortLevel: 0,
        terrain: 'plains',
      );

      expect(outcome.result, EngagementResult.attackerVictory);
      expect(outcome.defenderCasualties, contains('d1'));
    },
  ),
  RunnableScenario(
    scenarioId: 'cre-defender-wins',
    label: 'defender wins when much stronger',
    run: () {
      final attackerUnits = [
        Unit(
          id: 'a1',
          type: 'peasant_levies',
          ownerId: 'att',
          locationProvinceId: 'p',
          medals: 0,
        ),
      ];
      final defenderUnits = [
        Unit(
          id: 'd1',
          type: 'grenadiers',
          ownerId: 'def',
          locationProvinceId: 'p',
          medals: 3,
        ),
        Unit(
          id: 'd2',
          type: 'grenadiers',
          ownerId: 'def',
          locationProvinceId: 'p',
          medals: 2,
        ),
      ];

      final outcome = resolveEngagement(
        attackerUnits: attackerUnits,
        defenderUnits: defenderUnits,
        fortLevel: 0,
        terrain: 'plains',
      );

      expect(outcome.result, EngagementResult.defenderVictory);
      expect(outcome.attackerCasualties, contains('a1'));
    },
  ),
  RunnableScenario(
    scenarioId: 'cre-siege-modifiers',
    label: 'siege modifiers apply when fortLevel >= 1',
    run: () {
      final attackerUnits = [
        Unit(
          id: 'a1',
          type: 'pikemen',
          ownerId: 'att',
          locationProvinceId: 'p',
          medals: 0,
        ),
      ];
      final defenderUnits = [
        Unit(
          id: 'd1',
          type: 'peasant_levies',
          ownerId: 'def',
          locationProvinceId: 'p',
          medals: 0,
        ),
      ];

      final field = resolveEngagement(
        attackerUnits: attackerUnits,
        defenderUnits: defenderUnits,
        fortLevel: 0,
        terrain: 'plains',
      );
      final siege = resolveEngagement(
        attackerUnits: attackerUnits,
        defenderUnits: defenderUnits,
        fortLevel: 2,
        terrain: 'plains',
      );

      expect(
        siege.result,
        isNot(equals(field.result)),
        reason: 'Fort should affect outcome when strengths are close',
      );
    },
  ),
];
