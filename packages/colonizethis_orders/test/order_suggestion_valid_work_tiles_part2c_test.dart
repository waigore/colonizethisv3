import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('getValidWorkOrderTileKeys', () {
    test(
      'suggestWorkOrders sorts by targetTileKey when unitId and target match',
      () {
        const playerId = 'gp1';
        const ow = 'oldWorld';

        final player = Player(
          id: playerId,
          displayName: 'GP',
          isHuman: false,
          treasury: 500,
        );
        final province = Province(
          id: '$ow|p1',
          regionId: ow,
          ownerId: playerId,
        );
        final builder = Unit(
          id: 'u1',
          type: kUnitTypeBuilder,
          ownerId: playerId,
          locationProvinceId: '$ow|p1',
          tileKey: 'oldWorld|p1|0|0',
        );

        final world = WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(provinces: [province], units: [builder]),
          newWorld: const RegionData(),
          playerVisibilityByTile: const {
            playerId: {
              'oldWorld|p1|0|0': 'fullyVisible',
              'oldWorld|p1|1|0': 'fullyVisible',
              'oldWorld|p1|2|0': 'fullyVisible',
            },
          },
          tileKeysByRegionAndProvince: {
            ow: {
              '$ow|p1': [
                'oldWorld|p1|0|0',
                'oldWorld|p1|1|0',
                'oldWorld|p1|2|0',
              ],
            },
          },
          resourceByTileKey: {
            'oldWorld|p1|0|0': 'grain',
            'oldWorld|p1|1|0': 'grain',
            'oldWorld|p1|2|0': 'grain',
          },
          tileState: TileMapState(
            improvementByTile: {
              'oldWorld|p1|0|0': 0,
              'oldWorld|p1|1|0': 0,
              'oldWorld|p1|2|0': 0,
            },
          ),
        );

        final game = Game(id: 'g1', worldState: world, players: [player]);
        final topology = const MapTopology(
          nodes: [
            TopologyNode(
              id: 'p1',
              regionId: 'oldWorld',
              type: TopologyNodeType.province,
            ),
          ],
          edges: [],
        );

        final view = buildPlayerView(game, topology, playerId);
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
        const playerId = 'gp1';
        const ow = 'oldWorld';

        final player = Player(
          id: playerId,
          displayName: 'GP',
          isHuman: false,
          treasury: 500,
        );
        final province = Province(
          id: '$ow|p1',
          regionId: ow,
          ownerId: playerId,
        );
        final builder = Unit(
          id: 'u1',
          type: kUnitTypeBuilder,
          ownerId: playerId,
          locationProvinceId: '$ow|p1',
          tileKey: 'oldWorld|p1|0|0',
        );
        final existingOrder = WorkOrder(
          unitId: 'u1',
          target: kWorkTargetBuildImprovement,
          targetTileKey: 'oldWorld|p1|0|0',
        );

        final world = WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(provinces: [province], units: [builder]),
          newWorld: const RegionData(),
          playerVisibilityByTile: const {
            playerId: {
              'oldWorld|p1|0|0': 'fullyVisible',
              'oldWorld|p1|1|0': 'fullyVisible',
            },
          },
          tileKeysByRegionAndProvince: {
            ow: {
              '$ow|p1': ['oldWorld|p1|0|0', 'oldWorld|p1|1|0'],
            },
          },
          resourceByTileKey: {
            'oldWorld|p1|0|0': 'grain',
            'oldWorld|p1|1|0': 'grain',
          },
          tileState: TileMapState(
            improvementByTile: {'oldWorld|p1|0|0': 0, 'oldWorld|p1|1|0': 0},
          ),
        );

        final game = Game(id: 'g1', worldState: world, players: [player]);
        final topology = const MapTopology(
          nodes: [
            TopologyNode(
              id: 'p1',
              regionId: 'oldWorld',
              type: TopologyNodeType.province,
            ),
          ],
          edges: [],
        );

        final view = buildPlayerView(game, topology, playerId);
        final currentOrders = Orders(
          workOrdersByPlayerId: {
            playerId: [existingOrder],
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
                  o.targetTileKey == 'oldWorld|p1|0|0',
            )
            .toList();
        expect(buildSuggestions, isEmpty);
      },
    );
  });
}
