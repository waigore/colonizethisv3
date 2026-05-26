// SPEC/game/tile-map-and-generation.md; SPEC/program/game-setup-pipeline.md (§7d.redist).

import 'dart:math';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/src/logging.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../constants.dart';
import '../world/game_world_mutations.dart';
import '../world/tile_key_coordinates.dart';
import 'setup_exceptions.dart';
import 'town_capital_occupancy.dart';

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

String _owTileKey(String localProvinceId, int x, int y) => CapitalTile.tileKey(
  kRegionOldWorld,
  ProvinceId.full(kRegionOldWorld, localProvinceId),
  x,
  y,
);

/// Maps local province grid id → owning faction id for Old World provinces.
Map<String, String> _ownerByLocalProvinceId(Game game) {
  final m = <String, String>{};
  for (final p in game.worldState.oldWorld.provinces) {
    m[ProvinceId.localIdFrom(p.id)] = p.ownerId ?? '';
  }
  return m;
}

bool _isGpId(String id, Set<String> gpIds) => gpIds.contains(id);

List<Resource> _resourcesInRedistributionSet(ResourceRules rules) {
  return Resource.values
      .where((r) => rules.isAllowedInRegion(r, kRegionOldWorld))
      .toList();
}

/// Counts resource [r] on GP-owned OW land tiles (excluding town/capital), from [map].
int _countResourceOnGpTiles({
  required TileMapResult map,
  required Map<String, String> ownerByLocal,
  required Set<String> gpIds,
  required Set<String> forbidden,
  required Resource resource,
}) {
  var n = 0;
  final grid = map.resourceGrid;
  if (grid == null) return 0;
  for (var y = 0; y < map.height; y++) {
    for (var x = 0; x < map.width; x++) {
      final local = map.cell(x, y);
      final owner = ownerByLocal[local];
      if (owner == null || !_isGpId(owner, gpIds)) continue;
      if (map.terrainAt(x, y) == null) continue;
      final key = _owTileKey(local, x, y);
      if (forbidden.contains(key)) continue;
      if (grid[y][x] == resource) n++;
    }
  }
  return n;
}

