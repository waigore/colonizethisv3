// SPEC/game/tile-map-and-generation.md; SPEC/program/game-setup-pipeline.md (§7d.redist).

import 'dart:math';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/src/logging.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../constants.dart';
import 'package:colonizethis_world/src/world/game_world_mutations.dart';
import 'package:colonizethis_world/src/world/province_lookup.dart';
import 'package:colonizethis_world/src/world/tile_key_coordinates.dart';
import 'setup_exceptions.dart';
import 'town_capital_occupancy.dart';

// GP Old World resource-redistribution concern fragments (Refs #3290 Phase 0
// file-split). Each `part of` fragment shares this library's imports and
// private scope, so the move is behaviour-preserving — symbols, visibility,
// and helper sharing are unchanged.
part 'gp_old_world_resource_redistribution_tile_scans.dart';
part 'gp_old_world_resource_redistribution_quota_placement.dart';

/// Salt for `Object.hash` when building per-resource shuffle RNGs.
/// ASCII "REDO" packed (issue #1837 / SPEC/program/game-setup-pipeline.md).
const int kGpOwResourceRedistributionSalt = 0x5245444f;

/// Thrown when a resource cannot be placed back on GP Old World tiles after spillover.
class GpOldWorldResourceRedistributionInfeasibleException
    extends SetupConfigConstraintException {
  static const codeValue = 'gp_ow_resource_redistribution_infeasible';

  GpOldWorldResourceRedistributionInfeasibleException({
    required Resource resource,
    required String details,
  }) : super(code: codeValue, details: 'resource=${resource.name}: $details');
}

/// After redistribution: counts [resource] on GP-owned OW land (excl. town/capital).
int countResourceOnGpOldWorldTiles({
  required Game game,
  required TileMapResult map,
  required Resource resource,
}) {
  final gpIds = game.players.map((p) => p.id).toSet();
  final ownerByLocal = _ownerByLocalProvinceId(game);
  final forbidden = collectTownAndCapitalTileKeys(game);
  return _countResourceOnGpTiles(
    map: map,
    ownerByLocal: ownerByLocal,
    gpIds: gpIds,
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
    logicLog.i(
      'skip GP Old World resource redistribution (missing terrain or resource grid)',
    );
    return (game: game, tileMap: tileMapOldWorld, fairnessScore: 0);
  }

  // Preserve runtime player slot order (gp1, gp2, …); do not lex-sort (gp10 < gp2).
  final gpIdsSorted = game.players.map((p) => p.id).toList();
  final gpIds = gpIdsSorted.toSet();
  final g = gpIdsSorted.length;
  if (g == 0) {
    return (game: game, tileMap: tileMapOldWorld, fairnessScore: 0);
  }

  final ownerByLocal = _ownerByLocalProvinceId(game);
  final forbidden = collectTownAndCapitalTileKeys(game);
  final resourceSet = _resourcesInRedistributionSet(resourceRules);

  final inventoryN = <Resource, int>{};
  for (final r in resourceSet) {
    inventoryN[r] = _countResourceOnGpTiles(
      map: tileMapOldWorld,
      ownerByLocal: ownerByLocal,
      gpIds: gpIds,
      forbidden: forbidden,
      resource: r,
    );
  }

  var map = tileMapOldWorld;
  var ws = game.worldState;
  final cleared = _clearGreatPowerOldWorldTerrainResources(
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
    final out = _redistributeOneResource(
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

  final fairness = _fairnessScore(
    gpIdsSorted: gpIdsSorted,
    inventoryN: inventoryN,
    game: game,
    map: map,
    resourceSet: resourceSet,
  );

  logicLog.i(
    'GP Old World resource redistribution complete fairnessMaxAbsDev=$fairness',
  );

  return (game: game, tileMap: map, fairnessScore: fairness);
}
