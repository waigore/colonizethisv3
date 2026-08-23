/// Crafted connectivity chain scenarios for multi-turn civilian-work pins (Refs #4176).
library;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';

import 'connectivity_dev_chain_fixture_reconquest.dart';

const String kConnectivityDevChainOw = 'oldWorld';
const String kConnectivityDevChainPlayerId = 'gp1';
const String kConnectivityDevChainEngineerId = 'e1';

/// Horizontal chain scenario: capital road at x=0, optional improved resources,
/// idle Engineer, materials for repeated `build_road`.
class ConnectivityDevChainFixture {
  ConnectivityDevChainFixture({
    required this.game,
    required this.topology,
    required this.tileMapByRegion,
    required this.resourceTiles,
    required this.expectedFrontierRoadTiles,
  });

  final Game game;
  final MapTopology topology;
  final Map<String, TileMapResult> tileMapByRegion;
  final List<String> resourceTiles;
  final List<String> expectedFrontierRoadTiles;

  static String tileKey(String provinceId, int x) => '$provinceId|$x|0';

  /// AC-A1: improved resource three owned tiles beyond the capital network.
  static ConnectivityDevChainFixture threeTileGap() {
    const p1 = '$kConnectivityDevChainOw|p1';
    const width = 5;
    final grid = [List.generate(width, (_) => 'p1')];
    final tileMap = TileMapResult(width: width, height: 1, grid: grid);
    final tiles = [for (var x = 0; x < width; x++) tileKey(p1, x)];
    final capTile = tileKey(p1, 0);
    final resourceTile = tileKey(p1, 4);
    final visibility = {for (final t in tiles) t: 'fullyVisible'};
    final game = TestFixtures.minimalGame(
      players: [
        Player(
          id: kConnectivityDevChainPlayerId,
          displayName: 'GP',
          isHuman: false,
          capitalProvinceId: p1,
          capitalTile: CapitalTile(
            regionId: kConnectivityDevChainOw,
            provinceId: p1,
            x: 0,
            y: 0,
          ),
          stockpile: const Stockpile(
            quantities: {'lumber': 50, 'castIron': 50},
          ),
        ),
      ],
      oldWorld: RegionData(
        provinces: [
          Province(
            id: p1,
            regionId: kConnectivityDevChainOw,
            ownerId: kConnectivityDevChainPlayerId,
          ),
        ],
        units: [
          Unit(
            id: kConnectivityDevChainEngineerId,
            type: kUnitTypeEngineer,
            ownerId: kConnectivityDevChainPlayerId,
            locationProvinceId: p1,
            tileKey: capTile,
          ),
        ],
      ),
      tileKeysByRegionAndProvince: {
        kConnectivityDevChainOw: {p1: tiles},
      },
      playerVisibilityByTile: {kConnectivityDevChainPlayerId: visibility},
      resourceByTileKey: {resourceTile: 'grain'},
      tileState: TileMapState(
        improvementByTile: {resourceTile: 1},
        roadLevelByTile: {capTile: 1},
      ),
    );
    const topology = MapTopology(
      nodes: [
        TopologyNode(
          id: p1,
          regionId: kConnectivityDevChainOw,
          type: TopologyNodeType.province,
        ),
      ],
      edges: [],
    );
    return ConnectivityDevChainFixture(
      game: game,
      topology: topology,
      tileMapByRegion: {kConnectivityDevChainOw: tileMap},
      resourceTiles: [resourceTile],
      expectedFrontierRoadTiles: [
        tileKey(p1, 1),
        tileKey(p1, 2),
        tileKey(p1, 3),
      ],
    );
  }

  /// AC-A6: nearer improved resource at x=2, farther at x=4 on one province row.
  static ConnectivityDevChainFixture dualResourceSequencing() {
    const p1 = '$kConnectivityDevChainOw|p1';
    const width = 5;
    final grid = [List.generate(width, (_) => 'p1')];
    final tileMap = TileMapResult(width: width, height: 1, grid: grid);
    final tiles = [for (var x = 0; x < width; x++) tileKey(p1, x)];
    final capTile = tileKey(p1, 0);
    final nearResource = tileKey(p1, 2);
    final farResource = tileKey(p1, 4);
    final visibility = {for (final t in tiles) t: 'fullyVisible'};
    final game = TestFixtures.minimalGame(
      players: [
        Player(
          id: kConnectivityDevChainPlayerId,
          displayName: 'GP',
          isHuman: false,
          capitalProvinceId: p1,
          capitalTile: CapitalTile(
            regionId: kConnectivityDevChainOw,
            provinceId: p1,
            x: 0,
            y: 0,
          ),
          stockpile: const Stockpile(
            quantities: {'lumber': 80, 'castIron': 80},
          ),
        ),
      ],
      oldWorld: RegionData(
        provinces: [
          Province(
            id: p1,
            regionId: kConnectivityDevChainOw,
            ownerId: kConnectivityDevChainPlayerId,
          ),
        ],
        units: [
          Unit(
            id: kConnectivityDevChainEngineerId,
            type: kUnitTypeEngineer,
            ownerId: kConnectivityDevChainPlayerId,
            locationProvinceId: p1,
            tileKey: capTile,
          ),
        ],
      ),
      tileKeysByRegionAndProvince: {
        kConnectivityDevChainOw: {p1: tiles},
      },
      playerVisibilityByTile: {kConnectivityDevChainPlayerId: visibility},
      resourceByTileKey: {nearResource: 'grain', farResource: 'timber'},
      tileState: TileMapState(
        improvementByTile: {nearResource: 1, farResource: 1},
        roadLevelByTile: {capTile: 1},
      ),
    );
    const topology = MapTopology(
      nodes: [
        TopologyNode(
          id: p1,
          regionId: kConnectivityDevChainOw,
          type: TopologyNodeType.province,
        ),
      ],
      edges: [],
    );
    return ConnectivityDevChainFixture(
      game: game,
      topology: topology,
      tileMapByRegion: {kConnectivityDevChainOw: tileMap},
      resourceTiles: [nearResource, farResource],
      expectedFrontierRoadTiles: const [],
    );
  }

  /// AC-F2: pre-built improvements outside the capital network on a distant tile.
  static ConnectivityDevChainFixture reconquestImprovements() =>
      reconquestImprovementsFixture();
}
