import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'support/suggestion/valid_work_tiles_test_support.dart';

void main() {
  group('getValidWorkOrderTileKeys', () {
    test('suggestMoveOrders excludes moves to other Great Power provinces', () {
      const otherGpId = 'gp2';
      final player = ValidWorkTilesTestSupport.defaultPlayer;
      final otherGp = const Player(
        id: otherGpId,
        displayName: 'Other GP',
        isHuman: false,
      );

      final p1 = Province(
        id: ValidWorkTilesTestSupport.provinceId('p1'),
        regionId: ValidWorkTilesTestSupport.ow,
        ownerId: ValidWorkTilesTestSupport.playerId,
      );
      final p2 = Province(
        id: ValidWorkTilesTestSupport.provinceId('p2'),
        regionId: ValidWorkTilesTestSupport.ow,
        ownerId: otherGpId,
      );
      final unit = ValidWorkTilesTestSupport.builderUnit(
        locationProvinceId: ValidWorkTilesTestSupport.provinceId('p1'),
      );

      final world = WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
        oldWorld: RegionData(provinces: [p1, p2], units: [unit]),
        newWorld: const RegionData(),
        playerVisibilityByTile: const {
          ValidWorkTilesTestSupport.playerId: {
            'oldWorld|p1|0|0': 'fullyVisible',
            'oldWorld|p2|0|0': 'fullyVisible',
          },
        },
      );
      final game = Game(
        id: 'g1',
        worldState: world,
        players: [player, otherGp],
      );
      final topology = MapTopology(
        nodes: const [
          TopologyNode(
            id: 'p1',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
          TopologyNode(
            id: 'p2',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
        ],
        edges: const [TopologyEdge(id1: 'p1', id2: 'p2')],
      );

      final view = buildPlayerView(
        game,
        topology,
        ValidWorkTilesTestSupport.playerId,
      );
      final suggestions = suggestMoveOrders(
        view,
        game,
        topology,
        const Orders(),
      );
      expect(
        suggestions.where(
          (m) =>
              Unit.provinceIdFromTileKey(m.destinationTileKey) ==
              ValidWorkTilesTestSupport.provinceId('p2'),
        ),
        isEmpty,
      );
    });
  });
}
