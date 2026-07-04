import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';

/// Shared fixtures for town manufacturing bonus extraction-phase integration
/// tests (Refs #3872 AC matrix).

const _ow = 'oldWorld';
const _playerId = 'pl1';

MapTopology twoProvinceOldWorldTopology() {
  return MapTopology(
    nodes: const [
      TopologyNode(
        id: 'p1',
        regionId: _ow,
        type: TopologyNodeType.province,
      ),
      TopologyNode(
        id: 'p2',
        regionId: _ow,
        type: TopologyNodeType.province,
      ),
    ],
    edges: const [],
  );
}

CapitalTile _capitalTile() => const CapitalTile(
  regionId: _ow,
  provinceId: '$_ow|p1',
  x: 0,
  y: 0,
);

Player _player({Map<String, bool> techUnlocked = const {}}) => Player(
  id: _playerId,
  displayName: 'Spain',
  isHuman: true,
  capitalProvinceId: '$_ow|p1',
  capitalTile: _capitalTile(),
  techUnlocked: techUnlocked,
);

/// p1 capital + p2 with timber capital-connected but not town-connected to
/// town at (3,1). Town dev level 2 on p2.
({Game game, Map<String, TileMapResult> tileMapByRegion})
capitalConnectedNotTownConnectedFixture() {
  const timberKey = '$_ow|p2|2|0';
  const townKey = '$_ow|p2|3|1';
  final grid = const [
    ['p1', 'p2', 'p2', 'p2'],
    ['p1', 'p2', 'p2', 'p2'],
  ];
  final tileMap = TileMapResult(
    width: 4,
    height: 2,
    grid: grid,
    resourceGrid: const [
      [null, null, Resource.timber, null],
      [null, null, null, null],
    ],
    terrainGrid: const [
      [null, null, TerrainType.hardwoodForest, null],
      [null, null, null, null],
    ],
  );
  final tileState = TileMapState()
      .setRoadLevel('$_ow|p1|0|0', 1)
      .setRoadLevel('$_ow|p2|1|0', 1)
      .setRoadLevel(timberKey, 1)
      .setImprovement(timberKey, 4)
      .setRoadLevel(townKey, 1);
  final game = TestFixtures.minimalGame(
    id: 'g_cap_not_town',
    capitalTileGrainBonusPerTurn: 0,
    oldWorld: RegionData(
      provinces: [
        Province(
          id: '$_ow|p1',
          regionId: _ow,
          ownerId: _playerId,
          townTileKey: '$_ow|p1|0|0',
          townDevelopmentLevel: 4,
        ),
        Province(
          id: '$_ow|p2',
          regionId: _ow,
          ownerId: _playerId,
          townTileKey: townKey,
          townDevelopmentLevel: 2,
        ),
      ],
    ),
    tileKeysByRegionAndProvince: {
      _ow: {
        '$_ow|p1': ['$_ow|p1|0|0'],
        '$_ow|p2': [timberKey, townKey, '$_ow|p2|1|0', '$_ow|p2|2|0'],
      },
    },
    tileState: tileState,
    players: [
      _player(techUnlocked: {kTechIdCircularSaw: true}),
    ],
  );
  return (game: game, tileMapByRegion: {_ow: tileMap});
}

/// p2 town-connected timber tile but province disconnected from GP capital.
({Game game, Map<String, TileMapResult> tileMapByRegion})
townConnectedNotCapitalConnectedFixture() {
  const townKey = '$_ow|p2|2|0';
  const timberKey = '$_ow|p2|2|1';
  final grid = const [
    ['p1', 'p1', 'p2'],
    ['p1', 'p1', 'p2'],
  ];
  final tileMap = TileMapResult(
    width: 3,
    height: 2,
    grid: grid,
    resourceGrid: const [
      [null, null, null],
      [null, null, Resource.timber],
    ],
    terrainGrid: const [
      [null, null, null],
      [null, null, TerrainType.hardwoodForest],
    ],
  );
  final tileState = TileMapState()
      .setRoadLevel('$_ow|p1|0|0', 1)
      .setRoadLevel(townKey, 1)
      .setRoadLevel(timberKey, 1)
      .setImprovement(timberKey, 4);
  final game = TestFixtures.minimalGame(
    id: 'g_town_not_cap',
    capitalTileGrainBonusPerTurn: 0,
    oldWorld: RegionData(
      provinces: [
        Province(
          id: '$_ow|p1',
          regionId: _ow,
          ownerId: _playerId,
          townTileKey: '$_ow|p1|0|0',
          townDevelopmentLevel: 4,
        ),
        Province(
          id: '$_ow|p2',
          regionId: _ow,
          ownerId: _playerId,
          townTileKey: townKey,
          townDevelopmentLevel: 2,
        ),
      ],
    ),
    tileKeysByRegionAndProvince: {
      _ow: {
        '$_ow|p1': ['$_ow|p1|0|0'],
        '$_ow|p2': [townKey, timberKey],
      },
    },
    tileState: tileState,
    players: [
      _player(techUnlocked: {kTechIdCircularSaw: true}),
    ],
  );
  return (game: game, tileMapByRegion: {_ow: tileMap});
}

