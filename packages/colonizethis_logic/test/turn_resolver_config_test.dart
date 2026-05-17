import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'test_fixtures.dart';

void main() {
  group('resolveTurnForGameWithConfig', () {
    test('matches resolveTurnForGame for same inputs', () {
      final topology = MapTopology(
        nodes: [
          const TopologyNode(
            id: 'P1',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
          const TopologyNode(
            id: 'P2',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
        ],
        edges: [const TopologyEdge(id1: 'P1', id2: 'P2')],
      );

      const ow = 'oldWorld';
      final game = TestFixtures.minimalGame(
        id: 'g1',
        turnNumber: 0,
        players: const [Player(id: 'p1', displayName: 'A', isHuman: true)],
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
      );

      final orders = Orders(
        moveOrdersByPlayerId: {
          'p1': [MoveOrder(unitId: 'u1', destinationTileKey: '$ow|P2|0|0')],
        },
      );

      final extractedByPlayerId = {
        'p1': {'grain': 3},
      };

      final named = requireTurnResolutionComplete(
        resolveTurnForGame(
          game: game,
          topology: topology,
          orders: orders,
          extractedByPlayerId: extractedByPlayerId,
          defaultAssignments: const [],
        ),
      );

      final withConfig = requireTurnResolutionComplete(
        resolveTurnForGameWithConfig(
          game: game,
          config: TurnResolverConfig(
            topology: topology,
            orders: orders,
            extractedByPlayerId: extractedByPlayerId,
            defaultAssignments: const [],
          ),
        ),
      );

      expect(
        withConfig.worldState.turnState.turnNumber,
        named.worldState.turnState.turnNumber,
      );
      expect(
        withConfig.worldState.oldWorld.units.single.locationProvinceId,
        named.worldState.oldWorld.units.single.locationProvinceId,
      );
      expect(
        withConfig.players.single.stockpile.quantityOf('grain'),
        named.players.single.stockpile.quantityOf('grain'),
      );
    });
  });
}
