import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';
import 'package:colonizethis_test/test.dart';

import 'scenario_runner.dart';


List<RunnableScenario>
combatResolverProvinceOwnerTransferScenarios() => [
  RunnableScenario(
    scenarioId: 'crpot-owner-not-defender',
    label:
        'transfers from province owner when battle defender is another occupant',
    run: () {
      const provinceId = 'p59';
      final attackerUnits = [
        for (var i = 0; i < 4; i++)
          Unit(
            id: 'a$i',
            type: 'grenadiers',
            ownerId: 'gp5',
            locationProvinceId: provinceId,
            medals: 4,
          ),
      ];
      final defenderUnits = [
        Unit(
          id: 'd1',
          type: 'peasant_levies',
          ownerId: 'gp3',
          locationProvinceId: provinceId,
          medals: 0,
        ),
      ];
      final game = TestFixtures.minimalGame(
        id: 'g_owner_transfer',
        turnNumber: 24,
        players: const [
          Player(id: 'gp5', displayName: 'GP5', isHuman: false),
          Player(id: 'gp3', displayName: 'GP3', isHuman: false),
        ],
        oldWorld: RegionData(
          provinces: const [
            Province(id: 'p59', regionId: kRegionOldWorld, ownerId: 'minor2'),
          ],
          units: [...attackerUnits, ...defenderUnits],
        ),
      );
      const ctx = BattleContext(
        provinceId: provinceId,
        regionId: kRegionOldWorld,
        defenderFactionId: 'gp3',
        defenderUnitIds: ['d1'],
        attackers: [
          AttackingSide(factionId: 'gp5', unitIds: ['a0', 'a1', 'a2', 'a3']),
        ],
        fortLevel: 0,
        terrain: 'plains',
      );
      expect(
        resolveBattleContext(
          game,
          ctx,
        ).worldState.oldWorld.provinces.single.ownerId,
        'gp5',
      );
    },
  ),
];
