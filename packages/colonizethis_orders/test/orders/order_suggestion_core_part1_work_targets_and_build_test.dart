import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('Order suggestion', () {
    test(
      'work suggestions for worker use unit id; targets may be any valid tile',
      () {
        const playerId = 'gp1';
        const ow = 'oldWorld';
        final player = Player(
          id: playerId,
          displayName: 'GP',
          isHuman: false,
          treasury: 500,
          stockpile: Stockpile(quantities: {'lumber': 10, 'castIron': 10}),
        );
        final p1 = Province(id: '$ow|p1', regionId: ow, ownerId: playerId);
        final unit = Unit(
          id: 'u1',
          type: kUnitTypeBuilder,
          ownerId: playerId,
          locationProvinceId: '$ow|p1',
        );
        final world = WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(provinces: [p1], units: [unit]),
          newWorld: const RegionData(),
          playerVisibilityByTile: const {
            playerId: {'oldWorld|p1|0|0': 'fullyVisible'},
          },
          tileKeysByRegionAndProvince: {
            ow: {
              '$ow|p1': ['oldWorld|p1|0|0'],
            },
          },
        );
        final game = Game(id: 'g1', worldState: world, players: [player]);
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
        final view = buildPlayerView(game, topology, playerId);
        final suggestions = suggestWorkOrders(
          view,
          game,
          topology,
          const Orders(),
        );
        // All suggested work orders are for u1, which is in p1; no order targets another province.
        for (final o in suggestions) {
          expect(o.unitId, 'u1');
          final u = view.ownUnitsById[o.unitId];
          expect(u, isNotNull);
          expect(u!.locationProvinceId, 'oldWorld|p1');
        }
      },
    );

    test(
      'suggestWorkOrders includes build_improvement when first province tile '
      'has no resource but a later tile does',
      () {
        const playerId = 'gp1';
        const ow = 'oldWorld';
        const tileNoResource = 'oldWorld|p1|0|0';
        const tileWithResource = 'oldWorld|p1|1|0';
        final player = Player(
          id: playerId,
          displayName: 'GP',
          isHuman: false,
          stockpile: Stockpile(quantities: {'lumber': 10, 'castIron': 10}),
        );
        final p1 = Province(id: '$ow|p1', regionId: ow, ownerId: playerId);
        final unit = Unit(
          id: 'u1',
          type: kUnitTypeBuilder,
          ownerId: playerId,
          locationProvinceId: '$ow|p1',
          tileKey: tileNoResource,
        );
        final world = WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(provinces: [p1], units: [unit]),
          newWorld: const RegionData(),
          playerVisibilityByTile: {
            playerId: {
              tileNoResource: 'fullyVisible',
              tileWithResource: 'fullyVisible',
            },
          },
          tileKeysByRegionAndProvince: {
            ow: {
              '$ow|p1': [tileNoResource, tileWithResource],
            },
          },
          resourceByTileKey: {tileWithResource: 'grain'},
          tileState: TileMapState(improvementByTile: {tileWithResource: 0}),
        );
        final game = Game(id: 'g1', worldState: world, players: [player]);
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
        final view = buildPlayerView(game, topology, playerId);
        final suggestions = suggestWorkOrders(
          view,
          game,
          topology,
          const Orders(),
        );
        final buildImp = suggestions.where(
          (o) => o.target == kWorkTargetBuildImprovement,
        );
        expect(buildImp, isNotEmpty);
        expect(
          buildImp.first.targetTileKey,
          tileWithResource,
          reason: 'should pick first valid tile, not the empty-resource tile',
        );
      },
    );

    test(
      'suggestWorkOrders includes build_improvement on another owned province '
      'when the builder’s province has no valid resource tile',
      () {
        const playerId = 'gp1';
        const ow = 'oldWorld';
        const tileP1 = 'oldWorld|p1|0|0';
        const tileP2 = 'oldWorld|p2|0|0';
        final player = Player(
          id: playerId,
          displayName: 'GP',
          isHuman: false,
          stockpile: Stockpile(quantities: {'lumber': 10, 'castIron': 10}),
        );
        final p1 = Province(id: '$ow|p1', regionId: ow, ownerId: playerId);
        final p2 = Province(id: '$ow|p2', regionId: ow, ownerId: playerId);
        final unit = Unit(
          id: 'u1',
          type: kUnitTypeBuilder,
          ownerId: playerId,
          locationProvinceId: '$ow|p1',
          tileKey: tileP1,
        );
        final world = WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(provinces: [p1, p2], units: [unit]),
          newWorld: const RegionData(),
          playerVisibilityByTile: {
            playerId: {tileP1: 'fullyVisible', tileP2: 'fullyVisible'},
          },
          tileKeysByRegionAndProvince: {
            ow: {
              '$ow|p1': [tileP1],
              '$ow|p2': [tileP2],
            },
          },
          resourceByTileKey: {tileP2: 'grain'},
          tileState: TileMapState(improvementByTile: {tileP2: 0}),
        );
        final game = Game(id: 'g1', worldState: world, players: [player]);
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
          edges: const [],
        );
        final view = buildPlayerView(game, topology, playerId);
        final suggestions = suggestWorkOrders(
          view,
          game,
          topology,
          const Orders(),
        );
        final buildImp = suggestions.where(
          (o) => o.target == kWorkTargetBuildImprovement,
        );
        expect(buildImp, isNotEmpty);
        expect(buildImp.first.targetTileKey, tileP2);
      },
    );

    test(
      'suggestWorkOrders second Builder skips tile reserved by another Builder '
      'pending work order',
      () {
        const playerId = 'gp1';
        const ow = 'oldWorld';
        const tileA = 'oldWorld|p1|0|0';
        const tileB = 'oldWorld|p1|1|0';
        final player = Player(
          id: playerId,
          displayName: 'GP',
          isHuman: false,
          stockpile: Stockpile(quantities: {'lumber': 20, 'castIron': 20}),
        );
        final p1 = Province(id: '$ow|p1', regionId: ow, ownerId: playerId);
        final b1 = Unit(
          id: 'b1',
          type: kUnitTypeBuilder,
          ownerId: playerId,
          locationProvinceId: '$ow|p1',
          tileKey: tileA,
        );
        final b2 = Unit(
          id: 'b2',
          type: kUnitTypeBuilder,
          ownerId: playerId,
          locationProvinceId: '$ow|p1',
          tileKey: tileA,
        );
        final world = WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(provinces: [p1], units: [b1, b2]),
          newWorld: const RegionData(),
          playerVisibilityByTile: {
            playerId: {tileA: 'fullyVisible', tileB: 'fullyVisible'},
          },
          tileKeysByRegionAndProvince: {
            ow: {
              '$ow|p1': [tileA, tileB],
            },
          },
          resourceByTileKey: {tileA: 'grain', tileB: 'grain'},
          tileState: TileMapState(improvementByTile: {tileA: 0, tileB: 0}),
        );
        final game = Game(id: 'g1', worldState: world, players: [player]);
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
        final view = buildPlayerView(game, topology, playerId);
        final orders = Orders(
          workOrdersByPlayerId: {
            playerId: [
              WorkOrder(
                unitId: 'b1',
                target: kWorkTargetBuildImprovement,
                targetTileKey: tileA,
              ),
            ],
          },
        );
        final suggestions = suggestWorkOrders(view, game, topology, orders);
        final b2Build = suggestions
            .where(
              (o) =>
                  o.unitId == 'b2' && o.target == kWorkTargetBuildImprovement,
            )
            .toList();
        expect(b2Build, isNotEmpty);
        expect(b2Build.first.targetTileKey, tileB);
      },
    );
  });
}
