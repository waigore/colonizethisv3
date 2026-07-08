// Shared extraction/tile-map fixtures for economy test suites (Refs #3661, #3831, #3939).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

/// A 1×1 [TileMapResult] for [province] (local id, default `p1`) carrying
/// [resource] (`null` for an empty/no-resource tile).
TileMapResult singleTileMap(Resource? resource, {String province = 'p1'}) =>
    TileMapResult(
      width: 1,
      height: 1,
      grid: [
        [province],
      ],
      resourceGrid: [
        [resource],
      ],
    );

/// 1×1 [TileMapResult] keyed to [province] carrying [resource].
TileMapResult singleResourceTileMap(
  Resource resource, {
  String province = 'M1',
}) =>
    singleTileMap(resource, province: province);

/// Builds a single-region `tileMapByRegion` map for [regionId] placing
/// [resource] at coordinates `(0, 0)` of [province].
Map<String, TileMapResult> tileMapByRegionForResource(
  Resource resource, {
  String regionId = 'oldWorld',
  String province = 'M1',
}) {
  return {regionId: singleResourceTileMap(resource, province: province)};
}

/// Connected tile with no matching province row (world-model defensive path).
Game provinceMissingExtractorGame({required TileMapState tileState}) {
  final player = Player(
    id: 'pl1',
    displayName: 'Spain',
    isHuman: true,
    capitalProvinceId: 'oldWorld|p1',
    capitalTile: const CapitalTile(
      regionId: 'oldWorld',
      provinceId: 'oldWorld|p1',
      x: 0,
      y: 0,
    ),
  );
  return TestFixtures.minimalGame(
    id: 'g1',
    capitalTileGrainBonusPerTurn: 0,
    oldWorld: const RegionData(provinces: []),
    tileState: tileState,
    players: [player],
  );
}

/// Per-tile improvement and road level for [tileStateFromSpecs].
class TileImprovementSpec {
  const TileImprovementSpec(
    this.tileKey, {
    this.improvement = 0,
    this.roadLevel = 0,
  });

  final String tileKey;
  final int improvement;
  final int roadLevel;
}

/// Builds a [TileMapState] from [specs], applying only non-zero levels.
TileMapState tileStateFromSpecs(Iterable<TileImprovementSpec> specs) {
  var state = TileMapState();
  for (final TileImprovementSpec spec in specs) {
    if (spec.improvement > 0) {
      state = state.setImprovement(spec.tileKey, spec.improvement);
    }
    if (spec.roadLevel > 0) {
      state = state.setRoadLevel(spec.tileKey, spec.roadLevel);
    }
  }
  return state;
}

/// Builds a [TileMapResult] from parallel [grid] and [resourceGrid] rows.
TileMapResult tileMapFromGrids({
  required List<List<String>> grid,
  required List<List<Resource?>> resourceGrid,
}) =>
    TileMapResult(
      width: grid.first.length,
      height: grid.length,
      grid: grid,
      resourceGrid: resourceGrid,
    );

/// Square tile map of size [width] × [height] where every cell belongs to the
/// same prefixed [provinceId] and resources are read from [resources].
TileMapResult tileMapAllInProvinceForNonGpExtractionTest({
  required String provinceId,
  required int width,
  required int height,
  required List<List<Resource?>> resources,
}) {
  final localId = provinceId.split('|').last;
  final grid = List<List<String>>.generate(
    height,
    (_) => List<String>.filled(width, localId),
  );
  return tileMapFromGrids(grid: grid, resourceGrid: resources);
}

/// `{playerId: ConnectivityResult(...)}` for the single-player extraction
/// setup.
Map<String, ConnectivityResult> connectivityFor(
  Set<String> connected, {
  Map<String, int> pathTransportCap = const {},
  Set<String> connectedByRoadRule = const {},
  String playerId = 'pl1',
}) => {
  playerId: ConnectivityResult(
    connected: connected,
    pathTransportCap: pathTransportCap,
    connectedByRoadRule: connectedByRoadRule,
  ),
};

/// A capital-province row with sane defaults for non-GP extraction tests.
Province capitalProvinceForNonGpExtractionTest({
  required String provinceId,
  int townDev = 1,
}) {
  final regionId = provinceId.split('|').first;
  final factionId = provinceId.split('|').last;
  return Province(
    id: provinceId,
    regionId: regionId,
    ownerId: factionId,
    townDevelopmentLevel: townDev,
  );
}

