import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'support/suggestion/valid_work_tiles_test_support.dart';

void main() {
  group('getValidWorkOrderTileKeys', () {
    test(
      'suggestWorkOrders sorts by targetTileKey when unitId and target match',
      () {
        final p1 = ValidWorkTilesTestSupport.provinceId('p1');
        final tile0 = ValidWorkTilesTestSupport.tileKey('p1', 0, 0);
        final tile1 = ValidWorkTilesTestSupport.tileKey('p1', 1, 0);
        final tile2 = ValidWorkTilesTestSupport.tileKey('p1', 2, 0);

        final province = Province(
          id: p1,
          regionId: ValidWorkTilesTestSupport.ow,
          ownerId: ValidWorkTilesTestSupport.playerId,
        );
        final builder = ValidWorkTilesTestSupport.builderUnit(
          locationProvinceId: p1,
          tileKey: tile0,
        );

        final world = WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(provinces: [province], units: [builder]),
          newWorld: const RegionData(),
          playerVisibilityByTile: {
            ValidWorkTilesTestSupport.playerId: {
              tile0: 'fullyVisible',
              tile1: 'fullyVisible',
              tile2: 'fullyVisible',
            },
          },
          tileKeysByRegionAndProvince:
              ValidWorkTilesTestSupport.tileKeysByProvince(
            {p1: [tile0, tile1, tile2]},
          ),
          resourceByTileKey: {tile0: 'grain', tile1: 'grain', tile2: 'grain'},
          tileState: TileMapState(
            improvementByTile: {tile0: 0, tile1: 0, tile2: 0},
          ),
        );

        final game = Game(
          id: 'g1',
          worldState: world,
          players: [ValidWorkTilesTestSupport.playerWithTreasury()],
        );
        final topology = MapTopology(
          nodes: const [
            TopologyNode(
              id: 'p1',
              regionId: 'oldWorld',
              type: TopologyNodeType.province,
            ),
          ],
          edges: const [],
        );

        final view = buildPlayerView(
          game,
          topology,
          ValidWorkTilesTestSupport.playerId,
        );
        final suggestions = suggestWorkOrders(
          view,
          game,
          topology,
          const Orders(),
        );
        final buildSuggestions = suggestions
            .where((o) => o.target == kWorkTargetBuildImprovement)
            .toList();

        if (buildSuggestions.length > 1) {
          for (int i = 0; i < buildSuggestions.length - 1; i++) {
            expect(
              buildSuggestions[i].targetTileKey.compareTo(
                buildSuggestions[i + 1].targetTileKey,
              ),
              lessThanOrEqualTo(0),
            );
          }
        }
      },
    );

    test(
      'suggestWorkOrders excludes targets from existing work orders for same unit',
      () {
        final p1 = ValidWorkTilesTestSupport.provinceId('p1');
        final tile0 = ValidWorkTilesTestSupport.tileKey('p1', 0, 0);
        final tile1 = ValidWorkTilesTestSupport.tileKey('p1', 1, 0);

        final province = Province(
          id: p1,
          regionId: ValidWorkTilesTestSupport.ow,
          ownerId: ValidWorkTilesTestSupport.playerId,
        );
        final builder = ValidWorkTilesTestSupport.builderUnit(
          locationProvinceId: p1,
          tileKey: tile0,
        );
        final existingOrder = WorkOrder(
          unitId: 'u1',
          target: kWorkTargetBuildImprovement,
          targetTileKey: tile0,
        );

        final world = WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(provinces: [province], units: [builder]),
          newWorld: const RegionData(),
          playerVisibilityByTile: {
            ValidWorkTilesTestSupport.playerId: {
              tile0: 'fullyVisible',
              tile1: 'fullyVisible',
            },
          },
          tileKeysByRegionAndProvince:
              ValidWorkTilesTestSupport.tileKeysByProvince(
            {p1: [tile0, tile1]},
          ),
          resourceByTileKey: {tile0: 'grain', tile1: 'grain'},
          tileState: TileMapState(
            improvementByTile: {tile0: 0, tile1: 0},
          ),
        );

        final game = Game(
          id: 'g1',
          worldState: world,
          players: [ValidWorkTilesTestSupport.playerWithTreasury()],
        );
        final topology = MapTopology(
          nodes: const [
            TopologyNode(
              id: 'p1',
              regionId: 'oldWorld',
              type: TopologyNodeType.province,
            ),
          ],
          edges: const [],
        );

        final view = buildPlayerView(
          game,
          topology,
          ValidWorkTilesTestSupport.playerId,
        );
        final currentOrders = Orders(
          workOrdersByPlayerId: {
            ValidWorkTilesTestSupport.playerId: [existingOrder],
          },
        );
        final suggestions = suggestWorkOrders(
          view,
          game,
          topology,
          currentOrders,
        );

        final buildSuggestions = suggestions
            .where(
              (o) =>
                  o.target == kWorkTargetBuildImprovement &&
                  o.targetTileKey == tile0,
            )
            .toList();
        expect(buildSuggestions, isEmpty);
      },
    );
  });
}
