// Shared fixture helper for `resource_extractor_part*_test.dart`.
//
// Hoists the single-owned-province `computeExtraction` setup that was copied
// verbatim across the four split resource-extractor suites so each scenario
// only declares the inputs it actually varies (tile state, town dev, tech,
// prospected tiles). Refs #3661 (economy test dedup, step 5); #3831 Phase 4.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import 'tile_map_test_support.dart';

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

/// `{playerId: ConnectivityResult(...)}` for the single-player extraction
/// setup. Hoists the `{'pl1': ConnectivityResult(connected: {…})}` wrapper
/// repeated across the resource-extractor suites; [pathTransportCap] and
/// [connectedByRoadRule] keep their `ConnectivityResult` defaults. Refs #3661.
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

/// Single-owned-province extraction setup: player `pl1` ("Spain") owns
/// `oldWorld|p1` (capital tile at 0,0) at [townDevelopmentLevel]. Pairs with a
/// single-region `tileMapByRegion` for `computeExtraction` resource tests; pass
/// [techUnlocked] for tech-cap cases and [playerProspectedTiles] for minerals.
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