/// Builds a minimal [Game] hosting the supplied non-GP factions.
Game gameForNonGpExtractionTest({
  required List<Province> provinces,
  TileMapState? tileState,
  List<MinorNation> minorNations = const [],
  List<Tribe> tribes = const [],
  int capitalTileGrainBonusPerTurn = 0,
  List<Province> newWorldProvinces = const [],
}) {
  return Game(
    id: 'g_test',
    capitalTileGrainBonusPerTurn: capitalTileGrainBonusPerTurn,
    worldState: WorldState(
      turnState: TurnState(turnNumber: 1, phase: TurnPhase.orders),
      oldWorld: RegionData(provinces: provinces),
      newWorld: RegionData(provinces: newWorldProvinces),
      tileState: tileState ?? TileMapState(),
    ),
    players: const [],
    minorNations: minorNations,
    tribes: tribes,
  );
}

/// A standard one-tile minor nation in `oldWorld|m1` with capital at (0,0).
MinorNation testMinor({
  String id = 'm1',
  String provinceId = 'oldWorld|m1',
  int capitalX = 0,
  int capitalY = 0,
}) {
  return MinorNation(
    id: id,
    capitalProvinceId: provinceId,
    capitalTile: CapitalTile(
      regionId: provinceId.split('|').first,
      provinceId: provinceId,
      x: capitalX,
      y: capitalY,
    ),
  );
}

/// A standard one-tile tribe in `newWorld|t1` with capital at (0,0).
Tribe testTribe({
  String id = 't1',
  String provinceId = 'newWorld|t1',
  int capitalX = 0,
  int capitalY = 0,
}) {
  return Tribe(
    id: id,
    capitalProvinceId: provinceId,
    capitalTile: CapitalTile(
      regionId: provinceId.split('|').first,
      provinceId: provinceId,
      x: capitalX,
      y: capitalY,
    ),
  );
}

/// Single-owned-province extraction setup: player `pl1` ("Spain") owns
/// `oldWorld|p1` (capital tile at 0,0) at [townDevelopmentLevel].
Game resourceExtractorGame({
  required TileMapState tileState,
  int townDevelopmentLevel = 4,
  Map<String, bool>? techUnlocked,
  Map<String, Set<String>>? playerProspectedTiles,
  String playerId = 'pl1',
}) {
  final player = Player(
    id: playerId,
    displayName: 'Spain',
    isHuman: true,
    capitalProvinceId: 'oldWorld|p1',
    capitalTile: const CapitalTile(
      regionId: 'oldWorld',
      provinceId: 'oldWorld|p1',
      x: 0,
      y: 0,
    ),
    techUnlocked: techUnlocked,
  );
  return TestFixtures.minimalGame(
    id: 'g1',
    capitalTileGrainBonusPerTurn: 0,
    oldWorld: RegionData(
      provinces: [
        Province(
          id: 'oldWorld|p1',
          regionId: 'oldWorld',
          ownerId: playerId,
          townDevelopmentLevel: townDevelopmentLevel,
        ),
      ],
    ),
    tileState: tileState,
    playerProspectedTiles: playerProspectedTiles,
    players: [player],
  );
}

/// Two-province GP game for town-rule extraction scenarios (Refs #3939).
Game townRuleTwoProvinceExtractorGame({
  required TileMapState tileState,
  required String p1TownTileKey,
  required String p2TownTileKey,
  int p1TownDevelopmentLevel = 4,
  int p2TownDevelopmentLevel = 2,
  Map<String, String>? portsByProvinceSeaboard,
  String playerId = 'pl1',
}) {
  const regionId = 'oldWorld';
  final player = Player(
    id: playerId,
    displayName: 'Spain',
    isHuman: true,
    capitalProvinceId: '$regionId|p1',
    capitalTile: const CapitalTile(
      regionId: regionId,
      provinceId: 'oldWorld|p1',
      x: 0,
      y: 0,
    ),
  );
  return TestFixtures.minimalGame(
    id: 'g1',
    capitalTileGrainBonusPerTurn: 0,
    oldWorld: RegionData(
      provinces: [
        Province(
          id: '$regionId|p1',
          regionId: regionId,
          ownerId: playerId,
          townTileKey: p1TownTileKey,
          townDevelopmentLevel: p1TownDevelopmentLevel,
        ),
        Province(
          id: '$regionId|p2',
          regionId: regionId,
          ownerId: playerId,
          townTileKey: p2TownTileKey,
          townDevelopmentLevel: p2TownDevelopmentLevel,
        ),
      ],
    ),
    tileState: tileState,
    portsByProvinceSeaboard: portsByProvinceSeaboard ?? const {},
    players: [player],
  );
}

