// dart format off
// Extraction game shells and faction helpers (Refs #3661, #4108 slice B).
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';
import 'package:colonizethis_world/colonizethis_world.dart';
import 'extraction_tile_fixture_support.dart';
import 'fixture_builders/game_builders.dart' show gameForNonGpExtractionTest;
Game provinceMissingExtractorGame({required TileMapState tileState}) {
  return TestFixtures.minimalGame(
    id: 'g1',
    capitalTileGrainBonusPerTurn: 0,
    oldWorld: const RegionData(provinces: []),
    tileState: tileState,
    players: [spainPl1Player()],
  );
}
Player spainPl1Player({Map<String, bool>? techUnlocked, String capitalProvinceId = 'oldWorld|p1', CapitalTile? capitalTile}) => Player(
  id: 'pl1',
  displayName: 'Spain',
  isHuman: true,
  capitalProvinceId: capitalProvinceId,
  capitalTile: capitalTile ?? const CapitalTile(regionId: 'oldWorld', provinceId: 'oldWorld|p1', x: 0, y: 0),
  techUnlocked: techUnlocked,
);
Province capitalProvinceForNonGpExtractionTest({required String provinceId, int townDev = 1, String? townTileKey}) {
  final regionId = provinceId.split('|').first;
  final factionId = provinceId.split('|').last;
  return Province(id: provinceId, regionId: regionId, ownerId: factionId, townDevelopmentLevel: townDev, townTileKey: townTileKey);
}
Game nonGpEmptyGame() => gameForNonGpExtractionTest(provinces: const []);
Game nonGpMinorM1Game({List<TileImprovementSpec> tileSpecs = const [], int townDev = 1, int capitalTileGrainBonusPerTurn = 0, String id = 'g_test', String? townTileKey, List<Player> players = const [], Map<String, Map<String, List<String>>> tileKeysByRegionAndProvince = const {}}) => gameForNonGpExtractionTest(
  id: id,
  provinces: [capitalProvinceForNonGpExtractionTest(provinceId: 'oldWorld|m1', townDev: townDev, townTileKey: townTileKey)],
  tileState: tileSpecs.isEmpty ? null : tileStateFromSpecs(tileSpecs),
  minorNations: [testMinor()],
  capitalTileGrainBonusPerTurn: capitalTileGrainBonusPerTurn,
  players: players,
  tileKeysByRegionAndProvince: tileKeysByRegionAndProvince,
);
Game nonGpMinorAndTribeGame({List<TileImprovementSpec> tileSpecs = const [], int minorTownDev = 1, int tribeTownDev = 1}) => gameForNonGpExtractionTest(
  provinces: [capitalProvinceForNonGpExtractionTest(provinceId: 'oldWorld|m1', townDev: minorTownDev)],
  newWorldProvinces: [capitalProvinceForNonGpExtractionTest(provinceId: 'newWorld|t1', townDev: tribeTownDev)],
  tileState: tileSpecs.isEmpty ? null : tileStateFromSpecs(tileSpecs),
  minorNations: [testMinor()],
  tribes: [testTribe()],
);
Game nonGpTribeNwGame({List<TileImprovementSpec> tileSpecs = const [], int townDev = 1}) => gameForNonGpExtractionTest(
  provinces: const [],
  newWorldProvinces: [capitalProvinceForNonGpExtractionTest(provinceId: 'newWorld|t1', townDev: townDev)],
  tileState: tileSpecs.isEmpty ? null : tileStateFromSpecs(tileSpecs),
  tribes: [testTribe()],
);
({Game game, Map<String, TileMapResult> tileMapByRegion, Map<String, ConnectivityResult> connectivityByFactionId}) nonGpMinorTribeTimberFursFixture({List<TileImprovementSpec>? tileSpecs}) {
  final specs = tileSpecs ?? const [TileImprovementSpec('oldWorld|m1|0|0', 1, 1), TileImprovementSpec('newWorld|t1|0|0', 1, 1)];
  return (
    game: nonGpMinorAndTribeGame(tileSpecs: specs),
    tileMapByRegion: {
      'oldWorld': nonGpProvMap('oldWorld|m1', const [
        [Resource.timber],
      ]),
      'newWorld': nonGpProvMap('newWorld|t1', const [
        [Resource.furs],
      ]),
    },
    connectivityByFactionId: connectivityByFaction({
      'm1': {'oldWorld|m1|0|0'},
      't1': {'newWorld|t1|0|0'},
    }),
  );
}
CapitalTile _factionCapitalTile(String provinceId, {int x = 0, int y = 0}) => CapitalTile(regionId: provinceId.split('|').first, provinceId: provinceId, x: x, y: y);
MinorNation testMinor({String id = 'm1', String provinceId = 'oldWorld|m1', int capitalX = 0, int capitalY = 0}) => MinorNation(
  id: id,
  capitalProvinceId: provinceId,
  capitalTile: _factionCapitalTile(provinceId, x: capitalX, y: capitalY),
);
Tribe testTribe({String id = 't1', String provinceId = 'newWorld|t1', int capitalX = 0, int capitalY = 0}) => Tribe(
  id: id,
  capitalProvinceId: provinceId,
  capitalTile: _factionCapitalTile(provinceId, x: capitalX, y: capitalY),
);
Province _owProvince(String localId, {int townDevelopmentLevel = 4, String ownerId = 'pl1', String? townTileKey}) => Province(id: 'oldWorld|$localId', regionId: 'oldWorld', ownerId: ownerId, townDevelopmentLevel: townDevelopmentLevel, townTileKey: townTileKey);
Province owP1Province({int townDevelopmentLevel = 4, String? townTileKey}) => _owProvince('p1', townDevelopmentLevel: townDevelopmentLevel, townTileKey: townTileKey);
Game spainExtractorGame({required TileMapState tileState, required RegionData oldWorld, RegionData? newWorld, Map<String, bool>? techUnlocked, Map<String, Set<String>>? playerProspectedTiles, Map<String, String> portsByProvinceSeaboard = const {}, Map<String, Map<String, List<String>>> tileKeysByRegionAndProvince = const {}, CapitalTile? capitalTile, int capitalTileGrainBonusPerTurn = 0}) => TestFixtures.minimalGame(
  id: 'g1',
  capitalTileGrainBonusPerTurn: capitalTileGrainBonusPerTurn,
  oldWorld: oldWorld,
  newWorld: newWorld,
  tileState: tileState,
  playerProspectedTiles: playerProspectedTiles,
  portsByProvinceSeaboard: portsByProvinceSeaboard,
  tileKeysByRegionAndProvince: tileKeysByRegionAndProvince,
  players: [spainPl1Player(techUnlocked: techUnlocked, capitalTile: capitalTile)],
);
Game resourceExtractorGame({required TileMapState tileState, int townDevelopmentLevel = 4, Map<String, bool>? techUnlocked, Map<String, Set<String>>? playerProspectedTiles, String playerId = 'pl1', String? townTileKey, int capitalTileGrainBonusPerTurn = 0}) {
  assert(playerId == 'pl1', 'resourceExtractorGame uses spainPl1Player');
  return spainExtractorGame(
    tileState: tileState,
    oldWorld: RegionData(
      provinces: [owP1Province(townDevelopmentLevel: townDevelopmentLevel, townTileKey: townTileKey)],
    ),
    techUnlocked: techUnlocked,
    playerProspectedTiles: playerProspectedTiles,
    capitalTileGrainBonusPerTurn: capitalTileGrainBonusPerTurn,
  );
}
Game townRuleTwoProvinceExtractorGame({required TileMapState tileState, required String p1TownTileKey, required String p2TownTileKey, int p1TownDevelopmentLevel = 4, int p2TownDevelopmentLevel = 2, Map<String, String>? portsByProvinceSeaboard, String playerId = 'pl1'}) {
  assert(playerId == 'pl1', 'townRuleTwoProvinceExtractorGame uses spainPl1Player');
  return spainExtractorGame(
    tileState: tileState,
    oldWorld: RegionData(
      provinces: [
        _owProvince('p1', townDevelopmentLevel: p1TownDevelopmentLevel, townTileKey: p1TownTileKey),
        _owProvince('p2', townDevelopmentLevel: p2TownDevelopmentLevel, townTileKey: p2TownTileKey),
      ],
    ),
    portsByProvinceSeaboard: portsByProvinceSeaboard ?? const {},
  );
}
Game overseasResourceExtractorGame({required TileMapState tileState}) => spainExtractorGame(
  tileState: tileState,
  oldWorld: RegionData(provinces: [owP1Province()]),
  newWorld: RegionData(
    provinces: [Province(id: 'newWorld|n1', regionId: 'newWorld', ownerId: 'pl1')],
  ),
);
TopologyNode _topoNode(String id, String regionId, TopologyNodeType type) => TopologyNode(id: id, regionId: regionId, type: type);
({Game game, Map<String, TileMapResult> tileMapByRegion, MapTopology topology}) blockadedOverseasExtractionFixture() {
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
    nodes: [_topoNode('p1', ow, TopologyNodeType.province), _topoNode('n1', nw, TopologyNodeType.province), _topoNode('sea1', ow, TopologyNodeType.seaZone), _topoNode('sea2', nw, TopologyNodeType.seaZone)],
    edges: const [
      TopologyEdge(id1: 'p1', id2: 'sea1'),
      TopologyEdge(id1: 'n1', id2: 'sea2'),
      TopologyEdge(id1: 'sea1', id2: 'sea2'),
    ],
  );
  return (
    game: spainExtractorGame(
      tileState: tileStateFromSpecs([const TileImprovementSpec('newWorld|n1|0|0', 1, 4), const TileImprovementSpec('newWorld|n1|1|0', 1, 4), owP1Imp(0, 4)]),
      oldWorld: RegionData(provinces: [owP1Province()]),
      newWorld: RegionData(
        provinces: [Province(id: '$nw|n1', regionId: nw, ownerId: 'pl1', townDevelopmentLevel: 4)],
      ),
      portsByProvinceSeaboard: {'$ow|p1|sea1': kOwP1Tile00, '$nw|n1|sea2': 'newWorld|n1|0|0'},
    ),
    tileMapByRegion: {ow: tileMapOw, nw: tileMapNw},
    topology: topology,
  );
}
// dart format on
