import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';

/// Shared fixtures for town manufacturing bonus extraction-phase integration
/// tests (Refs #3872 AC matrix).

const _ow = kRegionOldWorld;
const _playerId = 'pl1';
const _p1Id = '$_ow|p1';
const _p2Id = '$_ow|p2';
const _p1CapitalKey = '$_ow|p1|0|0';

MapTopology twoProvinceOldWorldTopology() {
  return const MapTopology(
    nodes: [
      TopologyNode(id: 'p1', regionId: _ow, type: TopologyNodeType.province),
      TopologyNode(id: 'p2', regionId: _ow, type: TopologyNodeType.province),
    ],
    edges: [],
  );
}

CapitalTile _capitalTile() =>
    const CapitalTile(regionId: _ow, provinceId: _p1Id, x: 0, y: 0);

Player _player({Map<String, bool> techUnlocked = const {}}) => Player(
  id: _playerId,
  displayName: 'Spain',
  isHuman: true,
  capitalProvinceId: _p1Id,
  capitalTile: _capitalTile(),
  techUnlocked: techUnlocked,
);

({Game game, Map<String, TileMapResult> tileMapByRegion})
_townManufacturingFixture({
  required String id,
  required String p2TownKey,
  required int p2TownDevelopmentLevel,
  required List<String> p2TileKeys,
  required TileMapResult tileMap,
  required TileMapState tileState,
}) {
  final game = TestFixtures.minimalGame(
    id: id,
    capitalTileGrainBonusPerTurn: 0,
    oldWorld: RegionData(
      provinces: [
        Province(
          id: _p1Id,
          regionId: _ow,
          ownerId: _playerId,
          townTileKey: _p1CapitalKey,
          townDevelopmentLevel: 4,
        ),
        Province(
          id: _p2Id,
          regionId: _ow,
          ownerId: _playerId,
          townTileKey: p2TownKey,
          townDevelopmentLevel: p2TownDevelopmentLevel,
        ),
      ],
    ),
    tileKeysByRegionAndProvince: {
      _ow: {
        _p1Id: [_p1CapitalKey],
        _p2Id: p2TileKeys,
      },
    },
    tileState: tileState,
    players: [
      _player(techUnlocked: {kTechIdCircularSaw: true}),
    ],
  );
  return (game: game, tileMapByRegion: {_ow: tileMap});
}

TileMapResult _map({
  required List<List<String>> grid,
  required List<List<Resource?>> resourceGrid,
  required List<List<TerrainType?>> terrainGrid,
}) => TileMapResult(
  width: grid.first.length,
  height: grid.length,
  grid: grid,
  resourceGrid: resourceGrid,
  terrainGrid: terrainGrid,
);

/// p1 capital + p2 with timber capital-connected but not town-connected to
/// town at (3,1). Town dev level 2 on p2.
({Game game, Map<String, TileMapResult> tileMapByRegion})
capitalConnectedNotTownConnectedFixture() {
  const timberKey = '$_ow|p2|2|0';
  const townKey = '$_ow|p2|3|1';
  return _townManufacturingFixture(
    id: 'g_cap_not_town',
    p2TownKey: townKey,
    p2TownDevelopmentLevel: 2,
    p2TileKeys: [timberKey, townKey, '$_ow|p2|1|0', '$_ow|p2|2|0'],
    tileMap: _map(
      grid: const [
        ['p1', 'p2', 'p2', 'p2'],
        ['p1', 'p2', 'p2', 'p2'],
      ],
      resourceGrid: const [
        [null, null, Resource.timber, null],
        [null, null, null, null],
      ],
      terrainGrid: const [
        [null, null, TerrainType.hardwoodForest, null],
        [null, null, null, null],
      ],
    ),
    tileState: TileMapState()
        .setRoadLevel(_p1CapitalKey, 1)
        .setRoadLevel('$_ow|p2|1|0', 1)
        .setRoadLevel(timberKey, 1)
        .setImprovement(timberKey, 4)
        .setRoadLevel(townKey, 1),
  );
}

/// p2 town-connected timber tile but province disconnected from GP capital.
({Game game, Map<String, TileMapResult> tileMapByRegion})
townConnectedNotCapitalConnectedFixture() {
  const townKey = '$_ow|p2|2|0';
  const timberKey = '$_ow|p2|2|1';
  return _townManufacturingFixture(
    id: 'g_town_not_cap',
    p2TownKey: townKey,
    p2TownDevelopmentLevel: 2,
    p2TileKeys: [townKey, timberKey],
    tileMap: _map(
      grid: const [
        ['p1', 'p1', 'p2'],
        ['p1', 'p1', 'p2'],
      ],
      resourceGrid: const [
        [null, null, null],
        [null, null, Resource.timber],
      ],
      terrainGrid: const [
        [null, null, null],
        [null, null, TerrainType.hardwoodForest],
      ],
    ),
    tileState: TileMapState()
        .setRoadLevel(_p1CapitalKey, 1)
        .setRoadLevel(townKey, 1)
        .setRoadLevel(timberKey, 1)
        .setImprovement(timberKey, 4),
  );
}

/// p2 timber tile is both capital- and town-connected; level-4 town.
({Game game, Map<String, TileMapResult> tileMapByRegion})
bothConnectedFixture() {
  const townKey = '$_ow|p2|1|0';
  const timberKey = '$_ow|p2|2|0';
  return _townManufacturingFixture(
    id: 'g_both_connected',
    p2TownKey: townKey,
    p2TownDevelopmentLevel: 4,
    p2TileKeys: [townKey, timberKey, '$_ow|p2|1|0'],
    tileMap: _map(
      grid: const [
        ['p1', 'p2', 'p2'],
        ['p1', 'p2', 'p2'],
      ],
      resourceGrid: const [
        [null, null, Resource.timber],
        [null, null, null],
      ],
      terrainGrid: const [
        [null, null, TerrainType.hardwoodForest],
        [null, null, null],
      ],
    ),
    tileState: TileMapState()
        .setRoadLevel(_p1CapitalKey, 4)
        .setRoadLevel('$_ow|p2|1|0', 4)
        .setRoadLevel(townKey, 4)
        .setRoadLevel(timberKey, 4)
        .setImprovement(timberKey, 4),
  );
}

/// Timber tile in p2 with no road path to capital and not town-connected.
({Game game, Map<String, TileMapResult> tileMapByRegion})
neitherConnectedFixture() {
  const timberKey = '$_ow|p2|2|1';
  return _townManufacturingFixture(
    id: 'g_neither',
    p2TownKey: '$_ow|p2|0|0',
    p2TownDevelopmentLevel: 2,
    p2TileKeys: [timberKey, '$_ow|p2|0|0'],
    tileMap: _map(
      grid: const [
        ['p1', 'p2', 'p2'],
        ['p1', 'p2', 'p2'],
      ],
      resourceGrid: const [
        [null, null, null],
        [null, null, Resource.timber],
      ],
      terrainGrid: const [
        [null, null, null],
        [null, null, TerrainType.hardwoodForest],
      ],
    ),
    tileState: TileMapState()
        .setRoadLevel(_p1CapitalKey, 1)
        .setImprovement(timberKey, 4),
  );
}
