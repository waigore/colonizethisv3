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
