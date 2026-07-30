// Deployment-limit scenarios for land resolver (Refs #4196 slice C).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'combat_resolver_test_support.dart';
import 'scenario_runner.dart';

List<RunnableScenario> combatResolverDeploymentLimitScenarios() =>
    [
  RunnableScenario(
    scenarioId: 'crl-deployment-cap-base-10',
    label:
        'deployment limit caps participating regiments per side (base 10, no Nationalism)',
    run: () {
      final attackerUnits = List.generate(
        15,
        (i) => Unit(
          id: 'a$i',
          type: 'grenadiers',
          ownerId: 'att',
          locationProvinceId: 'p',
          medals: 1,
        ),
      );
      final defenderUnits = List.generate(
        15,
        (i) => Unit(
          id: 'd$i',
          type: 'peasant_levies',
          ownerId: 'def',
          locationProvinceId: 'p',
          medals: 0,
        ),
      );
      final game = landResolverBattleGame(
        units: [...attackerUnits, ...defenderUnits],
      );
      final ctx = BattleContext(
        provinceId: 'p',
        regionId: 'oldWorld',
        defenderFactionId: 'def',
        defenderUnitIds: defenderUnits.map((u) => u.id).toList(),
        attackers: [
          AttackingSide(
            factionId: 'att',
            unitIds: attackerUnits.map((u) => u.id).toList(),
            generalMedals: 0,
          ),
        ],
        fortLevel: 0,
        terrain: 'plains',
      );
      final result = resolveBattleContext(game, ctx);
      final survivingAtt = result.worldState.oldWorld.units
          .where((u) => u.ownerId == 'att')
          .length;
      final survivingDef = result.worldState.oldWorld.units
          .where((u) => u.ownerId == 'def')
          .length;
      expect(
        survivingAtt,
        greaterThanOrEqualTo(5),
        reason:
            'deployment limit 10: at most 10 attackers participate, so ≥5 must remain',
      );
      expect(
        survivingAtt + survivingDef,
        greaterThanOrEqualTo(5),
        reason: 'at least one side has non-participants',
      );
    },
  ),
  RunnableScenario(
    scenarioId: 'crl-deployment-cap-nationalism-12',
    label:
        'deployment limit with Nationalism tech is 12 (attacker has 13 units, ≥1 does not participate)',
    run: () {
      final attackerUnits = List.generate(
        13,
        (i) => Unit(
          id: 'a$i',
          type: 'grenadiers',
          ownerId: 'att',
          locationProvinceId: 'p',
          medals: 0,
        ),
      );
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
        players: const [
          Player(
            id: 'att',
            displayName: 'Att',
            isHuman: true,
            techUnlocked: {kTechIdNationalism: true},
          ),
          Player(id: 'def', displayName: 'Def', isHuman: false),
        ],
      );
      final ctx = BattleContext(
        provinceId: 'p',
        regionId: 'oldWorld',
        defenderFactionId: 'def',
        defenderUnitIds: ['d1'],
        attackers: [
          AttackingSide(
            factionId: 'att',
            unitIds: attackerUnits.map((u) => u.id).toList(),
            generalMedals: 0,
          ),
        ],
        fortLevel: 0,
        terrain: 'plains',
      );
      final result = resolveBattleContext(game, ctx);
      final survivingAtt = result.worldState.oldWorld.units
          .where((u) => u.ownerId == 'att')
          .length;
      expect(
        survivingAtt,
        greaterThanOrEqualTo(1),
        reason: 'deployment limit 12 with Nationalism: at most 12 participate',
      );
    },
  ),
];

