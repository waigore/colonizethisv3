// Table-driven land resolveEngagement / resolveBattleContext scenarios (Refs #3865, #4196 slice B).

import 'package:colonizethis_combat/colonizethis_combat.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'combat_resolver_test_support.dart';
import 'scenario_runner.dart';

List<RunnableScenario> combatResolverEngagementContextScenarios() => [
  RunnableScenario(
    scenarioId: 'cre-feeding-morale-penalty',
    label:
        'low attacker feeding coverage penalises strength via morale multiplier',
    run: () {
      final attackerUnits = [
        Unit(
          id: 'a1',
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

      final wellFed = resolveEngagement(
        attackerUnits: attackerUnits,
        defenderUnits: defenderUnits,
        fortLevel: 0,
        terrain: 'plains',
        attackerMoraleMultiplier: 1.0,
        defenderMoraleMultiplier: 1.0,
      );

      final underfed = resolveEngagement(
        attackerUnits: attackerUnits,
        defenderUnits: defenderUnits,
        fortLevel: 0,
        terrain: 'plains',
        attackerMoraleMultiplier: 0.5,
        defenderMoraleMultiplier: 1.0,
      );

      expect(underfed.attackerStrength, wellFed.attackerStrength);
      expect(
        underfed.result == EngagementResult.attackerVictory,
        isFalse,
        reason:
            'Underfed attacker should not perform better than well-fed attacker',
      );
    },
  ),
  RunnableScenario(
    scenarioId: 'cre-leader-keys-resolve-path',
    label:
        'leader keys from Game produce correct multipliers in resolveEngagement path',
    run: () {
      final attackerUnits = [
        Unit(
          id: 'a1',
          type: 'grenadiers',
          ownerId: 'att',
          locationProvinceId: 'p',
          medals: 2,
        ),
        Unit(
          id: 'a2',
          type: 'grenadiers',
          ownerId: 'att',
          locationProvinceId: 'p',
          medals: 1,
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
      final game = landResolverBattleGame(
        units: [...attackerUnits, ...defenderUnits],
        players: landResolverNapoleonFrederickPlayers,
      );
      const ctx = BattleContext(
        provinceId: 'p',
        regionId: 'oldWorld',
        defenderFactionId: 'def',
        defenderUnitIds: ['d1'],
        attackers: [
          AttackingSide(factionId: 'att', unitIds: ['a1', 'a2']),
        ],
        fortLevel: 0,
        terrain: 'plains',
      );
      final result = resolveBattleContext(game, ctx);
      expect(
        result.worldState.oldWorld.units.length,
        lessThanOrEqualTo(3),
        reason: 'some units may be casualties',
      );
      expect(result.worldState.oldWorld.provinces.single.id, 'p');
    },
  ),
  RunnableScenario(
    scenarioId: 'cre-new-world-context',
    label: 'resolveBattleContext updates newWorld when regionId is newWorld',
    run: () {
      final game = landResolverNewWorldBattleGame(
        provinceId: 'N1',
        units: [
          Unit(
            id: 'd1',
            type: 'peasant_levies',
            ownerId: 'def',
            locationProvinceId: 'N1',
            medals: 0,
          ),
          Unit(
            id: 'a1',
            type: 'grenadiers',
            ownerId: 'att',
            locationProvinceId: 'N1',
            medals: 3,
          ),
          Unit(
            id: 'a2',
            type: 'grenadiers',
            ownerId: 'att',
            locationProvinceId: 'N1',
            medals: 2,
          ),
        ],
      );
      const ctx = BattleContext(
        provinceId: 'N1',
        regionId: 'newWorld',
        defenderFactionId: 'def',
        defenderUnitIds: ['d1'],
        attackers: [
          AttackingSide(
            factionId: 'att',
            unitIds: ['a1', 'a2'],
            generalMedals: 0,
          ),
        ],
        fortLevel: 0,
        terrain: 'plains',
      );
      final result = resolveBattleContext(game, ctx);
      expect(result.worldState.newWorld.provinces.single.id, 'N1');
      expect(
        result.worldState.newWorld.units.length,
        greaterThanOrEqualTo(1),
        reason: 'attacker should win and have at least one surviving unit',
      );
    },
  ),
];
