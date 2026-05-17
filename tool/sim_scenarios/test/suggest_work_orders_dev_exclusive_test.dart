import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

/// SPEC/program/order-suggestions.md § Dev-exclusive reservations; companion to
/// scenarios/civilian_tile_exclusivity_dev.json (order validation).
void main() {
  test(
    'suggestWorkOrders: second Builder does not suggest build_improvement on '
    'tile already in peer pending work order',
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
      final b2Suggestions = suggestions
          .where((o) => o.unitId == 'b2' && o.target == kWorkTargetBuildImprovement);
      expect(b2Suggestions, isNotEmpty);
      expect(b2Suggestions.first.targetTileKey, tileB);
    });
}
