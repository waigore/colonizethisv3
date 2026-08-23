/// Reconquest connectivity-chain fixture (Refs #4176 / #4602 Slice E).
library;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';

import 'connectivity_dev_chain_fixture.dart';

/// AC-F2: pre-built improvements outside the capital network on a distant tile.
ConnectivityDevChainFixture reconquestImprovementsFixture() {
  const p1 = '$kConnectivityDevChainOw|p1';
  const width = 5;
  final grid = [List.generate(width, (_) => 'p1')];
  final tileMap = TileMapResult(width: width, height: 1, grid: grid);
  final tiles = [
    for (var x = 0; x < width; x++) ConnectivityDevChainFixture.tileKey(p1, x),
  ];
  final capTile = ConnectivityDevChainFixture.tileKey(p1, 0);
  final resourceTile = ConnectivityDevChainFixture.tileKey(p1, 4);
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
        stockpile: const Stockpile(quantities: {'lumber': 50, 'castIron': 50}),
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
      improvementByTile: {resourceTile: 2},
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
      ConnectivityDevChainFixture.tileKey(p1, 1),
      ConnectivityDevChainFixture.tileKey(p1, 2),
      ConnectivityDevChainFixture.tileKey(p1, 3),
    ],
  );
}
