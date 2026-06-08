import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('Order suggestion', () {
    test('getValidWorkOrderTileKeysWithVisibility excludes tile reserved by '
        'another unit pending order', () {
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
      final topology = const MapTopology(nodes: [], edges: []);
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
      final validB2 = getValidWorkOrderTileKeysWithVisibility(
        game: game,
        topology: topology,
        view: view,
        unitId: 'b2',
        workTarget: kWorkTargetBuildImprovement,
        currentOrders: orders,
      );
      expect(validB2, isNot(contains(tileA)));
      expect(validB2, contains(tileB));
    });
  });
}
