import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/colonizethis_orders.dart';
import 'package:colonizethis_orders/src/orders/connectivity_dev_snapshot.dart';
import 'package:colonizethis_test/test.dart';

/// Panel assign vs worker suggestion tile parity (Refs #4211 Slice B).
void main() {
  test(
    'selectDevelopmentImproveAssignCandidate matches suggestWorkOrders tile',
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
      const orders = Orders();
      final snapshot = buildConnectivityDevSnapshot(
        game: game,
        playerId: playerId,
        topology: topology,
        tileMapByRegion: tileMapByRegion,
      );
      expect(snapshot, isNotNull);
      final connected = snapshot!.connected;

      final assign = selectDevelopmentImproveAssignCandidate(
        game: game,
        playerId: playerId,
        currentOrders: orders,
        topology: topology,
        tileMapByRegion: tileMapByRegion,
        commodityTileKeys: {connectedGrain, farGrain},
        connectedTileKeys: connected,
      );
      expect(assign, isNotNull);

      final view = buildPlayerView(game, topology, playerId);
      final suggestions = suggestWorkOrders(
        view,
        game,
        topology,
        orders,
        tileMapByRegion: tileMapByRegion,
      );
      final improve = suggestions
          .where(
            (o) => o.unitId == 'b1' && o.target == kWorkTargetBuildImprovement,
          )
          .toList();
      expect(improve, hasLength(1));
      expect(assign!.targetTileKey, improve.single.targetTileKey);
    },
  );

  test(
    'orderDevelopmentImproveTiles falls back to SPEC comparator without maps',
    () {
      const ts = TileMapState(
        improvementByTile: {
          'oldWorld|p1|0|0': 1,
          'oldWorld|p1|1|0': 0,
          'oldWorld|p1|2|0': 0,
        },
      );
      const connected = {'oldWorld|p1|0|0', 'oldWorld|p1|1|0'};
      expect(
        orderDevelopmentImproveTiles(
          game: Game(
            id: 'g',
            worldState: WorldState(
              turnState: const TurnState(
                phase: TurnPhase.orders,
                turnNumber: 1,
              ),
              oldWorld: const RegionData(),
              newWorld: const RegionData(),
              tileState: ts,
            ),
            players: const [],
          ),
          playerId: 'gp1',
          tileKeys: const {
            'oldWorld|p1|2|0',
            'oldWorld|p1|0|0',
            'oldWorld|p1|1|0',
          },
          connectedTileKeys: connected,
          tileState: ts,
        ),
        ['oldWorld|p1|1|0', 'oldWorld|p1|0|0', 'oldWorld|p1|2|0'],
      );
    },
  );
}
