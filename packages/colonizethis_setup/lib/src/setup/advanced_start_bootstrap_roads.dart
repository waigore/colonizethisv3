// Road wiring helpers for advanced-start bootstrap. SPEC/game/advanced-starts.md.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_world/colonizethis_world.dart';
import 'grid_bfs.dart';
import 'setup_topology_adjacency.dart';

const int _kAdvancedStartRoadLevel = 1;

TileMapState raiseRoadAtLeast(TileMapState tileState, String tileKey, int level) {
  final current = tileState.roadLevel(tileKey);
  if (current >= level) return tileState;
  return tileState.setRoadLevel(tileKey, level);
}

Map<String, String> coordToTileKeyForRegion(
  WorldState ws,
  String regionId,
) {
  final m = <String, String>{};
  final byProvince = ws.tileKeysByRegionAndProvince[regionId];
  if (byProvince == null) return m;
  for (final list in byProvince.values) {
    for (final tk in list) {
      final coords = parseTileKeyCoordinates(tk);
      if (coords == null || coords.regionId != regionId) continue;
      m[gridCoordKey(coords.x, coords.y)] = tk;
    }
  }
  return m;
}

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
  int minRoadLevel = _kAdvancedStartRoadLevel,
}) {
  var next = tileState;
  for (final key in pathTileKeys) {
    next = raiseRoadAtLeast(next, key, minRoadLevel);
  }
  return next;
}

WorldState applySeaboardPortAndRoadToTile({
  required WorldState worldState,
  required String provinceId,
  required String inlandTileKey,
  required MapTopology topology,
  required TileMapResult map,
}) {
  final coords = parseTileKeyCoordinates(inlandTileKey);
  if (coords == null) return worldState;
  final regionId = coords.regionId;
  final localProvinceId = ProvinceId.localIdFrom(provinceId);

  if (!isProvinceSeaBound(topology, localProvinceId)) {
    return worldState;
  }

  var tileState = worldState.tileState;
  var ports = Map<String, String>.from(worldState.portsByProvinceSeaboard);
  final provinceIds = provinceNodeIds(topology);
  final seaZoneIds = seaZonesAdjacentToProvince(
    topology,
    localProvinceId,
  ).toList()
    ..sort();

  for (final seaZoneId in seaZoneIds) {
    final portKeyProvSea = '$provinceId|$seaZoneId';
    if (ports.containsKey(portKeyProvSea)) continue;

    final inlandTouchesSea = tileAdjacentToSeaZone(
      coords.x,
      coords.y,
      map,
      topology,
      seaZoneId,
      provinceIds: provinceIds,
    );
    if (inlandTouchesSea) {
      tileState = raiseRoadAtLeast(tileState, inlandTileKey, 4);
      ports[portKeyProvSea] = inlandTileKey;
      continue;
    }

    int? bestDist;
    int? bestX;
    int? bestY;
    for (var y = 0; y < map.height; y++) {
      for (var x = 0; x < map.width; x++) {
        if (map.cell(x, y) != localProvinceId) continue;
        if (!tileAdjacentToSeaZone(
          x,
          y,
          map,
          topology,
          seaZoneId,
          provinceIds: provinceIds,
        )) {
          continue;
        }
        final dist = (x - coords.x).abs() + (y - coords.y).abs();
        if (bestDist == null || dist < bestDist) {
          bestDist = dist;
          bestX = x;
          bestY = y;
        }
      }
    }
    if (bestX == null || bestY == null) continue;

    final portKey = CapitalTile.tileKey(
      regionId,
      provinceId,
      bestX,
      bestY,
    );
    tileState = raiseRoadAtLeast(tileState, inlandTileKey, _kAdvancedStartRoadLevel);
    tileState = raiseRoadAtLeast(tileState, portKey, 4);
    ports[portKeyProvSea] = portKey;

    final parents = bfsGridParents(
      startX: bestX,
      startY: bestY,
      width: map.width,
      height: map.height,
      passable: (x, y) => map.cell(x, y) == localProvinceId,
    );
    final path = reconstructGridPath(
      parents: parents,
      toX: coords.x,
      toY: coords.y,
    );
    if (path != null) {
      for (final p in path) {
        final key = CapitalTile.tileKey(regionId, provinceId, p.$1, p.$2);
        if (key == portKey) continue;
        tileState = raiseRoadAtLeast(tileState, key, _kAdvancedStartRoadLevel);
      }
    }
  }

  return worldState.copyWith(
    tileState: tileState,
    portsByProvinceSeaboard: ports,
  );
}
