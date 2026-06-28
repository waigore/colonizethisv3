part of 'gp_old_world_resource_redistribution.dart';

// GP Old World resource-redistribution tile-scan + fairness helpers, extracted
// from `gp_old_world_resource_redistribution.dart` for maintainability
// (Refs #3290 Phase 0 file-split). Behaviour-preserving move: this is a
// `part of` the redistribution library, so imports, shared helpers, the
// `GpOldWorldResourceRedistributionInfeasibleException` type, and private
// visibility are all unchanged.

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
  if (map.resourceGrid == null) return 0;
  var n = 0;
  visitGpOwLandTiles(
    map: map,
    ownerByLocal: ownerByLocal,
    gpIds: gpIds,
    visit: (x, y, local, owner, key) {
      if (forbidden.contains(key)) return;
      if (map.resourceAt(x, y) == resource) n++;
    },
  );
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
  visitGpOwLandTiles(
    map: map,
    ownerByLocal: ownerByLocal,
    gpIds: gpSet,
    visit: (x, y, local, owner, key) {
      if (owner != gp) return;
      if (forbidden.contains(key)) return;
      if (map.resourceAt(x, y) == r) a++;
    },
  );
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
  final ownerByLocal = gpOwnerByLocalProvinceId(game);
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
  final gpIds = gpIdsSortedFromPlayers(game).toSet();
  final ownerByLocal = gpOwnerByLocalProvinceId(game);
  if (map.resourceGrid == null) return (map, resMap, tileState);

  visitGpOwLandTiles(
    map: map,
    ownerByLocal: ownerByLocal,
    gpIds: gpIds,
    visit: (x, y, local, owner, key) {
      final hadRes = map.resourceAt(x, y) != null;
      final hadEntry = resMap.containsKey(key);
      final hadImp = tileState.improvementLevel(key) != 0;
      if (!hadRes && !hadEntry && !hadImp) return;
      map = map.withResourceAt(x, y, null);
      resMap.remove(key);
      tileState = tileState.setImprovement(key, 0);
    },
  );
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
  visitGpOwLandTiles(
    map: map,
    ownerByLocal: ownerByLocal,
    gpIds: gpIds,
    visit: (x, y, local, owner, key) {
      if (owner != gp) return;
      if (forbidden.contains(key)) return;
      if (used.contains(key)) return;
      if (map.resourceAt(x, y) != null) return;
      final t = map.terrainAt(x, y);
      if (t == null) return;
      if (!rules.isAllowedOnTerrain(r, t)) return;
      c++;
    },
  );
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
  visitGpOwLandTiles(
    map: map,
    ownerByLocal: ownerByLocal,
    gpIds: gpIds,
    visit: (x, y, local, owner, key) {
      if (owner != gp) return;
      if (forbidden.contains(key)) return;
      if (used.contains(key)) return;
      if (map.resourceAt(x, y) != null) return;
      final t = map.terrainAt(x, y);
      if (t == null) return;
      if (!rules.isAllowedOnTerrain(r, t)) return;
      candidates.add(key);
    },
  );
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
