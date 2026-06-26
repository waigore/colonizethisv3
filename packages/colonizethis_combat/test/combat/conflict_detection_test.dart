import 'package:colonizethis_test/game_test_fixtures.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('detectConflicts', () {
    test('returns one battle when two factions in same province', () {
      const ow = 'oldWorld';
      final game = TestFixtures.minimalGame(
        id: 'g1',
        players: [
          Player(id: 'player1', displayName: 'P1', isHuman: true),
          Player(id: 'player2', displayName: 'P2', isHuman: true),
        ],
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
            MoveOrder(unitId: 'u1', destinationTileKey: '$ow|P1|0|0'),
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
    });

    test('detects conflict in newWorld when two factions and move order', () {
      const nw = 'newWorld';
      final game = TestFixtures.minimalGame(
        id: 'g1',
        players: [
          Player(id: 'p1', displayName: 'P1', isHuman: true),
          Player(id: 'p2', displayName: 'P2', isHuman: true),
        ],
        newWorld: RegionData(
          provinces: [
            Province(id: '$nw|N1', regionId: nw, ownerId: 'p2'),
          ],
          units: [
            Unit(id: 'u1', type: 'musketeers', ownerId: 'p1', locationProvinceId: '$nw|N1'),
            Unit(id: 'u2', type: 'pikemen', ownerId: 'p2', locationProvinceId: '$nw|N1'),
          ],
        ),
      );
      final orders = Orders(
        moveOrdersByPlayerId: {
          'p1': [MoveOrder(unitId: 'u1', destinationTileKey: '$nw|N1|0|0')],
        },
      );
      final battles = detectConflicts(game, orders);
      expect(battles.length, 1);
      expect(battles[0].regionId, nw);
      expect(battles[0].provinceId, '$nw|N1');
    });

    test('returns no battle when only one faction in province', () {
      const ow = 'oldWorld';
      final game = TestFixtures.minimalGame(
        id: 'g1',
        players: [
          Player(id: 'player1', displayName: 'P1', isHuman: true),
        ],
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

      final orders = Orders();

      final battles = detectConflicts(game, orders);

      expect(battles, isEmpty);
    });

    test('multiple provinces with conflicts return multiple battles', () {
      const ow = 'oldWorld';
      final game = TestFixtures.minimalGame(
        id: 'g1',
        players: [
          Player(id: 'player1', displayName: 'P1', isHuman: true),
          Player(id: 'player2', displayName: 'P2', isHuman: true),
        ],
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
            MoveOrder(unitId: 'u1', destinationTileKey: '$ow|P1|0|0'),
          ],
          'player2': [
            MoveOrder(unitId: 'u3', destinationTileKey: '$ow|P2|0|0'),
          ],
        },
      );

      final battles = detectConflicts(game, orders);

      expect(battles.length, 2);
      expect(
        battles.map((b) => b.provinceId).toList()..sort(),
        ['oldWorld|P1', 'oldWorld|P2'],
      );
      expect(battles.firstWhere((b) => b.provinceId == 'oldWorld|P1').defenderFactionId, 'player2');
      expect(battles.firstWhere((b) => b.provinceId == 'oldWorld|P2').defenderFactionId, 'player1');
    });

    test('civilians alone do not trigger battles', () {
      const ow = 'oldWorld';
      final game = TestFixtures.minimalGame(
        id: 'g1',
        players: [
          Player(id: 'player1', displayName: 'P1', isHuman: true),
          Player(id: 'player2', displayName: 'P2', isHuman: true),
        ],
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
            MoveOrder(unitId: 'u1', destinationTileKey: '$ow|P1|0|0'),
          ],
        },
      );

      final battles = detectConflicts(game, orders);
      expect(battles, isEmpty);
    });

    test('unowned province: defender is non-mover when two factions present', () {
      const ow = 'oldWorld';
      final game = TestFixtures.minimalGame(
        id: 'g1',
        players: [
          Player(id: 'p1', displayName: 'P1', isHuman: true),
          Player(id: 'p2', displayName: 'P2', isHuman: true),
        ],
        oldWorld: RegionData(
          provinces: [
            Province(id: '$ow|P1', regionId: ow),
          ],
          units: [
            Unit(id: 'u1', type: 'musketeers', ownerId: 'p1', locationProvinceId: '$ow|P1'),
            Unit(id: 'u2', type: 'pikemen', ownerId: 'p2', locationProvinceId: '$ow|P1'),
          ],
        ),
      );
      final orders = Orders(
        moveOrdersByPlayerId: {
          'p1': [MoveOrder(unitId: 'u1', destinationTileKey: '$ow|P1|0|0')],
        },
      );
      final battles = detectConflicts(game, orders);
      expect(battles.length, 1);
      expect(battles[0].defenderFactionId, 'p2');
      expect(battles[0].attackers.length, 1);
      expect(battles[0].attackers[0].factionId, 'p1');
    });

    test('unowned province: defender is lexicographically first when all moved in', () {
      const ow = 'oldWorld';
      final game = TestFixtures.minimalGame(
        id: 'g1',
        players: [
          Player(id: 'p1', displayName: 'P1', isHuman: true),
          Player(id: 'p2', displayName: 'P2', isHuman: true),
        ],
        oldWorld: RegionData(
          provinces: [
            Province(id: '$ow|P1', regionId: ow),
          ],
          units: [
            Unit(id: 'u1', type: 'musketeers', ownerId: 'p1', locationProvinceId: '$ow|P1'),
            Unit(id: 'u2', type: 'pikemen', ownerId: 'p2', locationProvinceId: '$ow|P1'),
          ],
        ),
      );
      final orders = Orders(
        moveOrdersByPlayerId: {
          'p1': [MoveOrder(unitId: 'u1', destinationTileKey: '$ow|P1|0|0')],
          'p2': [MoveOrder(unitId: 'u2', destinationTileKey: '$ow|P1|0|0')],
        },
      );
      final battles = detectConflicts(game, orders);
      expect(battles.length, 1);
      expect(battles[0].defenderFactionId, 'p1');
    });

    test('returns no battles when oldWorld has no units', () {
      const nw = 'newWorld';
      final game = TestFixtures.minimalGame(
        id: 'g1',
        players: [
          Player(id: 'p1', displayName: 'P1', isHuman: true),
          Player(id: 'p2', displayName: 'P2', isHuman: true),
        ],
        newWorld: RegionData(
          provinces: [
            Province(id: '$nw|N1', regionId: nw, ownerId: 'p2'),
          ],
          units: [
            Unit(id: 'u1', type: 'musketeers', ownerId: 'p1', locationProvinceId: '$nw|N1'),
            Unit(id: 'u2', type: 'pikemen', ownerId: 'p2', locationProvinceId: '$nw|N1'),
          ],
        ),
      );
      final orders = Orders(
        moveOrdersByPlayerId: {
          'p1': [MoveOrder(unitId: 'u1', destinationTileKey: '$nw|N1|0|0')],
        },
      );
      final battles = detectConflicts(game, orders);
      expect(battles.length, 1);
      expect(battles[0].regionId, nw);
    });

    test('army move order contributes moved-in attacker detection', () {
      const ow = 'oldWorld';
      final p1 = '$ow|P1';
      final game = TestFixtures.minimalGame(
        id: 'g_army',
        players: [
          Player(id: 'player1', displayName: 'P1', isHuman: true),
          Player(id: 'player2', displayName: 'P2', isHuman: true),
        ],
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
    });

  });
}
