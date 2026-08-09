// SPEC/game/tile-map-and-generation.md; SPEC/program/game-setup-pipeline.md (§7d.redist).
// GP Old World resource-redistribution tile-scan + fairness helpers
// (Refs #4086 Slice B de-part).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import 'gp_old_world_tile_scan.dart';

List<Resource> resourcesInRedistributionSet(ResourceRules rules) {
  return Resource.values
      .where((r) => rules.isAllowedInRegion(r, kRegionOldWorld))
      .toList();
}

/// One GP-owned Old World land tile snapshotted for a redistribution pass.
class GpOwTileInvEntry {
  const GpOwTileInvEntry({
    required this.x,
    required this.y,
    required this.localProvinceId,
    required this.ownerId,
    required this.tileKey,
    required this.resource,
    required this.terrain,
  });

  final int x;
  final int y;
  final String localProvinceId;
  final String ownerId;
  final String tileKey;
  final Resource? resource;
  final TerrainType? terrain;
}

/// Builds a single GP-land inventory from [map] for this redistribution pass.
List<GpOwTileInvEntry> buildGpOwTileInventory({
  required TileMapResult map,
  required Map<String, String> ownerByLocal,
  required Set<String> gpIds,
}) {
  final out = <GpOwTileInvEntry>[];
  visitGpOwLandTiles(
    map: map,
    ownerByLocal: ownerByLocal,
    gpIds: gpIds,
    visit: (x, y, local, owner, key) {
      out.add(
        GpOwTileInvEntry(
          x: x,
          y: y,
          localProvinceId: local,
          ownerId: owner,
          tileKey: key,
          resource: map.resourceAt(x, y),
          terrain: map.terrainAt(x, y),
        ),
      );
    },
  );
  return out;
}

/// Counts resource [r] on GP-owned OW land tiles (excluding town/capital).
int countResourceOnGpTiles({
  required List<GpOwTileInvEntry> inventory,
  required Set<String> forbidden,
  required Resource resource,
}) {
  var n = 0;
  for (final t in inventory) {
    if (forbidden.contains(t.tileKey)) continue;
    if (t.resource == resource) n++;
  }
  return n;
}

int _countResourceTilesForGp({
  required List<GpOwTileInvEntry> inventory,
  required Set<String> forbidden,
  required String gp,
  required Resource r,
}) {
  var a = 0;
  for (final t in inventory) {
    if (t.ownerId != gp) continue;
    if (forbidden.contains(t.tileKey)) continue;
    if (t.resource == r) a++;
  }
  return a;
}

double fairnessScore({
  required List<String> gpIdsSorted,
  required Map<Resource, int> inventoryN,
  required List<GpOwTileInvEntry> inventory,
  required Set<String> forbidden,
  required List<Resource> resourceSet,
}) {
  final g = gpIdsSorted.length;
  if (g == 0) return 0;
  var maxDev = 0.0;
  for (final gp in gpIdsSorted) {
    for (final r in resourceSet) {
      final nR = inventoryN[r] ?? 0;
      final expected = nR / g;
      final a = _countResourceTilesForGp(
        inventory: inventory,
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
clearGreatPowerOldWorldTerrainResources({
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

int eligibleEmptyCountForGp({
  required List<GpOwTileInvEntry> inventory,
  required Resource r,
  required ResourceRules rules,
  required String gp,
  required Set<String> forbidden,
  required Set<String> used,
}) {
  var c = 0;
  for (final t in inventory) {
    if (t.ownerId != gp) continue;
    if (forbidden.contains(t.tileKey)) continue;
    if (used.contains(t.tileKey)) continue;
    if (t.resource != null) continue;
    final terrain = t.terrain;
    if (terrain == null) continue;
    if (!rules.isAllowedOnTerrain(r, terrain)) continue;
    c++;
  }
  return c;
}

String? firstLexEligibleEmptyTileForGp({
  required List<GpOwTileInvEntry> inventory,
  required Resource r,
  required ResourceRules rules,
  required String gp,
  required Set<String> forbidden,
  required Set<String> used,
}) {
  final candidates = <String>[];
  for (final t in inventory) {
    if (t.ownerId != gp) continue;
    if (forbidden.contains(t.tileKey)) continue;
    if (used.contains(t.tileKey)) continue;
    if (t.resource != null) continue;
    final terrain = t.terrain;
    if (terrain == null) continue;
    if (!rules.isAllowedOnTerrain(r, terrain)) continue;
    candidates.add(t.tileKey);
  }
  candidates.sort();
  return candidates.isEmpty ? null : candidates.first;
}

TileMapResult placeResourceAtKey(TileMapResult map, String key, Resource r) {
  final parsed = parseTileKeyCoordinates(key);
  if (parsed == null) return map;
  return map.withResourceAt(parsed.x, parsed.y, r);
}

int sumPlacedAll(Map<String, int> placed, List<String> gpIdsSorted) {
  var sumPlaced = 0;
  for (final id in gpIdsSorted) {
    sumPlaced += placed[id] ?? 0;
  }
  return sumPlaced;
}
