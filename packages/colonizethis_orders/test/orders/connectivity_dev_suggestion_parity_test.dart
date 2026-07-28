import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/src/orders/connectivity_dev_snapshot.dart';
import 'package:colonizethis_orders/src/orders/connectivity_dev_targets.dart';
import 'package:colonizethis_orders/src/orders/order_suggestion_work.dart';
import 'package:colonizethis_orders/src/orders/order_work_constants.dart';
import 'package:colonizethis_test/test.dart';

/// Human suggestion parity pin (Refs #4176 AC-F6).
void main() {
  test(
    'suggestWorkOrders applies connectivity ordering for build_improvement',
    () {
      const ow = 'oldWorld';
      const p1 = '$ow|p1';
      const playerId = 'gp1';
      const capTile = '$p1|2|2';
      const connectedGrain = '$p1|0|0';
      const farGrain = '$p1|4|0';
      const grid = [
        ['p1', 'p1', 'p1', 'p1', 'p1'],
        ['p1', 'p1', 'p1', 'p1', 'p1'],
        ['p1', 'p1', 'p1', 'p1', 'p1'],
        ['p1', 'p1', 'p1', 'p1', 'p1'],
        ['p1', 'p1', 'p1', 'p1', 'p1'],
      ];
      final tileMap = TileMapResult(
        width: grid.first.length,
        height: grid.length,
        grid: grid,
      );
      const topology = MapTopology(
        nodes: [
          TopologyNode(
            id: p1,
            regionId: ow,
            type: TopologyNodeType.province,
          ),
        ],
        edges: [],
      );
      final tileState = TileMapState(
        improvementByTile: const {connectedGrain: 0, farGrain: 0},
        roadLevelByTile: {
          capTile: 1,
          '$p1|2|1': 1,
          '$p1|1|1': 1,
          '$p1|1|0': 1,
          connectedGrain: 1,
        },
      );
      final tiles = <String>[
        for (var y = 0; y < 5; y++)
          for (var x = 0; x < 5; x++) '$p1|$x|$y',
      ];
      final game = Game(
        id: 'g',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [Province(id: p1, regionId: ow, ownerId: playerId)],
            units: [
              Unit(
                id: 'b1',
                type: kUnitTypeBuilder,
                ownerId: playerId,
                locationProvinceId: p1,
                tileKey: capTile,
              ),
            ],
          ),
          newWorld: const RegionData(),
          tileKeysByRegionAndProvince: {ow: {p1: tiles}},
          resourceByTileKey: {connectedGrain: 'grain', farGrain: 'grain'},
          tileState: tileState,
          playerVisibilityByTile: {
            playerId: {for (final t in tiles) t: 'fullyVisible'},
          },
        ),
        players: [
          Player(
            id: playerId,
            displayName: 'Human',
            isHuman: true,
            capitalProvinceId: p1,
            capitalTile: CapitalTile(
              regionId: ow,
              provinceId: p1,
              x: 2,
              y: 2,
            ),
            stockpile: const Stockpile(
              quantities: {'lumber': 20, 'castIron': 20},
            ),
          ),
        ],
      );
      final tileMapByRegion = {ow: tileMap};
      final view = buildPlayerView(game, topology, playerId);
      final snapshot = buildConnectivityDevSnapshot(
        game: game,
        playerId: playerId,
        topology: topology,
        tileMapByRegion: tileMapByRegion,
      );
      expect(snapshot, isNotNull);
      expect(snapshot!.connected, contains(connectedGrain));
      expect(snapshot.connected, isNot(contains(farGrain)));

      final rawSorted = [farGrain, connectedGrain]..sort();
      final expectedOrder = prioritizeBuildImprovementCandidatesByConnectivity(
        snapshot: snapshot,
        sortedVisible: rawSorted,
      );
      expect(expectedOrder.first, connectedGrain);

      final suggestions = suggestWorkOrders(
        view,
        game,
        topology,
        const Orders(),
        tileMapByRegion: tileMapByRegion,
      );
      final improve = suggestions
          .where(
            (o) => o.unitId == 'b1' && o.target == kWorkTargetBuildImprovement,
          )
          .toList();
      expect(improve, hasLength(1));
      expect(improve.single.targetTileKey, connectedGrain);
    },
  );
}
