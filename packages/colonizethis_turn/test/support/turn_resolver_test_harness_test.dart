import 'package:colonizethis_data/colonizethis_data.dart';
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

    test('resolveTurnComplete advances turn with minimal move order', () {
      const ow = turnTestOldWorldRegionId;
      final topology = twoAdjacentOldWorldProvinceTopology();
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: RegionData(
            provinces: [
              Province(id: '$ow|P1', regionId: ow, ownerId: 'p1'),
              Province(id: '$ow|P2', regionId: ow, ownerId: 'p1'),
            ],
            units: [
              Unit(
                id: 'u1',
                type: 'Regiment',
                ownerId: 'p1',
                locationProvinceId: '$ow|P1',
              ),
            ],
          ),
          newWorld: const RegionData(),
        ),
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