/// p2 timber tile is both capital- and town-connected; level-4 town.
({Game game, Map<String, TileMapResult> tileMapByRegion})
bothConnectedFixture() {
  const townKey = '$_ow|p2|1|0';
  const timberKey = '$_ow|p2|2|0';
  final grid = const [
    ['p1', 'p2', 'p2'],
    ['p1', 'p2', 'p2'],
  ];
  final tileMap = TileMapResult(
    width: 3,
    height: 2,
    grid: grid,
    resourceGrid: const [
      [null, null, Resource.timber],
      [null, null, null],
    ],
    terrainGrid: const [
      [null, null, TerrainType.hardwoodForest],
      [null, null, null],
    ],
  );
  final tileState = TileMapState()
      .setRoadLevel('$_ow|p1|0|0', 4)
      .setRoadLevel('$_ow|p2|1|0', 4)
      .setRoadLevel(townKey, 4)
      .setRoadLevel(timberKey, 4)
      .setImprovement(timberKey, 4);
  final game = TestFixtures.minimalGame(
    id: 'g_both_connected',
    capitalTileGrainBonusPerTurn: 0,
    oldWorld: RegionData(
      provinces: [
        Province(
          id: '$_ow|p1',
          regionId: _ow,
          ownerId: _playerId,
          townTileKey: '$_ow|p1|0|0',
          townDevelopmentLevel: 4,
        ),
        Province(
          id: '$_ow|p2',
          regionId: _ow,
          ownerId: _playerId,
          townTileKey: townKey,
          townDevelopmentLevel: 4,
        ),
      ],
    ),
    tileKeysByRegionAndProvince: {
      _ow: {
        '$_ow|p1': ['$_ow|p1|0|0'],
        '$_ow|p2': [townKey, timberKey, '$_ow|p2|1|0'],
      },
    },
    tileState: tileState,
    players: [
      _player(techUnlocked: {kTechIdCircularSaw: true}),
    ],
  );
  return (game: game, tileMapByRegion: {_ow: tileMap});
}

/// Timber tile in p2 with no road path to capital and not town-connected.
({Game game, Map<String, TileMapResult> tileMapByRegion})
neitherConnectedFixture() {
  const timberKey = '$_ow|p2|2|1';
  final grid = const [
    ['p1', 'p2', 'p2'],
    ['p1', 'p2', 'p2'],
  ];
  final tileMap = TileMapResult(
    width: 3,
    height: 2,
    grid: grid,
    resourceGrid: const [
      [null, null, null],
      [null, null, Resource.timber],
    ],
    terrainGrid: const [
      [null, null, null],
      [null, null, TerrainType.hardwoodForest],
    ],
  );
  final tileState = TileMapState()
      .setRoadLevel('$_ow|p1|0|0', 1)
      .setImprovement(timberKey, 4);
  final game = TestFixtures.minimalGame(
    id: 'g_neither',
    capitalTileGrainBonusPerTurn: 0,
    oldWorld: RegionData(
      provinces: [
        Province(
          id: '$_ow|p1',
          regionId: _ow,
          ownerId: _playerId,
          townTileKey: '$_ow|p1|0|0',
          townDevelopmentLevel: 4,
        ),
        Province(
          id: '$_ow|p2',
          regionId: _ow,
          ownerId: _playerId,
          townTileKey: '$_ow|p2|0|0',
          townDevelopmentLevel: 2,
        ),
      ],
    ),
    tileKeysByRegionAndProvince: {
      _ow: {
        '$_ow|p1': ['$_ow|p1|0|0'],
        '$_ow|p2': [timberKey, '$_ow|p2|0|0'],
      },
    },
    tileState: tileState,
    players: [
      _player(techUnlocked: {kTechIdCircularSaw: true}),
    ],
  );
  return (game: game, tileMapByRegion: {_ow: tileMap});
}