/// Single-player game with [oldWorld|p1] capital and an owned [newWorld|n1]
/// province for overseas extraction scenarios.
Game overseasResourceExtractorGame({
  required TileMapState tileState,
}) {
  const playerId = 'pl1';
  final player = Player(
    id: playerId,
    displayName: 'Spain',
    isHuman: true,
    capitalProvinceId: 'oldWorld|p1',
    capitalTile: const CapitalTile(
      regionId: 'oldWorld',
      provinceId: 'oldWorld|p1',
      x: 0,
      y: 0,
    ),
  );
  return TestFixtures.minimalGame(
    id: 'g1',
    capitalTileGrainBonusPerTurn: 0,
    oldWorld: RegionData(
      provinces: [
        Province(
          id: 'oldWorld|p1',
          regionId: 'oldWorld',
          ownerId: playerId,
          townDevelopmentLevel: 4,
        ),
      ],
    ),
    newWorld: RegionData(
      provinces: [
        Province(id: 'newWorld|n1', regionId: 'newWorld', ownerId: playerId),
      ],
    ),
    tileState: tileState,
    players: [player],
  );
}

/// Dual-region blockaded-port extraction fixture (Refs #3939 phase 3 slice 23).
({
  Game game,
  Map<String, TileMapResult> tileMapByRegion,
  MapTopology topology,
}) blockadedOverseasExtractionFixture() {
  const ow = 'oldWorld';
  const nw = 'newWorld';
  final tileMapOw = TileMapResult(
    width: 2,
    height: 2,
    grid: const [
      ['p1', 'p1'],
      ['p1', 'p1'],
    ],
    resourceGrid: const [
      [null, null],
      [null, null],
    ],
  );
  final tileMapNw = TileMapResult(
    width: 2,
    height: 2,
    grid: const [
      ['n1', 'n1'],
      ['n1', 'n1'],
    ],
    resourceGrid: const [
      [Resource.sugarCane, Resource.sugarCane],
      [null, null],
    ],
  );
  final topology = MapTopology(
    nodes: [
      TopologyNode(
        id: 'p1',
        regionId: ow,
        type: TopologyNodeType.province,
      ),
      TopologyNode(
        id: 'n1',
        regionId: nw,
        type: TopologyNodeType.province,
      ),
      TopologyNode(
        id: 'sea1',
        regionId: ow,
        type: TopologyNodeType.seaZone,
      ),
      TopologyNode(
        id: 'sea2',
        regionId: nw,
        type: TopologyNodeType.seaZone,
      ),
    ],
    edges: [
      TopologyEdge(id1: 'p1', id2: 'sea1'),
      TopologyEdge(id1: 'n1', id2: 'sea2'),
      TopologyEdge(id1: 'sea1', id2: 'sea2'),
    ],
  );
  final cap = CapitalTile(regionId: ow, provinceId: '$ow|p1', x: 0, y: 0);
  final tileState = tileStateFromSpecs(const [
    TileImprovementSpec('newWorld|n1|0|0', improvement: 1, roadLevel: 4),
    TileImprovementSpec('newWorld|n1|1|0', improvement: 1, roadLevel: 4),
    TileImprovementSpec('oldWorld|p1|0|0', roadLevel: 4),
  ]);
  final ports = {
    '$ow|p1|sea1': 'oldWorld|p1|0|0',
    '$nw|n1|sea2': 'newWorld|n1|0|0',
  };
  final game = TestFixtures.minimalGame(
    id: 'g1',
    capitalTileGrainBonusPerTurn: 0,
    oldWorld: RegionData(
      provinces: [
        Province(
          id: '$ow|p1',
          regionId: ow,
          ownerId: 'pl1',
          townDevelopmentLevel: 4,
        ),
      ],
    ),
    newWorld: RegionData(
      provinces: [
        Province(
          id: '$nw|n1',
          regionId: nw,
          ownerId: 'pl1',
          townDevelopmentLevel: 4,
        ),
      ],
    ),
    tileState: tileState,
    portsByProvinceSeaboard: ports,
    players: [
      Player(
        id: 'pl1',
        displayName: 'Spain',
        isHuman: true,
        capitalProvinceId: '$ow|p1',
        capitalTile: cap,
      ),
    ],
  );
  return (
    game: game,
    tileMapByRegion: {ow: tileMapOw, nw: tileMapNw},
    topology: topology,
  );
}
