// Shared road / seaboard-port wiring for capital choice, init town roads, and
// advanced-start bootstrap. SPEC/game/capital-and-connectivity.md;
// SPEC/game/advanced-starts.md; SPEC/program/game-setup-pipeline.md.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import 'grid_bfs.dart';
import 'setup_exceptions.dart';
import 'setup_topology_adjacency.dart';
import 'tile_cell_scan.dart';

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

/// Nearest province tile adjacent to [seaZoneId], Manhattan-closest to inland.
(int x, int y)? nearestSeaboardTileInProvinceForSeaZone({
  required TileMapResult map,
  required MapTopology topology,
  required String localProvinceId,
  required String seaZoneId,
  required Set<String> provinceIds,
  required int inlandX,
  required int inlandY,
}) {
  var bestDist = -1;
  var bestX = -1;
  var bestY = -1;
  forEachProvinceCell(map, localProvinceId, (x, y) {
    if (!tileAdjacentToSeaZone(
      x,
      y,
      map,
      topology,
      seaZoneId,
      provinceIds: provinceIds,
    )) {
      return;
    }
    final dist = (x - inlandX).abs() + (y - inlandY).abs();
    if (bestDist >= 0 && dist >= bestDist) return;
    bestDist = dist;
    bestX = x;
    bestY = y;
  });
  if (bestDist < 0) return null;
  return (bestX, bestY);
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

/// How to handle a sea zone with no coastal tile in the province.
enum SeaboardMissingCoastalPolicy {
  /// Capital choice: throw [SetupTopologyDataException].
  throwException,

  /// Advanced-start: skip this sea zone.
  skip,
}

/// How to handle an already-recorded `portsByProvinceSeaboard` entry.
enum SeaboardExistingPortPolicy { overwrite, skip }

/// How to handle a failed province-tile path from port to inland.
enum SeaboardPathMissingPolicy {
  /// Capital choice: raise only the start cell (then skip the port key).
  useStartOnly,

  /// Advanced-start: skip path road raises.
  skip,
}

/// Shared seaboard port + road skeleton for capital choice and advanced-start.
WorldState applySeaboardPortAndRoadWiring({
  required WorldState worldState,
  required String provinceId,
  required String inlandTileKey,
  required int inlandX,
  required int inlandY,
  required String regionId,
  required MapTopology topology,
  required TileMapResult map,
  required int pathRoadLevel,
  SeaboardMissingCoastalPolicy missingCoastalPolicy =
      SeaboardMissingCoastalPolicy.skip,
  SeaboardExistingPortPolicy existingPortPolicy =
      SeaboardExistingPortPolicy.skip,
  SeaboardPathMissingPolicy pathMissingPolicy = SeaboardPathMissingPolicy.skip,
  bool requireSeaBoundProvince = false,
  bool throwIfNoSeaZones = false,
}) {
  final localProvinceId = ProvinceId.localIdFrom(provinceId);

  if (requireSeaBoundProvince &&
      !isProvinceSeaBound(topology, localProvinceId)) {
    return worldState;
  }

  var tileState = worldState.tileState;
  var ports = Map<String, String>.from(worldState.portsByProvinceSeaboard);
  final provinceIds = provinceNodeIds(topology);
  final seaZoneIds = seaZonesAdjacentToProvince(
    topology,
    localProvinceId,
  ).toList()..sort();

  if (seaZoneIds.isEmpty && throwIfNoSeaZones) {
    throw SetupTopologyDataException(
      code: 'province_has_no_sea_zone',
      details: 'Province $provinceId has no sea zone in topology',
    );
  }

  for (final seaZoneId in seaZoneIds) {
    final portKeyProvSea = '$provinceId|$seaZoneId';
    if (existingPortPolicy == SeaboardExistingPortPolicy.skip &&
        ports.containsKey(portKeyProvSea)) {
      continue;
    }

    final inlandTouchesSea = tileAdjacentToSeaZone(
      inlandX,
      inlandY,
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

    final coastal = nearestSeaboardTileInProvinceForSeaZone(
      map: map,
      topology: topology,
      localProvinceId: localProvinceId,
      seaZoneId: seaZoneId,
      provinceIds: provinceIds,
      inlandX: inlandX,
      inlandY: inlandY,
    );
    if (coastal == null) {
      if (missingCoastalPolicy == SeaboardMissingCoastalPolicy.throwException) {
        throw SetupTopologyDataException(
          code: 'seaboard_port_tile_not_found',
          details:
              'No coastal tile in province $provinceId for sea zone $seaZoneId',
        );
      }
      continue;
    }

    final (bestX, bestY) = coastal;
    final portKey = CapitalTile.tileKey(regionId, provinceId, bestX, bestY);
    tileState = raiseRoadAtLeast(tileState, inlandTileKey, pathRoadLevel);
    tileState = raiseRoadAtLeast(tileState, portKey, 4);
    ports[portKeyProvSea] = portKey;

    final parents = bfsGridParents(
      startX: bestX,
      startY: bestY,
      width: map.width,
      height: map.height,
      passable: (x, y) => map.cell(x, y) == localProvinceId,
    );
    final reconstructed = reconstructGridPath(
      parents: parents,
      toX: inlandX,
      toY: inlandY,
    );
    final pathTiles =
        reconstructed ??
        (pathMissingPolicy == SeaboardPathMissingPolicy.useStartOnly
            ? [(bestX, bestY)]
            : null);
    if (pathTiles == null) continue;
    for (final p in pathTiles) {
      final key = CapitalTile.tileKey(regionId, provinceId, p.$1, p.$2);
      if (key == portKey) continue;
      tileState = raiseRoadAtLeast(tileState, key, pathRoadLevel);
    }
  }

  return worldState.copyWith(
    tileState: tileState,
    portsByProvinceSeaboard: ports,
  );
}
