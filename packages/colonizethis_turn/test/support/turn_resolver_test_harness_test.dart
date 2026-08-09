import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'turn_resolver_test_harness.dart';

void main() {
  group('turn_resolver_test_harness', () {
    test('twoAdjacentOldWorldProvinceTopology wires P1–P2 edge', () {
      final topology = twoAdjacentOldWorldProvinceTopology();
      expect(topology.nodes.length, 2);
      expect(topology.edges.single.id1, 'P1');
      expect(topology.edges.single.id2, 'P2');
    });

    test('twoAdjacentOldWorldProvinceTopology can omit the edge', () {
      final topology = twoAdjacentOldWorldProvinceTopology(adjacent: false);
      expect(topology.nodes.length, 2);
      expect(topology.edges, isEmpty);
    });

    test('turnTestOwProvinceStacksFixture builds mass-province OW maps', () {
      final fixture = turnTestOwProvinceStacksFixture(
        stacks: [
          (ownerId: 'p1', count: 2, localIdPrefix: 'A'),
          (ownerId: 'p2', count: 1, localIdPrefix: 'B'),
        ],
        turnNumber: 4,
      );
      expect(fixture.game.worldState.oldWorld.provinces.length, 3);
      expect(fixture.topology.nodes.length, 3);
      expect(fixture.game.worldState.turnState.turnNumber, 4);
    });

    test('adjacentOwP1P2Game builds split-ownership OW stack', () {
      const ow = turnTestOldWorldRegionId;
      final game = adjacentOwP1P2Game(
        units: [
          Unit(
            id: 'u1',
            type: 'Regiment',
            ownerId: 'p1',
            locationProvinceId: '$ow|P1',
          ),
        ],
      );
      expect(game.worldState.oldWorld.provinces.length, 2);
      expect(game.worldState.oldWorld.provinces[0].ownerId, 'p1');
      expect(game.worldState.oldWorld.provinces[1].ownerId, 'p2');
      expect(game.worldState.newWorld.provinces, isEmpty);
      expect(game.worldState.oldWorld.units.single.id, 'u1');
      expect(game.players.length, 2);
    });

    test('adjacentOwP1P2Game can own both provinces and wrap armies', () {
      const ow = turnTestOldWorldRegionId;
      final withoutArmies = adjacentOwP1P2Game(
        province1OwnerId: 'p1',
        province2OwnerId: 'p1',
        units: [
          Unit(
            id: 'u1',
            type: 'grenadiers',
            ownerId: 'p1',
            locationProvinceId: '$ow|P1',
          ),
        ],
        players: const [Player(id: 'p1', displayName: 'A', isHuman: true)],
      );
      final game = adjacentOwP1P2Game(
        province1OwnerId: 'p1',
        province2OwnerId: 'p1',
        ensureMilitaryArmies: true,
        units: [
          Unit(
            id: 'u1',
            type: 'grenadiers',
            ownerId: 'p1',
            locationProvinceId: '$ow|P1',
          ),
        ],
        players: const [Player(id: 'p1', displayName: 'A', isHuman: true)],
      );
      expect(
        game.worldState.oldWorld.provinces.every((p) => p.ownerId == 'p1'),
        isTrue,
      );
      expect(game.players.single.id, 'p1');
      expect(withoutArmies.worldState.armies, isEmpty);
      expect(game.worldState.armies, isNotEmpty);
    });

    test('turnTestOwTileKey builds 1x1 OW tile keys', () {
      expect(turnTestOwTileKey('P2'), 'oldWorld|P2|0|0');
      expect(turnTestNwTileKey('N1'), 'newWorld|N1|0|0');
    });

    test('turnTestCarrackFleet builds standard naval fixture', () {
      final fleet = turnTestCarrackFleet(
        seaZoneId: null,
        inPortAtProvinceId: 'oldWorld|P1',
        shipTypeIds: const ['fluyte'],
      );
      expect(fleet.shipTypeIds, ['fluyte']);
      expect(fleet.inPortAtProvinceId, 'oldWorld|P1');
      expect(fleet.seaZoneId, isNull);
    });

    test('resolveTurnComplete advances turn with minimal move order', () {
      const ow = turnTestOldWorldRegionId;
      final topology = twoAdjacentOldWorldProvinceTopology();
      final game = adjacentOwP1P2Game(
        province1OwnerId: 'p1',
        province2OwnerId: 'p1',
        units: [
          Unit(
            id: 'u1',
            type: 'Regiment',
            ownerId: 'p1',
            locationProvinceId: '$ow|P1',
          ),
        ],
        players: const [Player(id: 'p1', displayName: 'A', isHuman: true)],
      );
      final orders = Orders(
        moveOrdersByPlayerId: {
          'p1': [MoveOrder(unitId: 'u1', destinationTileKey: '$ow|P2|0|0')],
        },
      );

      final next = resolveTurnComplete(
        game: game,
        topology: topology,
        orders: orders,
        extractedByPlayerId: const {
          'p1': {'grain': 2},
        },
      );

      expect(next.worldState.turnState.turnNumber, 1);
      expect(
        next.worldState.oldWorld.units.single.locationProvinceId,
        '$ow|P2',
      );
      expect(next.players.single.stockpile.quantityOf('grain'), 2);
    });
  });
}
