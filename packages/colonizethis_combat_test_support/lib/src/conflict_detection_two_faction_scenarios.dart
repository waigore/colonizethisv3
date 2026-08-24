// Table-driven land conflict-detection scenarios (Refs #3865, #4196 slice B).

import 'package:colonizethis_combat/colonizethis_combat.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'conflict_detection_test_support.dart';
import 'scenario_runner.dart';

List<RunnableScenario> detectConflictsTwoFactionScenarios() => [
  RunnableScenario(
    scenarioId: 'cd-two-factions-same-province',
    label: 'returns one battle when two factions in same province',
    run: () {
      const ow = 'oldWorld';
      final game = landConflictTwoPlayerGame(
        id: 'g1',
        players: landConflictTestPlayers,
        oldWorld: RegionData(
          provinces: [
            Province(id: '$ow|P1', regionId: ow, ownerId: 'player2'),
            Province(id: '$ow|P2', regionId: ow, ownerId: 'player1'),
          ],
          units: [
            Unit(
              id: 'u1',
              type: 'musketeers',
              ownerId: 'player1',
              locationProvinceId: '$ow|P1',
            ),
            Unit(
              id: 'u2',
              type: 'pikemen',
              ownerId: 'player2',
              locationProvinceId: '$ow|P1',
            ),
          ],
        ),
      );

      final orders = Orders(
        moveOrdersByPlayerId: {
          'player1': [
            landConflictMoveOrder(unitId: 'u1', provinceId: '$ow|P1'),
          ],
        },
      );

      final battles = detectConflicts(game, orders);

      expect(battles.length, 1);
      expect(battles[0].provinceId, 'oldWorld|P1');
      expect(battles[0].defenderFactionId, 'player2');
      expect(battles[0].defenderUnitIds, ['u2']);
      expect(battles[0].attackers.length, 1);
      expect(battles[0].attackers[0].factionId, 'player1');
      expect(battles[0].attackers[0].unitIds, ['u1']);
    },
  ),
  RunnableScenario(
    scenarioId: 'cd-new-world-conflict',
    label: 'detects conflict in newWorld when two factions and move order',
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
      expect(battles[0].provinceId, '$nw|N1');
    },
  ),
];
