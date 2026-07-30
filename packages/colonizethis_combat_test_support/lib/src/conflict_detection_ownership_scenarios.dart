// Table-driven land conflict-detection scenarios (Refs #3865, #4196 slice B).

import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'conflict_detection_test_support.dart';
import 'scenario_runner.dart';

List<RunnableScenario> detectConflictsOwnershipScenarios() => [
  RunnableScenario(
    scenarioId: 'cd-civilians-no-battle',
    label: 'civilians alone do not trigger battles',
    run: () {
      const ow = 'oldWorld';
      final game = landConflictTwoPlayerGame(
        id: 'g1',
        players: landConflictTestPlayers,
        oldWorld: RegionData(
          provinces: [
            Province(id: '$ow|P1', regionId: ow, ownerId: 'player2'),
          ],
          units: [
            Unit(
              id: 'u1',
              type: kUnitTypeExplorer,
              ownerId: 'player1',
              locationProvinceId: '$ow|P1',
            ),
            Unit(
              id: 'u2',
              type: kUnitTypeBuilder,
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
      expect(battles, isEmpty);
    },
  ),
  RunnableScenario(
    scenarioId: 'cd-unowned-non-mover-defender',
    label: 'unowned province: defender is non-mover when two factions present',
    run: () {
      const ow = 'oldWorld';
      final game = landConflictTwoPlayerGame(
        id: 'g1',
        players: landConflictShortPlayers,
        oldWorld: RegionData(
          provinces: [
            Province(id: '$ow|P1', regionId: ow),
          ],
          units: [
            Unit(
              id: 'u1',
              type: 'musketeers',
              ownerId: 'p1',
              locationProvinceId: '$ow|P1',
            ),
            Unit(
              id: 'u2',
              type: 'pikemen',
              ownerId: 'p2',
              locationProvinceId: '$ow|P1',
            ),
          ],
        ),
      );
      final orders = Orders(
        moveOrdersByPlayerId: {
          'p1': [landConflictMoveOrder(unitId: 'u1', provinceId: '$ow|P1')],
        },
      );
      final battles = detectConflicts(game, orders);
      expect(battles.length, 1);
      expect(battles[0].defenderFactionId, 'p2');
      expect(battles[0].attackers.length, 1);
      expect(battles[0].attackers[0].factionId, 'p1');
    },
  ),
  RunnableScenario(
    scenarioId: 'cd-unowned-lex-first-defender',
    label: 'unowned province: defender is lexicographically first when all moved in',
    run: () {
      const ow = 'oldWorld';
      final game = landConflictTwoPlayerGame(
        id: 'g1',
        players: landConflictShortPlayers,
        oldWorld: RegionData(
          provinces: [
            Province(id: '$ow|P1', regionId: ow),
          ],
          units: [
            Unit(
              id: 'u1',
              type: 'musketeers',
              ownerId: 'p1',
              locationProvinceId: '$ow|P1',
            ),
            Unit(
              id: 'u2',
              type: 'pikemen',
              ownerId: 'p2',
              locationProvinceId: '$ow|P1',
            ),
          ],
        ),
      );
      final orders = Orders(
        moveOrdersByPlayerId: {
          'p1': [landConflictMoveOrder(unitId: 'u1', provinceId: '$ow|P1')],
          'p2': [landConflictMoveOrder(unitId: 'u2', provinceId: '$ow|P1')],
        },
      );
      final battles = detectConflicts(game, orders);
      expect(battles.length, 1);
      expect(battles[0].defenderFactionId, 'p1');
    },
  ),
];
