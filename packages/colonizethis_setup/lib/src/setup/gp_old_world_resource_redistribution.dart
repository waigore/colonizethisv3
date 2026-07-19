// SPEC/game/tile-map-and-generation.md; SPEC/program/game-setup-pipeline.md (§7d.redist).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import 'gp_old_world_resource_redistribution_quota_placement.dart';
import 'gp_old_world_resource_redistribution_tile_scans.dart';
import 'gp_old_world_tile_scan.dart';
import 'setup_logging.dart';

export 'gp_old_world_resource_redistribution_types.dart';

/// After redistribution: counts [resource] on GP-owned OW land (excl. town/capital).
int countResourceOnGpOldWorldTiles({
  required Game game,
  required TileMapResult map,
  required Resource resource,
}) {
  final gpIds = gpIdsSortedFromPlayers(game).toSet();
  final ownerByLocal = gpOwnerByLocalProvinceId(game);
  final forbidden = collectTownAndCapitalTileKeys(game);
  final inventory = buildGpOwTileInventory(
    map: map,
    ownerByLocal: ownerByLocal,
    gpIds: gpIds,
  );
  return countResourceOnGpTiles(
    inventory: inventory,
    forbidden: forbidden,
    resource: resource,
  );
}

/// Mandatory GP Old World terrain resource redistribution after §7d.strip and before
/// Great Power grain bootstrap. See SPEC/program/game-setup-pipeline.md.
({Game game, TileMapResult tileMap, double fairnessScore})
applyGreatPowerOldWorldResourceRedistribution({
  required Game game,
  required TileMapResult tileMapOldWorld,
  required ResourceRules resourceRules,
  required int setupSeedBase,
}) {
  final terrain = tileMapOldWorld.terrainGrid;
  final resGrid = tileMapOldWorld.resourceGrid;
  if (terrain == null || resGrid == null) {
    setupLog.i(
      'skip GP Old World resource redistribution (missing terrain or resource grid)',
    );
    return (game: game, tileMap: tileMapOldWorld, fairnessScore: 0);
  }

  // Slot order preserved by gpIdsSortedFromPlayers (gp1, gp2, …; no lex sort).
  final gpIdsSorted = gpIdsSortedFromPlayers(game);
  final gpIds = gpIdsSorted.toSet();
  final g = gpIdsSorted.length;
  if (g == 0) {
    return (game: game, tileMap: tileMapOldWorld, fairnessScore: 0);
  }

  final ownerByLocal = gpOwnerByLocalProvinceId(game);
  final forbidden = collectTownAndCapitalTileKeys(game);
  final resourceSet = resourcesInRedistributionSet(resourceRules);

  // Single pre-clear inventory for N_r counts (Refs #4029).
  final preClearInventory = buildGpOwTileInventory(
    map: tileMapOldWorld,
    ownerByLocal: ownerByLocal,
    gpIds: gpIds,
  );
  final inventoryN = <Resource, int>{};
  for (final r in resourceSet) {
    inventoryN[r] = countResourceOnGpTiles(
      inventory: preClearInventory,
      forbidden: forbidden,
      resource: r,
    );
  }

  var map = tileMapOldWorld;
  var ws = game.worldState;
  final cleared = clearGreatPowerOldWorldTerrainResources(
    mapIn: map,
    game: game,
    resMapIn: ws.resourceByTileKey,
    tileStateIn: ws.tileState,
  );
  map = cleared.$1;
  var resMap = cleared.$2;
  final tileState = cleared.$3;
  ws = ws.copyWith(tileState: tileState, resourceByTileKey: resMap);
  game = game.withWorldState(ws);

  for (final r in resourceSet) {
    final nR = inventoryN[r] ?? 0;
    if (nR <= 0) continue;
    final out = redistributeOneResource(
      mapIn: map,
      resMapIn: resMap,
      r: r,
      nR: nR,
      resourceRules: resourceRules,
      gpIdsSorted: gpIdsSorted,
      gpIds: gpIds,
      ownerByLocal: ownerByLocal,
      forbidden: forbidden,
      setupSeedBase: setupSeedBase,
    );
    map = out.map;
    resMap = out.resMap;
    ws = game.worldState.copyWith(
      tileState: tileState,
      resourceByTileKey: resMap,
    );
    game = game.withWorldState(ws);
  }

  final postInventory = buildGpOwTileInventory(
    map: map,
    ownerByLocal: ownerByLocal,
    gpIds: gpIds,
  );
  final fairness = fairnessScore(
    gpIdsSorted: gpIdsSorted,
    inventoryN: inventoryN,
    inventory: postInventory,
    forbidden: forbidden,
    resourceSet: resourceSet,
  );

  setupLog.i(
    'GP Old World resource redistribution complete fairnessMaxAbsDev=$fairness',
  );

  return (game: game, tileMap: map, fairnessScore: fairness);
}