int _countResourceTilesForGp({
  required TileMapResult map,
  required Map<String, String> ownerByLocal,
  required Set<String> gpSet,
  required Set<String> forbidden,
  required String gp,
  required Resource r,
}) {
  var a = 0;
  for (var y = 0; y < map.height; y++) {
    for (var x = 0; x < map.width; x++) {
      final local = map.cell(x, y);
      final owner = ownerByLocal[local];
      if (owner == null || owner != gp) continue;
      if (!_isGpId(owner, gpSet)) continue;
      if (map.terrainAt(x, y) == null) continue;
      final key = _owTileKey(local, x, y);
      if (forbidden.contains(key)) continue;
      if (map.resourceAt(x, y) == r) a++;
    }
  }
  return a;
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

double _fairnessScore({
  required List<String> gpIdsSorted,
  required Map<Resource, int> inventoryN,
  required Game game,
  required TileMapResult map,
  required List<Resource> resourceSet,
}) {
  final g = gpIdsSorted.length;
  if (g == 0) return 0;
  final ownerByLocal = _ownerByLocalProvinceId(game);
  final gpSet = gpIdsSorted.toSet();
  final forbidden = collectTownAndCapitalTileKeys(game);
  var maxDev = 0.0;
  for (final gp in gpIdsSorted) {
    for (final r in resourceSet) {
      final nR = inventoryN[r] ?? 0;
      final expected = nR / g;
      final a = _countResourceTilesForGp(
        map: map,
        ownerByLocal: ownerByLocal,
        gpSet: gpSet,
        forbidden: forbidden,
        gp: gp,
        r: r,
      );
      final dev = (a - expected).abs();
      if (dev > maxDev) maxDev = dev;
    }
  }
  return maxDev;
}

/// Clears resources and extraction on all GP-owned OW land tiles (including town/capital).
(TileMapResult map, Map<String, String> resMap, TileMapState tileState)
_clearGreatPowerOldWorldTerrainResources({
  required TileMapResult mapIn,
  required Game game,
  required Map<String, String> resMapIn,
  required TileMapState tileStateIn,
}) {
  var map = mapIn;
  var resMap = Map<String, String>.from(resMapIn);
  var tileState = tileStateIn;
  final gpIds = game.players.map((p) => p.id).toSet();
  final ownerByLocal = _ownerByLocalProvinceId(game);
  if (map.resourceGrid == null) return (map, resMap, tileState);

  for (var y = 0; y < map.height; y++) {
    for (var x = 0; x < map.width; x++) {
      final local = map.cell(x, y);
      final owner = ownerByLocal[local];
      if (owner == null || !_isGpId(owner, gpIds)) continue;
      if (map.terrainAt(x, y) == null) continue;
      final key = _owTileKey(local, x, y);
      final hadRes = map.resourceAt(x, y) != null;
      final hadEntry = resMap.containsKey(key);
      final hadImp = tileState.improvementLevel(key) != 0;
      if (!hadRes && !hadEntry && !hadImp) continue;
      map = map.withResourceAt(x, y, null);
      resMap.remove(key);
      tileState = tileState.setImprovement(key, 0);
    }
  }
  return (map, resMap, tileState);
}

int _eligibleEmptyCountForGp({
  required TileMapResult map,
  required Resource r,
  required ResourceRules rules,
  required String gp,
  required Map<String, String> ownerByLocal,
  required Set<String> gpIds,
  required Set<String> forbidden,
  required Set<String> used,
}) {
  var c = 0;
  for (var y = 0; y < map.height; y++) {
    for (var x = 0; x < map.width; x++) {
      final local = map.cell(x, y);
      final owner = ownerByLocal[local];
      if (owner == null || owner != gp) continue;
      if (!_isGpId(owner, gpIds)) continue;
      final t = map.terrainAt(x, y);
      if (t == null) continue;
      final key = _owTileKey(local, x, y);
      if (forbidden.contains(key)) continue;
      if (used.contains(key)) continue;
      if (map.resourceAt(x, y) != null) continue;
      if (!rules.isAllowedOnTerrain(r, t)) continue;
      c++;
    }
  }
  return c;
}

String? _firstLexEligibleEmptyTileForGp({
  required TileMapResult map,
  required Resource r,
  required ResourceRules rules,
  required String gp,
  required Map<String, String> ownerByLocal,
  required Set<String> gpIds,
  required Set<String> forbidden,
  required Set<String> used,
}) {
  final candidates = <String>[];
  for (var y = 0; y < map.height; y++) {
    for (var x = 0; x < map.width; x++) {
      final local = map.cell(x, y);
      final owner = ownerByLocal[local];
      if (owner == null || owner != gp) continue;
      if (!_isGpId(owner, gpIds)) continue;
      final t = map.terrainAt(x, y);
      if (t == null) continue;
      final key = _owTileKey(local, x, y);
      if (forbidden.contains(key)) continue;
      if (used.contains(key)) continue;
      if (map.resourceAt(x, y) != null) continue;
      if (!rules.isAllowedOnTerrain(r, t)) continue;
      candidates.add(key);
    }
  }
  candidates.sort();
  return candidates.isEmpty ? null : candidates.first;
}

TileMapResult _placeResourceAtKey(TileMapResult map, String key, Resource r) {
  final parsed = parseTileKeyCoordinates(key);
  if (parsed == null) return map;
  return map.withResourceAt(parsed.x, parsed.y, r);
}

int _sumPlacedAll(Map<String, int> placed, List<String> gpIdsSorted) {
  var sumPlaced = 0;
  for (final id in gpIdsSorted) {
    sumPlaced += placed[id] ?? 0;
  }
  return sumPlaced;
}

/// One pass: place resources for each GP until targets met or no eligible tile.
TileMapResult _runGpPlacementPass({
  required TileMapResult mapIn,
  required Map<String, String> resMap,
  required List<String> shuffled,
  required Map<String, int> targets,
  required Map<String, int> placed,
  required Set<String> used,
  required Resource r,
  required ResourceRules resourceRules,
  required Map<String, String> ownerByLocal,
  required Set<String> gpIds,
  required Set<String> forbidden,
}) {
  var map = mapIn;
  for (final gp in shuffled) {
    while (true) {
      if ((targets[gp] ?? 0) <= (placed[gp] ?? 0)) break;
      final key = _firstLexEligibleEmptyTileForGp(
        map: map,
        r: r,
        rules: resourceRules,
        gp: gp,
        ownerByLocal: ownerByLocal,
        gpIds: gpIds,
        forbidden: forbidden,
        used: used,
      );
      if (key == null) break;
      map = _placeResourceAtKey(map, key, r);
      used.add(key);
      placed[gp] = (placed[gp] ?? 0) + 1;
      resMap[key] = r.name;
    }
  }
  return map;
}

/// Caps targets to reachable counts; returns surplus moved into [pool].
int _accumulateSpilloverPool({
  required List<String> shuffled,
  required Map<String, int> targets,
  required Map<String, int> placed,
  required TileMapResult map,
  required Resource r,
  required ResourceRules resourceRules,
  required Map<String, String> ownerByLocal,
  required Set<String> gpIds,
  required Set<String> forbidden,
  required Set<String> used,
}) {
  var pool = 0;
  for (final gp in shuffled) {
    final tgt = targets[gp] ?? 0;
    final pl = placed[gp] ?? 0;
    final deficit = tgt - pl;
    if (deficit <= 0) continue;
    final eg = _eligibleEmptyCountForGp(
      map: map,
      r: r,
      rules: resourceRules,
      gp: gp,
      ownerByLocal: ownerByLocal,
      gpIds: gpIds,
      forbidden: forbidden,
      used: used,
    );
    final maxTarget = pl + eg;
    if (tgt <= maxTarget) continue;
    pool += tgt - maxTarget;
    targets[gp] = maxTarget;
  }
  return pool;
}

({int newPool, bool anyIncrement}) _applyOneQuotaPoolRound({
  required int pool,
  required List<String> shuffled,
  required Map<String, int> targets,
  required Map<String, int> placed,
  required TileMapResult map,
  required Resource r,
  required ResourceRules resourceRules,
  required Map<String, String> ownerByLocal,
  required Set<String> gpIds,
  required Set<String> forbidden,
  required Set<String> used,
}) {
  var p = pool;
  var moved = false;
  for (final h in shuffled) {
    if (p <= 0) break;
    final pl = placed[h] ?? 0;
    final tgt = targets[h] ?? 0;
    final eg = _eligibleEmptyCountForGp(
      map: map,
      r: r,
      rules: resourceRules,
      gp: h,
      ownerByLocal: ownerByLocal,
      gpIds: gpIds,
      forbidden: forbidden,
      used: used,
    );
    final maxTarget = pl + eg;
    if (tgt >= maxTarget) continue;
    targets[h] = tgt + 1;
    p--;
    moved = true;
  }
  return (newPool: p, anyIncrement: moved);
}

void _distributeQuotaPool({
  required int initialPool,
  required List<String> shuffled,
  required Map<String, int> targets,
  required Map<String, int> placed,
  required TileMapResult map,
  required Resource r,
  required ResourceRules resourceRules,
  required Map<String, String> ownerByLocal,
  required Set<String> gpIds,
  required Set<String> forbidden,
  required Set<String> used,
  required int sumPlaced,
  required int nR,
}) {
  var pool = initialPool;
  while (pool > 0) {
    final round = _applyOneQuotaPoolRound(
      pool: pool,
      shuffled: shuffled,
      targets: targets,
      placed: placed,
      map: map,
      r: r,
      resourceRules: resourceRules,
      ownerByLocal: ownerByLocal,
      gpIds: gpIds,
      forbidden: forbidden,
      used: used,
    );
    pool = round.newPool;
    if (!round.anyIncrement) {
      throw GpOldWorldResourceRedistributionInfeasibleException(
        resource: r,
        details:
            'cannot distribute quota pool=$pool sumPlaced=$sumPlaced nR=$nR',
      );
    }
  }
}

({TileMapResult map, Map<String, String> resMap}) _redistributeOneResource({
  required TileMapResult mapIn,
  required Map<String, String> resMapIn,
  required Resource r,
  required int nR,
  required ResourceRules resourceRules,
  required List<String> gpIdsSorted,
  required Set<String> gpIds,
  required Map<String, String> ownerByLocal,
  required Set<String> forbidden,
  required int setupSeedBase,
}) {
  var map = mapIn;
  var resMap = Map<String, String>.from(resMapIn);
  final g = gpIdsSorted.length;
  final rnd = Random(
    Object.hash(setupSeedBase, kGpOwResourceRedistributionSalt, r.index),
  );
  final shuffled = List<String>.from(gpIdsSorted)..shuffle(rnd);

  final base = nR ~/ g;
  final rem = nR % g;
  final targets = <String, int>{};
  for (var i = 0; i < shuffled.length; i++) {
    targets[shuffled[i]] = base + (i < rem ? 1 : 0);
  }

  final placed = <String, int>{for (final id in gpIdsSorted) id: 0};
  final used = <String>{};

  var totalCapacity = 0;
  for (final gp in gpIdsSorted) {
    totalCapacity += _eligibleEmptyCountForGp(
      map: map,
      r: r,
      rules: resourceRules,
      gp: gp,
      ownerByLocal: ownerByLocal,
      gpIds: gpIds,
      forbidden: forbidden,
      used: const {},
    );
  }
  if (nR > totalCapacity) {
    throw GpOldWorldResourceRedistributionInfeasibleException(
      resource: r,
      details:
          'N_r=$nR exceeds total terrain-eligible capacity=$totalCapacity on GP Old World tiles',
    );
  }

  while (true) {
    map = _runGpPlacementPass(
      mapIn: map,
      resMap: resMap,
      shuffled: shuffled,
      targets: targets,
      placed: placed,
      used: used,
      r: r,
      resourceRules: resourceRules,
      ownerByLocal: ownerByLocal,
      gpIds: gpIds,
      forbidden: forbidden,
    );

    final sumPlaced = _sumPlacedAll(placed, gpIdsSorted);
    if (sumPlaced >= nR) {
      return (map: map, resMap: resMap);
    }

    final pool = _accumulateSpilloverPool(
      shuffled: shuffled,
      targets: targets,
      placed: placed,
      map: map,
      r: r,
      resourceRules: resourceRules,
      ownerByLocal: ownerByLocal,
      gpIds: gpIds,
      forbidden: forbidden,
      used: used,
    );

    if (pool == 0) {
      throw GpOldWorldResourceRedistributionInfeasibleException(
        resource: r,
        details:
            'stalled with sumPlaced=$sumPlaced nR=$nR after spillover (pool=0)',
      );
    }

    _distributeQuotaPool(
      initialPool: pool,
      shuffled: shuffled,
      targets: targets,
      placed: placed,
      map: map,
      r: r,
      resourceRules: resourceRules,
      ownerByLocal: ownerByLocal,
      gpIds: gpIds,
      forbidden: forbidden,
      used: used,
      sumPlaced: sumPlaced,
      nR: nR,
    );
  }
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
