part of 'gp_old_world_resource_redistribution.dart';

// GP Old World resource-redistribution tile-scan + fairness helpers, extracted
// from `gp_old_world_resource_redistribution.dart` for maintainability
// (Refs #3290 Phase 0 file-split). Behaviour-preserving move: this is a
// `part of` the redistribution library, so imports, shared helpers, the
// `GpOldWorldResourceRedistributionInfeasibleException` type, and private
// visibility are all unchanged.

String _owTileKey(String localProvinceId, int x, int y) => CapitalTile.tileKey(
  kRegionOldWorld,
  ProvinceId.full(kRegionOldWorld, localProvinceId),
  x,
  y,
);

/// Maps local province grid id → owning faction id for Old World provinces.
Map<String, String> _ownerByLocalProvinceId(Game game) {
  final m = <String, String>{};
  for (final p in game.worldState.provincesForRegion(kRegionOldWorld)) {
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
