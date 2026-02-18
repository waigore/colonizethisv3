import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:test/test.dart';

void main() {
  group('Order suggestion', () {
    test('suggestMoveOrders only returns moves that pass validation', () {
      const playerId = 'gp1';
      final player = const Player(
        id: playerId,
        displayName: 'Test GP',
        isHuman: false,
      );

      final p1 = const Province(id: 'p1', regionId: 'oldWorld', ownerId: playerId);
      final p2 = const Province(id: 'p2', regionId: 'oldWorld');

      final unit = const Unit(
        id: 'u1',
        type: 'Explorer',
        ownerId: playerId,
        provinceId: 'p1',
      );

      final world = WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
        oldWorld: RegionData(
          provinces: [p1, p2],
          units: [unit],
        ),
        newWorld: const RegionData(),
        playerVisibilityByTile: const {
          playerId: {
            'oldWorld|p1|0|0': 'fullyVisible',
            'oldWorld|p2|0|0': 'fogged',
          },
        },
      );

      final game = Game(
        id: 'g1',
        worldState: world,
        players: [player],
      );

      final topology = MapTopology(
        nodes: const [
          TopologyNode(id: 'p1', regionId: 'oldWorld', type: TopologyNodeType.province),
          TopologyNode(id: 'p2', regionId: 'oldWorld', type: TopologyNodeType.province),
        ],
        edges: const [
          TopologyEdge(id1: 'p1', id2: 'p2'),
        ],
      );

      final view = buildPlayerView(game, topology, playerId);
      final suggestions = suggestMoveOrders(view, game, topology, const Orders());

      expect(suggestions.length, 1);
      expect(suggestions.first.unitId, 'u1');
      expect(suggestions.first.destinationProvinceId, 'p2');
    });
  });
}

