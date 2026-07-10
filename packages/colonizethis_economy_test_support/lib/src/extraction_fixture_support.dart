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
}) => singleTileMap(resource, province: province);

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
  return TestFixtures.minimalGame(
    id: 'g1',
    capitalTileGrainBonusPerTurn: 0,
    oldWorld: const RegionData(provinces: []),
    tileState: tileState,
    players: [spainPl1Player()],
  );
}

/// Per-tile improvement and road level for [tileStateFromSpecs].
///
/// Positional [improvement]/[roadLevel] keep scenario tables compact
/// (Refs #3939 slice 50). Prefer `TileImprovementSpec(key, imp, road)`.
class TileImprovementSpec {
  const TileImprovementSpec(
    this.tileKey, [
    this.improvement = 0,
    this.roadLevel = 0,
  ]);

  final String tileKey;
  final int improvement;
  final int roadLevel;
}

/// Same improvement/road level applied to each key (Refs #3939 slice 50).
List<TileImprovementSpec> tileImps(
  Iterable<String> tileKeys, [
  int improvement = 1,
  int roadLevel = 1,
]) => [
  for (final key in tileKeys) TileImprovementSpec(key, improvement, roadLevel),
];

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
}) => TileMapResult(
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

/// Multi-faction `{factionId: ConnectivityResult(connected: …)}` map
/// (Refs #3939 slice 52).
Map<String, ConnectivityResult> connectivityByFaction(
  Map<String, Set<String>> byFaction,
) => {
  for (final e in byFaction.entries)
    e.key: ConnectivityResult(connected: e.value),
};

/// Canonical capital-province tile key `oldWorld|p1|0|0` (Refs #3939 slice 53).
const String kOwP1Tile00 = 'oldWorld|p1|0|0';

/// [TileImprovementSpec] for [kOwP1Tile00] (Refs #3939 slice 53).
TileImprovementSpec owP1Imp([int improvement = 0, int roadLevel = 0]) =>
    TileImprovementSpec(kOwP1Tile00, improvement, roadLevel);

/// Canonical GP player `pl1` / "Spain" with oldWorld|p1 capital
/// (Refs #3939 slice 52).
Player spainPl1Player({
  Map<String, bool>? techUnlocked,
  String capitalProvinceId = 'oldWorld|p1',
  CapitalTile? capitalTile,
}) => Player(
  id: 'pl1',
  displayName: 'Spain',
  isHuman: true,
  capitalProvinceId: capitalProvinceId,
  capitalTile:
      capitalTile ??
      const CapitalTile(
        regionId: 'oldWorld',
        provinceId: 'oldWorld|p1',
        x: 0,
        y: 0,
      ),
  techUnlocked: techUnlocked,
);

/// A capital-province row with sane defaults for non-GP extraction tests.
Province capitalProvinceForNonGpExtractionTest({
  required String provinceId,
  int townDev = 1,
  String? townTileKey,
}) {
  final regionId = provinceId.split('|').first;
  final factionId = provinceId.split('|').last;
  return Province(
    id: provinceId,
    regionId: regionId,
    ownerId: factionId,
    townDevelopmentLevel: townDev,
    townTileKey: townTileKey,
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
  String id = 'g_test',
  List<Player> players = const [],
  Map<String, Map<String, List<String>>> tileKeysByRegionAndProvince = const {},
}) {
  return Game(
    id: id,
    capitalTileGrainBonusPerTurn: capitalTileGrainBonusPerTurn,
    worldState: WorldState(
      turnState: TurnState(turnNumber: 1, phase: TurnPhase.orders),
      oldWorld: RegionData(provinces: provinces),
      newWorld: RegionData(provinces: newWorldProvinces),
      tileState: tileState ?? TileMapState(),
      tileKeysByRegionAndProvince: tileKeysByRegionAndProvince,
    ),
    players: players,
    minorNations: minorNations,
    tribes: tribes,
  );
}

/// Province-filling [TileMapResult] for non-GP extraction/auto-offer rows
/// (Refs #3939 slice 58).
TileMapResult nonGpProvMap(
  String provinceId,
  int width,
  int height,
  List<List<Resource?>> resources,
) => tileMapAllInProvinceForNonGpExtractionTest(
  provinceId: provinceId,
  width: width,
  height: height,
  resources: resources,
);

/// Empty non-GP [Game] (no provinces / minors / tribes) (Refs #3939 slice 58).
Game nonGpEmptyGame() => gameForNonGpExtractionTest(provinces: const []);

/// Standard `m1` OW capital + [testMinor] shell (Refs #3939 slice 58 / 60).
Game nonGpMinorM1Game({
  List<TileImprovementSpec> tileSpecs = const [],
  int townDev = 1,
  int capitalTileGrainBonusPerTurn = 0,
  String id = 'g_test',
  String? townTileKey,
  List<Player> players = const [],
  Map<String, Map<String, List<String>>> tileKeysByRegionAndProvince = const {},
}) => gameForNonGpExtractionTest(
  id: id,
  provinces: [
    capitalProvinceForNonGpExtractionTest(
      provinceId: 'oldWorld|m1',
      townDev: townDev,
      townTileKey: townTileKey,
    ),
  ],
  tileState: tileSpecs.isEmpty ? null : tileStateFromSpecs(tileSpecs),
  minorNations: [testMinor()],
  capitalTileGrainBonusPerTurn: capitalTileGrainBonusPerTurn,
  players: players,
  tileKeysByRegionAndProvince: tileKeysByRegionAndProvince,
);

/// `m1` OW + `t1` NW dual-faction non-GP shell (Refs #3939 slice 58).
Game nonGpMinorAndTribeGame({
  List<TileImprovementSpec> tileSpecs = const [],
  int minorTownDev = 1,
  int tribeTownDev = 1,
}) => gameForNonGpExtractionTest(
  provinces: [
    capitalProvinceForNonGpExtractionTest(
      provinceId: 'oldWorld|m1',
      townDev: minorTownDev,
    ),
  ],
  newWorldProvinces: [
    capitalProvinceForNonGpExtractionTest(
      provinceId: 'newWorld|t1',
      townDev: tribeTownDev,
    ),
  ],
  tileState: tileSpecs.isEmpty ? null : tileStateFromSpecs(tileSpecs),
  minorNations: [testMinor()],
  tribes: [testTribe()],
);

/// Tribe-only NW shell for mineral-exclusion rows (Refs #3939 slice 58).
Game nonGpTribeNwGame({
  List<TileImprovementSpec> tileSpecs = const [],
  int townDev = 1,
}) => gameForNonGpExtractionTest(
  provinces: const [],
  newWorldProvinces: [
    capitalProvinceForNonGpExtractionTest(
      provinceId: 'newWorld|t1',
      townDev: townDev,
    ),
  ],
  tileState: tileSpecs.isEmpty ? null : tileStateFromSpecs(tileSpecs),
  tribes: [testTribe()],
);

/// Dual-faction timber/furs fixture shared by extraction + auto-offer rows
/// (Refs #3939 slice 59).
({
  Game game,
  Map<String, TileMapResult> tileMapByRegion,
  Map<String, ConnectivityResult> connectivityByFactionId,
})
nonGpMinorTribeTimberFursFixture({List<TileImprovementSpec>? tileSpecs}) {
  final specs =
      tileSpecs ??
      const [
        TileImprovementSpec('oldWorld|m1|0|0', 1, 1),
        TileImprovementSpec('newWorld|t1|0|0', 1, 1),
      ];
  return (
    game: nonGpMinorAndTribeGame(tileSpecs: specs),
    tileMapByRegion: {
      'oldWorld': nonGpProvMap('oldWorld|m1', 1, 1, const [
        [Resource.timber],
      ]),
      'newWorld': nonGpProvMap('newWorld|t1', 1, 1, const [
        [Resource.furs],
      ]),
    },
    connectivityByFactionId: connectivityByFaction({
      'm1': {'oldWorld|m1|0|0'},
      't1': {'newWorld|t1|0|0'},
    }),
  );
}

CapitalTile _factionCapitalTile(String provinceId, {int x = 0, int y = 0}) =>
    CapitalTile(
      regionId: provinceId.split('|').first,
      provinceId: provinceId,
      x: x,
      y: y,
    );

/// A standard one-tile minor nation in `oldWorld|m1` with capital at (0,0).
MinorNation testMinor({
  String id = 'm1',
  String provinceId = 'oldWorld|m1',
  int capitalX = 0,
  int capitalY = 0,
}) => MinorNation(
  id: id,
  capitalProvinceId: provinceId,
  capitalTile: _factionCapitalTile(provinceId, x: capitalX, y: capitalY),
);

/// A standard one-tile tribe in `newWorld|t1` with capital at (0,0).
Tribe testTribe({
  String id = 't1',
  String provinceId = 'newWorld|t1',
  int capitalX = 0,
  int capitalY = 0,
}) => Tribe(
  id: id,
  capitalProvinceId: provinceId,
  capitalTile: _factionCapitalTile(provinceId, x: capitalX, y: capitalY),
);

Province _owProvince(
  String localId, {
  int townDevelopmentLevel = 4,
  String ownerId = 'pl1',
  String? townTileKey,
}) => Province(
  id: 'oldWorld|$localId',
  regionId: 'oldWorld',
  ownerId: ownerId,
  townDevelopmentLevel: townDevelopmentLevel,
  townTileKey: townTileKey,
);

/// Canonical `oldWorld|p1` province owned by Spain/`pl1` (Refs #3939 slice 58).
Province owP1Province({int townDevelopmentLevel = 4, String? townTileKey}) =>
    _owProvince(
      'p1',
      townDevelopmentLevel: townDevelopmentLevel,
      townTileKey: townTileKey,
    );

/// Shared Spain/`pl1` extraction [Game] shell (Refs #3939 slice 57 / 58).
Game spainExtractorGame({
  required TileMapState tileState,
  required RegionData oldWorld,
  RegionData? newWorld,
  Map<String, bool>? techUnlocked,
  Map<String, Set<String>>? playerProspectedTiles,
  Map<String, String> portsByProvinceSeaboard = const {},
  Map<String, Map<String, List<String>>> tileKeysByRegionAndProvince = const {},
  CapitalTile? capitalTile,
  int capitalTileGrainBonusPerTurn = 0,
}) => TestFixtures.minimalGame(
  id: 'g1',
  capitalTileGrainBonusPerTurn: capitalTileGrainBonusPerTurn,
  oldWorld: oldWorld,
  newWorld: newWorld,
  tileState: tileState,
  playerProspectedTiles: playerProspectedTiles,
  portsByProvinceSeaboard: portsByProvinceSeaboard,
  tileKeysByRegionAndProvince: tileKeysByRegionAndProvince,
  players: [
    spainPl1Player(techUnlocked: techUnlocked, capitalTile: capitalTile),
  ],
);

/// Single-owned-province extraction setup: player `pl1` ("Spain") owns
/// `oldWorld|p1` (capital tile at 0,0) at [townDevelopmentLevel].
Game resourceExtractorGame({
  required TileMapState tileState,
  int townDevelopmentLevel = 4,
  Map<String, bool>? techUnlocked,
  Map<String, Set<String>>? playerProspectedTiles,
  String playerId = 'pl1',
  String? townTileKey,
  int capitalTileGrainBonusPerTurn = 0,
}) {
  assert(playerId == 'pl1', 'resourceExtractorGame uses spainPl1Player');
  return spainExtractorGame(
    tileState: tileState,
    oldWorld: RegionData(
      provinces: [
        owP1Province(
          townDevelopmentLevel: townDevelopmentLevel,
          townTileKey: townTileKey,
        ),
      ],
    ),
    techUnlocked: techUnlocked,
    playerProspectedTiles: playerProspectedTiles,
    capitalTileGrainBonusPerTurn: capitalTileGrainBonusPerTurn,
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
  assert(
    playerId == 'pl1',
    'townRuleTwoProvinceExtractorGame uses spainPl1Player',
  );
  return spainExtractorGame(
    tileState: tileState,
    oldWorld: RegionData(
      provinces: [
        _owProvince(
          'p1',
          townDevelopmentLevel: p1TownDevelopmentLevel,
          townTileKey: p1TownTileKey,
        ),
        _owProvince(
          'p2',
          townDevelopmentLevel: p2TownDevelopmentLevel,
          townTileKey: p2TownTileKey,
        ),
      ],
    ),
    portsByProvinceSeaboard: portsByProvinceSeaboard ?? const {},
  );
}

/// Single-player game with [oldWorld|p1] capital and an owned [newWorld|n1]
/// province for overseas extraction scenarios.
Game overseasResourceExtractorGame({required TileMapState tileState}) =>
    spainExtractorGame(
      tileState: tileState,
      oldWorld: RegionData(provinces: [owP1Province()]),
      newWorld: RegionData(
        provinces: [
          Province(id: 'newWorld|n1', regionId: 'newWorld', ownerId: 'pl1'),
        ],
      ),
    );

TopologyNode _topoNode(String id, String regionId, TopologyNodeType type) =>
    TopologyNode(id: id, regionId: regionId, type: type);

/// Dual-region blockaded-port extraction fixture (Refs #3939 phase 3 slice 23).
({Game game, Map<String, TileMapResult> tileMapByRegion, MapTopology topology})
blockadedOverseasExtractionFixture() {
  const ow = 'oldWorld';
  const nw = 'newWorld';
  final tileMapOw = tileMapFromGrids(
    grid: const [
      ['p1', 'p1'],
      ['p1', 'p1'],
    ],
    resourceGrid: const [
      [null, null],
      [null, null],
    ],
  );
  final tileMapNw = tileMapFromGrids(
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
      _topoNode('p1', ow, TopologyNodeType.province),
      _topoNode('n1', nw, TopologyNodeType.province),
      _topoNode('sea1', ow, TopologyNodeType.seaZone),
      _topoNode('sea2', nw, TopologyNodeType.seaZone),
    ],
    edges: const [
      TopologyEdge(id1: 'p1', id2: 'sea1'),
      TopologyEdge(id1: 'n1', id2: 'sea2'),
      TopologyEdge(id1: 'sea1', id2: 'sea2'),
    ],
  );
  return (
    game: spainExtractorGame(
      tileState: tileStateFromSpecs([
        const TileImprovementSpec('newWorld|n1|0|0', 1, 4),
        const TileImprovementSpec('newWorld|n1|1|0', 1, 4),
        owP1Imp(0, 4),
      ]),
      oldWorld: RegionData(provinces: [owP1Province()]),
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
      portsByProvinceSeaboard: {
        '$ow|p1|sea1': kOwP1Tile00,
        '$nw|n1|sea2': 'newWorld|n1|0|0',
      },
    ),
    tileMapByRegion: {ow: tileMapOw, nw: tileMapNw},
    topology: topology,
  );
}
