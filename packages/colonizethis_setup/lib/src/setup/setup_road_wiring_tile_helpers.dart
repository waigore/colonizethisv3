// Coord / owned-tile / BFS path helpers for road wiring.
// Seaboard apply remains in setup_road_wiring.dart (Refs #4349 Slice A).

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import 'grid_bfs.dart';

/// Raise [tileKey] road level to at least [level] (no-op when already higher).
TileMapState raiseRoadAtLeast(
  TileMapState tileState,
  String tileKey,
  int level,
) {
  final current = tileState.roadLevel(tileKey);
  if (current >= level) return tileState;
  return tileState.setRoadLevel(tileKey, level);
}

/// Build `gridCoordKey(x,y) → tileKey` for one region's province tile lists.
Map<String, String> coordToTileKeysFromProvinceLists(
  String regionId,
  Map<String, List<String>> byProvince,
) {
  final m = <String, String>{};
  for (final list in byProvince.values) {
    for (final tk in list) {
      final coords = parseTileKeyCoordinates(tk);
      if (coords == null || coords.regionId != regionId) continue;
      m[gridCoordKey(coords.x, coords.y)] = tk;
    }
  }
  return m;
}

/// Coord→tile map for [regionId] from [WorldState.tileKeysByRegionAndProvince].
Map<String, String> coordToTileKeyForRegion(WorldState ws, String regionId) {
  final byProvince = ws.tileKeysByRegionAndProvince[regionId];
  if (byProvince == null) return <String, String>{};
  return coordToTileKeysFromProvinceLists(regionId, byProvince);
}

/// Multi-region coord→tile maps from the full tile-keys-by-region structure.
Map<String, Map<String, String>> coordToTileKeyByRegion(
  Map<String, Map<String, List<String>>> tileKeysByRegion,
) {
  final out = <String, Map<String, String>>{};
  for (final entry in tileKeysByRegion.entries) {
    out[entry.key] = coordToTileKeysFromProvinceLists(entry.key, entry.value);
  }
  return out;
}

/// Tile keys in [regionId] owned by [factionId].
Set<String> ownedTileKeysForFaction(
  WorldState ws,
  String regionId,
  String factionId,
) {
  final keys = <String>{};
  final byProvince = ws.tileKeysByRegionAndProvince[regionId];
  if (byProvince == null) return keys;
  for (final p in ws.provincesForRegion(regionId)) {
    if (p.ownerId != factionId) continue;
    final list = byProvince[p.id];
    if (list == null) continue;
    keys.addAll(list);
  }
  return keys;
}

/// BFS parent map (tileKey → predecessor toward [startTileKey]) over [allowed].
Map<String, String> bfsParentsFromTileKey({
  required String startTileKey,
  required Set<String> allowed,
  required Map<String, String> coordToKey,
  required int mapWidth,
  required int mapHeight,
}) {
  final startXY = parseTileKeyCoordinates(startTileKey);
  if (startXY == null) return {startTileKey: startTileKey};
  final (startX, startY) = (startXY.x, startXY.y);

  final coordParents = bfsGridParents(
    startX: startX,
    startY: startY,
    width: mapWidth,
    height: mapHeight,
    passable: (x, y) {
      final tile = coordToKey[gridCoordKey(x, y)];
      return tile != null && allowed.contains(tile);
    },
  );

  final parent = <String, String>{startTileKey: startTileKey};
  for (final entry in coordParents.entries) {
    final tile = coordToKey[entry.key];
    if (tile == null) continue;
    final pc = entry.value;
    final parentTile = coordToKey[gridCoordKey(pc.$1, pc.$2)];
    if (parentTile == null) continue;
    parent[tile] = parentTile;
  }
  return parent;
}

/// Walk [parent] from [fromTileKey] toward [hubTileKey], collecting tile keys.
Set<String> pathTileKeysTowardHub({
  required String fromTileKey,
  required String hubTileKey,
  required Map<String, String> parent,
}) {
  final out = <String>{};
  var k = fromTileKey;
  while (true) {
    out.add(k);
    if (k == hubTileKey) break;
    final pr = parent[k];
    if (pr == null || pr == k) break;
    k = pr;
  }
  return out;
}

TileMapState wireRoadPathsOnOwnedTiles({
  required TileMapState tileState,
  required Iterable<String> pathTileKeys,
  int minRoadLevel = 1,
}) {
  var next = tileState;
  for (final key in pathTileKeys) {
    next = raiseRoadAtLeast(next, key, minRoadLevel);
  }
  return next;
}
