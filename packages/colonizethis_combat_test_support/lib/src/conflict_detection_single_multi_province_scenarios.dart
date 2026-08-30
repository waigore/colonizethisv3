// Table-driven land conflict-detection scenarios (Refs #3865, #4196 slice B).

import 'package:colonizethis_combat/colonizethis_combat.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'conflict_detection_test_support.dart';
import 'scenario_runner.dart';

List<RunnableScenario> detectConflictsSingleAndMultiProvinceScenarios() => [
  RunnableScenario(
    scenarioId: 'cd-single-faction',
    label: 'returns no battle when only one faction in province',
    run: () {
      const ow = 'oldWorld';
      final game = landConflictTwoPlayerGame(
        id: 'g1',
        players: [landConflictTestPlayers[0]],
        oldWorld: RegionData(
          provinces: [Province(id: '$ow|P1', regionId: ow, ownerId: 'player1')],
          units: [
            Unit(
              id: 'u1',
              type: 'musketeers',
              ownerId: 'player1',
              locationProvinceId: '$ow|P1',
            ),
          ],
        ),
      );

      final battles = detectConflicts(game, const Orders());

      expect(battles, isEmpty);
    },
  ),
  RunnableScenario(
    scenarioId: 'cd-multiple-provinces',
    label: 'multiple provinces with conflicts return multiple battles',
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
            Unit(
              id: 'u3',
              type: 'musketeers',
              ownerId: 'player2',
              locationProvinceId: '$ow|P2',
            ),
            Unit(
              id: 'u4',
              type: 'pikemen',
              ownerId: 'player1',
              locationProvinceId: '$ow|P2',
            ),
          ],
        ),
      );

      final orders = Orders(
        moveOrdersByPlayerId: {
          'player1': [
            landConflictMoveOrder(unitId: 'u1', provinceId: '$ow|P1'),
          ],
          'player2': [
            landConflictMoveOrder(unitId: 'u3', provinceId: '$ow|P2'),
          ],
        },
      );

      final battles = detectConflicts(game, orders);

      expect(battles.length, 2);
      expect(battles.map((b) => b.provinceId).toList()..sort(), [
        'oldWorld|P1',
        'oldWorld|P2',
      ]);
      expect(
        battles
            .firstWhere((b) => b.provinceId == 'oldWorld|P1')
            .defenderFactionId,
        'player2',
      );
      expect(
        battles
            .firstWhere((b) => b.provinceId == 'oldWorld|P2')
            .defenderFactionId,
        'player1',
      );
    },
  ),
];
