// Table-driven land conflict-detection scenarios (Refs #3865, #4196 slice B).

import 'package:colonizethis_combat/colonizethis_combat.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'conflict_detection_test_support.dart';
import 'scenario_runner.dart';

List<RunnableScenario> detectConflictsOrderScenarios() => [
  RunnableScenario(
    scenarioId: 'cd-new-world-only-units',
    label: 'returns no battles when oldWorld has no units',
    run: () {
      const nw = 'newWorld';
      final game = landConflictTwoPlayerGame(
        id: 'g1',
        players: landConflictShortPlayers,
        newWorld: RegionData(
          provinces: [Province(id: '$nw|N1', regionId: nw, ownerId: 'p2')],
          units: [
            Unit(
              id: 'u1',
              type: 'musketeers',
              ownerId: 'p1',
              locationProvinceId: '$nw|N1',
            ),
            Unit(
              id: 'u2',
              type: 'pikemen',
              ownerId: 'p2',
              locationProvinceId: '$nw|N1',
            ),
          ],
        ),
      );
      final orders = Orders(
        moveOrdersByPlayerId: {
          'p1': [landConflictMoveOrder(unitId: 'u1', provinceId: '$nw|N1')],
        },
      );
      final battles = detectConflicts(game, orders);
      expect(battles.length, 1);
      expect(battles[0].regionId, nw);
    },
  ),
  RunnableScenario(
    scenarioId: 'cd-army-move-attacker',
    label: 'army move order contributes moved-in attacker detection',
    run: () {
      const ow = 'oldWorld';
      final p1 = '$ow|P1';
      final game = landConflictTwoPlayerGame(
        id: 'g_army',
        players: landConflictTestPlayers,
        oldWorld: RegionData(
          provinces: [
            Province(id: p1, regionId: ow, ownerId: 'player2'),
            Province(id: '$ow|P2', regionId: ow, ownerId: 'player1'),
          ],
          units: [
            Unit(
              id: 'u1',
              type: 'musketeers',
              ownerId: 'player1',
              locationProvinceId: p1,
            ),
            Unit(
              id: 'u2',
              type: 'pikemen',
              ownerId: 'player2',
              locationProvinceId: p1,
            ),
          ],
        ),
        armies: [
          Army(
            id: 'arm_a',
            ownerId: 'player1',
            regionId: ow,
            stationedProvinceId: p1,
            regimentUnitIds: const ['u1'],
            isHomeArmy: false,
          ),
        ],
      );

      final orders = Orders(
        armyMoveOrdersByPlayerId: {
          'player1': [
            ArmyMoveOrder(armyId: 'arm_a', destinationProvinceId: p1),
          ],
        },
      );

      final battles = detectConflicts(game, orders);
      expect(battles.length, 1);
      expect(battles[0].attackers.single.factionId, 'player1');
      expect(battles[0].attackers.single.unitIds, ['u1']);
    },
  ),
];
