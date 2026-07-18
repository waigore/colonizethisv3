// SPEC/program/game-setup-pipeline.md §7d.terrain-restore;
// SPEC/game/tile-map-and-generation.md — restore GP OW N_T after settlement plains conversion.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_world/colonizethis_world.dart';
import 'gp_old_world_tile_scan.dart';
import 'setup_logging.dart';
import 'town_capital_occupancy.dart';

/// Counts each [TerrainType] on Great Power–owned Old World land tiles.
Map<TerrainType, int> countGpOwTerrainByType({
  required Game game,
  required TileMapResult tileMapOldWorld,
}) {
  final counts = <TerrainType, int>{for (final t in TerrainType.values) t: 0};
  final gpIds = gpIdsSortedFromPlayers(game).toSet();
  if (gpIds.isEmpty || tileMapOldWorld.terrainGrid == null) return counts;
  final ownerByLocal = gpOwnerByLocalProvinceId(game);
  visitGpOwLandTiles(
    map: tileMapOldWorld,
    ownerByLocal: ownerByLocal,
    gpIds: gpIds,
    visit: (x, y, local, owner, key) {
      final terrain = tileMapOldWorld.terrainAt(x, y);
      if (terrain == null) return;
      counts[terrain] = (counts[terrain] ?? 0) + 1;
    },
  );
  return counts;
}

/// After capital/town select-then-convert, restores each non-plains terrain-type
/// total on GP Old World land to [targetCounts] (snapshot after §7d.terrain) by
/// converting non-settlement plains tiles in deterministic (y, x) order.
///
/// Settlement tiles stay plains and remain excluded from §7d.redist capacity;
/// relocated labels restore terrain-eligible capacity lost when conversion
/// destroyed non-plains labels that terrain redistrib had placed on settlements.
TileMapResult restoreGpOwTerrainCountsAfterSettlementPlains({
  required Game game,
  required TileMapResult tileMapOldWorld,
  required Map<TerrainType, int> targetCounts,
}) {
  if (tileMapOldWorld.terrainGrid == null) return tileMapOldWorld;
  final gpIds = gpIdsSortedFromPlayers(game).toSet();
  if (gpIds.isEmpty) return tileMapOldWorld;

  final forbidden = collectTownAndCapitalTileKeys(game);
  final current = countGpOwTerrainByType(
    game: game,
    tileMapOldWorld: tileMapOldWorld,
  );
  var map = tileMapOldWorld;
  var restoredCells = 0;

  for (final t in TerrainType.values) {
    if (t == TerrainType.plains) continue;
    final deficit = (targetCounts[t] ?? 0) - (current[t] ?? 0);
    if (deficit <= 0) continue;

    final plainsCandidates = <({int x, int y})>[];
    final ownerByLocal = gpOwnerByLocalProvinceId(game);
    visitGpOwLandTiles(
      map: map,
      ownerByLocal: ownerByLocal,
      gpIds: gpIds,
      visit: (x, y, local, owner, key) {
        if (forbidden.contains(key)) return;
        if (map.terrainAt(x, y) != TerrainType.plains) return;
        plainsCandidates.add((x: x, y: y));
      },
    );
    // visitGpOwLandTiles is already (y, x); keep stable order.
    final take = deficit < plainsCandidates.length
        ? deficit
        : plainsCandidates.length;
    for (var i = 0; i < take; i++) {
      final cell = plainsCandidates[i];
      map = map.withTerrainAt(cell.x, cell.y, t);
      restoredCells++;
      current[t] = (current[t] ?? 0) + 1;
      current[TerrainType.plains] = (current[TerrainType.plains] ?? 0) - 1;
    }
    if (take < deficit) {
      setupLog.w(
        'GP OW terrain restore: could not fully restore ${t.name} '
        '(needed $deficit, relocated $take)',
      );
    }
  }

  if (restoredCells > 0) {
    setupLog.i(
      'GP OW terrain restore after settlement plains: relocated $restoredCells '
      'non-plains label(s) onto non-settlement plains',
    );
  }
  return map;
}
