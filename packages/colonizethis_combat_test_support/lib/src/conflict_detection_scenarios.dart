// Table-driven land conflict-detection scenarios (Refs #3865).

import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'conflict_detection_test_support.dart';

/// One row in a land conflict-detection scenario table.
class ConflictDetectionScenario {
  const ConflictDetectionScenario({
    required this.scenarioId,
    required this.label,
    required this.run,
  });

  final String scenarioId;
  final String label;
  final void Function() run;
}

/// Runs [scenario] (setup + assertions live in [ConflictDetectionScenario.run]).
void runConflictDetectionScenario(ConflictDetectionScenario scenario) {
  scenario.run();
}

List<ConflictDetectionScenario> detectConflictsScenarios() => [
  ..._detectConflictsCoreScenarios(),
  ..._detectConflictsOwnershipScenarios(),
  ..._detectConflictsOrderScenarios(),
];

List<ConflictDetectionScenario> _detectConflictsCoreScenarios() => [
  ConflictDetectionScenario(
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
  ConflictDetectionScenario(
    scenarioId: 'cd-new-world-conflict',
    label: 'detects conflict in newWorld when two factions and move order',
    run: () {
      const nw = 'newWorld';
      final game = landConflictTwoPlayerGame(
        id: 'g1',
        players: landConflictShortPlayers,
        newWorld: RegionData(
          provinces: [
            Province(id: '$nw|N1', regionId: nw, ownerId: 'p2'),
          ],
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
  ConflictDetectionScenario(
    scenarioId: 'cd-single-faction',
    label: 'returns no battle when only one faction in province',
    run: () {
      const ow = 'oldWorld';
      final game = landConflictTwoPlayerGame(
        id: 'g1',
        players: [landConflictTestPlayers[0]],
        oldWorld: RegionData(
          provinces: [
            Province(id: '$ow|P1', regionId: ow, ownerId: 'player1'),
          ],
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
  ConflictDetectionScenario(
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
      expect(
        battles.map((b) => b.provinceId).toList()..sort(),
        ['oldWorld|P1', 'oldWorld|P2'],
      );
      expect(
        battles.firstWhere((b) => b.provinceId == 'oldWorld|P1').defenderFactionId,
        'player2',
      );
      expect(
        battles.firstWhere((b) => b.provinceId == 'oldWorld|P2').defenderFactionId,
        'player1',
      );
    },
  ),
];

List<ConflictDetectionScenario> _detectConflictsOwnershipScenarios() => [
  ConflictDetectionScenario(
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
  ConflictDetectionScenario(
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
  ConflictDetectionScenario(
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

List<ConflictDetectionScenario> _detectConflictsOrderScenarios() => [
  ConflictDetectionScenario(
    scenarioId: 'cd-new-world-only-units',
    label: 'returns no battles when oldWorld has no units',
    run: () {
      const nw = 'newWorld';
      final game = landConflictTwoPlayerGame(
        id: 'g1',
        players: landConflictShortPlayers,
        newWorld: RegionData(
          provinces: [
            Province(id: '$nw|N1', regionId: nw, ownerId: 'p2'),
          ],
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
  ConflictDetectionScenario(
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
