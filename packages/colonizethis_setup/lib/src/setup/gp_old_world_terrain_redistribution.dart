// SPEC/game/tile-map-and-generation.md; SPEC/program/game-setup-pipeline.md (§7d.terrain).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'gp_old_world_terrain_redistribution_hamilton.dart';
import 'gp_old_world_tile_scan.dart';
import 'setup_logging.dart';
import 'town_capital_occupancy.dart';

export 'gp_old_world_terrain_redistribution_hamilton.dart'
    show kGpOwTerrainRedistributionSalt;

/// Best-effort GP Old World terrain balancing after ownership and before
/// capitals/towns (§7b/§7d). Never throws for terrain fairness; see
/// SPEC/program/game-setup-pipeline.md.
({Game game, TileMapResult tileMap, double fairnessMaxAbsFracDeviation})
applyGreatPowerOldWorldTerrainRedistribution({
  required Game game,
  required TileMapResult tileMapOldWorld,
  required int setupSeedBase,
}) {
  final terrainGrid = tileMapOldWorld.terrainGrid;
  final resGrid = tileMapOldWorld.resourceGrid;
  if (terrainGrid == null || resGrid == null) {
    setupLog.i(
      'skip GP Old World terrain redistribution (missing terrain or resource grid)',
    );
    return (
      game: game,
      tileMap: tileMapOldWorld,
      fairnessMaxAbsFracDeviation: 0,
    );
  }

  final gpIdsSorted = gpIdsSortedFromPlayers(game);
  final gpIds = gpIdsSorted.toSet();
  if (gpIdsSorted.isEmpty) {
    return (
      game: game,
      tileMap: tileMapOldWorld,
      fairnessMaxAbsFracDeviation: 0,
    );
  }

  final ownerByLocal = gpOwnerByLocalProvinceId(game);
  final forbidden = collectTownAndCapitalTileKeys(game);
  final tiles = collectGpOwEligibleTilesSorted(
    map: tileMapOldWorld,
    gpIdsSorted: gpIdsSorted,
    gpIds: gpIds,
    ownerByLocal: ownerByLocal,
    forbidden: forbidden,
  );
  if (tiles.isEmpty) {
    setupLog.i(
      'GP Old World terrain redistribution: no eligible GP land tiles',
    );
    return (
      game: game,
      tileMap: tileMapOldWorld,
      fairnessMaxAbsFracDeviation: 0,
    );
  }

  final wByGp = eligibleLandCountsByGp(tiles, gpIdsSorted);
  final nTGlobal = countTerrainOnEligibleTiles(
    map: tileMapOldWorld,
    tiles: tiles,
  );

  final targetByGpTerrain = <String, Map<TerrainType, int>>{
    for (final g in gpIdsSorted) g: <TerrainType, int>{},
  };
  for (final t in TerrainType.values) {
    final nT = nTGlobal[t] ?? 0;
    if (nT <= 0) continue;
    final perGp = hamiltonTargetsForType(
      nT: nT,
      gpIdsSorted: gpIdsSorted,
      wByGp: wByGp,
      tieTerrainIndex: t.index,
      setupSeedBase: setupSeedBase,
    );
    for (final g in gpIdsSorted) {
      targetByGpTerrain[g]![t] = perGp[g] ?? 0;
    }
  }

  final sequence = <TerrainType>[];
  for (final g in gpIdsSorted) {
    final row = targetByGpTerrain[g]!;
    for (final t in TerrainType.values) {
      final c = row[t] ?? 0;
      for (var i = 0; i < c; i++) {
        sequence.add(t);
      }
    }
  }

  if (sequence.length != tiles.length) {
    setupLog.e(
      'logic: GP OW terrain redistribution internal length mismatch '
      'seq=${sequence.length} tiles=${tiles.length} — leaving map unchanged',
    );
    return (
      game: game,
      tileMap: tileMapOldWorld,
      fairnessMaxAbsFracDeviation: 0,
    );
  }

  final nextTerrain = <List<TerrainType?>>[
    for (var row = 0; row < tileMapOldWorld.height; row++)
      List<TerrainType?>.from(terrainGrid[row]),
  ];
  for (var i = 0; i < tiles.length; i++) {
    final c = tiles[i];
    nextTerrain[c.y][c.x] = sequence[i];
  }
  var map = TileMapResult(
    width: tileMapOldWorld.width,
    height: tileMapOldWorld.height,
    grid: tileMapOldWorld.grid,
    terrainGrid: nextTerrain,
    resourceGrid: resGrid,
  );

  final achieved = <String, Map<TerrainType, int>>{
    for (final g in gpIdsSorted) g: {},
  };
  for (final c in tiles) {
    final ter = map.terrainAt(c.x, c.y);
    if (ter == null) continue;
    final row = achieved[c.gpId]!;
    row[ter] = (row[ter] ?? 0) + 1;
  }

  final fairness = fairnessMaxAbsFracDeviation(
    gpIdsSorted: gpIdsSorted,
    wByGp: wByGp,
    nTGlobal: nTGlobal,
    achieved: achieved,
  );

  setupLog.i(
    'GP Old World terrain redistribution complete '
    'eligibleTiles=${tiles.length} fairnessMaxAbsFracDev=$fairness '
    '(diagnostic; setup does not fail on terrain fairness)',
  );

  return (game: game, tileMap: map, fairnessMaxAbsFracDeviation: fairness);
}

/// Test helper: counts [terrain] on eligible GP Old World land tiles (excl. town/capital).
int countTerrainOnGpOldWorldEligibleTiles({
  required Game game,
  required TileMapResult map,
  required TerrainType terrain,
}) {
  final gpIdsSorted = gpIdsSortedFromPlayers(game);
  final gpIds = gpIdsSorted.toSet();
  final ownerByLocal = gpOwnerByLocalProvinceId(game);
  final forbidden = collectTownAndCapitalTileKeys(game);
  final tiles = collectGpOwEligibleTilesSorted(
    map: map,
    gpIdsSorted: gpIdsSorted,
    gpIds: gpIds,
    ownerByLocal: ownerByLocal,
    forbidden: forbidden,
  );
  var n = 0;
  for (final t in tiles) {
    if (map.terrainAt(t.x, t.y) == terrain) n++;
  }
  return n;
}
