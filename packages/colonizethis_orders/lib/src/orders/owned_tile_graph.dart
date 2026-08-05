import 'dart:collection';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import 'order_suggestion_pass_context.dart';

/// Owned-land tile graph primitives shared by connectivity dev snapshot and
/// development-panel road-first paths (Refs #4258 Slice C).
///
/// Neighbor expansion uses stable sorted tile-key ordering for deterministic
/// BFS tie-breaking.

/// All owned land tile keys for [playerId], including purchased tiles.
Set<String> ownedLandTileKeysForPlayer({
  required Game game,
  required String playerId,
}) {
  final ownedProvinceIds =
      ownedProvinceIdsForPlayer(game.worldState, playerId);
  final purchasedTiles = game.worldState.purchasedTilesByTileKey.keys.toSet();
  return _ownedLandTileKeys(
    game: game,
    ownedProvinceIds: ownedProvinceIds,
    purchasedTiles: purchasedTiles,
  );
}

Set<String> _ownedLandTileKeys({
  required Game game,
  required Set<String> ownedProvinceIds,
  required Set<String> purchasedTiles,
}) {
  final out = <String>{};
  final tileKeysByRegion = game.worldState.tileKeysByRegionAndProvince;
  for (final regionEntry in tileKeysByRegion.entries) {
    final regionId = regionEntry.key;
    for (final provinceEntry in regionEntry.value.entries) {
      final provinceKey = provinceEntry.key;
      final fullProvinceId = ProvinceId.isPrefixed(provinceKey)
          ? provinceKey
          : ProvinceId.full(regionId, provinceKey);
      if (!ownedProvinceIds.contains(fullProvinceId)) continue;
      out.addAll(provinceEntry.value);
    }
  }
  out.addAll(purchasedTiles);
  return out;
}

/// Cardinal land-neighbor tile keys for [tileKey] in stable sorted order.
List<String> cardinalLandNeighborTileKeys({
  required String tileKey,
  required Map<String, TileMapResult> tileMapByRegion,
  required Set<String> landProvinceIds,
}) {
  final coords = parseTileKeyCoordinates(tileKey);
  if (coords == null) return const [];

  final map = tileMapByRegion[coords.regionId];
  if (map == null) return const [];

  final neighbors = <String>[];
  final w = map.width;
  final h = map.height;
  for (final d in kGridNeighborsCardinal4) {
    final nx = coords.x + d.$1;
    final ny = coords.y + d.$2;
    if (nx < 0 || nx >= w || ny < 0 || ny >= h) continue;
    final cellId = map.cell(nx, ny);
    final fullProvinceId = landProvinceIds.contains(cellId)
        ? ProvinceId.full(coords.regionId, cellId)
        : (landProvinceIds.contains(ProvinceId.full(coords.regionId, cellId))
              ? ProvinceId.full(coords.regionId, cellId)
              : null);
    if (fullProvinceId == null) continue;
    neighbors.add(
      CapitalTile.tileKey(coords.regionId, fullProvinceId, nx, ny),
    );
  }
  neighbors.sort();
  return neighbors;
}

/// Shortest owned-tile path from [startTileKey] to any [connectedTileKeys] tile.
///
/// Returns `null` when no path exists on owned land tiles.
List<String>? shortestOwnedTilePathToConnectedNetwork({
  required Game game,
  required String playerId,
  required String startTileKey,
  required Set<String> connectedTileKeys,
  required Map<String, TileMapResult> tileMapByRegion,
  required MapTopology topology,
}) {
  if (connectedTileKeys.contains(startTileKey)) {
    return [startTileKey];
  }

  final landProvinceIds = provinceNodeIds(topology);
  final ownedLandTiles = ownedLandTileKeysForPlayer(game: game, playerId: playerId);
  final parent = <String, String?>{startTileKey: null};
  final queue = Queue<String>()..add(startTileKey);

  while (queue.isNotEmpty) {
    final current = queue.removeFirst();
    if (connectedTileKeys.contains(current)) {
      final path = <String>[];
      var walk = current;
      while (true) {
        path.insert(0, walk);
        final previous = parent[walk];
        if (previous == null) break;
        walk = previous;
      }
      return path;
    }

    for (final neighbor in cardinalLandNeighborTileKeys(
      tileKey: current,
      tileMapByRegion: tileMapByRegion,
      landProvinceIds: landProvinceIds,
    )) {
      if (!ownedLandTiles.contains(neighbor)) continue;
      if (parent.containsKey(neighbor)) continue;
      parent[neighbor] = current;
      queue.add(neighbor);
    }
  }
  return null;
}

/// Minimum owned-land steps from each reachable tile to the nearest tile in
/// [startTargets]; absent when unreachable over [ownedLandTiles].
Map<String, int> extensionDistancesOverOwnedLand({
  required Set<String> startTargets,
  required Set<String> ownedLandTiles,
  required Map<String, TileMapResult> tileMapByRegion,
  required Set<String> landProvinceIds,
}) {
  final distances = <String, int>{};
  final queue = Queue<String>();
  for (final tk in startTargets) {
    distances[tk] = 0;
    queue.add(tk);
  }
  while (queue.isNotEmpty) {
    final current = queue.removeFirst();
    final currentDist = distances[current]!;
    for (final neighbor in cardinalLandNeighborTileKeys(
      tileKey: current,
      tileMapByRegion: tileMapByRegion,
      landProvinceIds: landProvinceIds,
    )) {
      if (!ownedLandTiles.contains(neighbor)) continue;
      if (distances.containsKey(neighbor)) continue;
      distances[neighbor] = currentDist + 1;
      queue.add(neighbor);
    }
  }
  return distances;
}

/// True when [tileKey] is 4-adjacent to any tile in [connected].
bool isTileAdjacentToConnectedSet(
  String tileKey,
  Set<String> connected, {
  required Map<String, TileMapResult> tileMapByRegion,
  required Set<String> landProvinceIds,
}) {
  for (final neighbor in cardinalLandNeighborTileKeys(
    tileKey: tileKey,
    tileMapByRegion: tileMapByRegion,
    landProvinceIds: landProvinceIds,
  )) {
    if (connected.contains(neighbor)) return true;
  }
  return false;
}
