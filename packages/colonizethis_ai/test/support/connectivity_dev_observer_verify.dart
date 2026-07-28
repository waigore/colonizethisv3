/// Observer-game verification helpers for connectivity-aware civilian work
/// (Refs #4176 AC-F1, AC-F3).
library;

import 'dart:collection';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

/// Improved resource tiles controlled by [playerId] (owned province or purchase).
Iterable<String> improvedResourceTilesForPlayer(Game game, String playerId) sync* {
  final ws = game.worldState;
  final provinceOwnerById = <String, String?>{
    for (final p in ws.oldWorld.provinces) p.id: p.ownerId,
    for (final p in ws.newWorld.provinces) p.id: p.ownerId,
  };
  final seen = <String>{};
  for (final regionEntry in ws.tileKeysByRegionAndProvince.entries) {
    final regionId = regionEntry.key;
    for (final provinceEntry in regionEntry.value.entries) {
      final localProvinceId = provinceEntry.key;
      final fullProvinceId = ProvinceId.full(regionId, localProvinceId);
      final provinceOwner = provinceOwnerById[fullProvinceId];
      for (final tileKey in provinceEntry.value) {
        if (seen.contains(tileKey)) continue;
        if (!_playerControlsTile(
          tileKey: tileKey,
          playerId: playerId,
          provinceOwner: provinceOwner,
          purchasedBy: ws.purchasedTilesByTileKey[tileKey],
        )) {
          continue;
        }
        final resourceId = ws.resourceByTileKey[tileKey];
        final level = ws.tileState.improvementLevel(tileKey);
        if (resourceId != null &&
            resourceId.isNotEmpty &&
            level >= 1 &&
            seen.add(tileKey)) {
          yield tileKey;
        }
      }
    }
  }
}

bool _playerControlsTile({
  required String tileKey,
  required String playerId,
  required String? provinceOwner,
  required String? purchasedBy,
}) {
  if (purchasedBy == playerId) return true;
  if (provinceOwner == playerId && purchasedBy == null) return true;
  return false;
}

Set<String> _ownedLandTilesForPlayer(Game game, String playerId) {
  final ownedProvinceIds = <String>{};
  for (final province in game.worldState.oldWorld.provinces) {
    if (province.ownerId == playerId) ownedProvinceIds.add(province.id);
  }
  for (final province in game.worldState.newWorld.provinces) {
    if (province.ownerId == playerId) ownedProvinceIds.add(province.id);
  }
  final purchased =
      game.worldState.purchasedTilesByTileKey.keys.toSet();
  final out = <String>{};
  for (final regionEntry
      in game.worldState.tileKeysByRegionAndProvince.entries) {
    final regionId = regionEntry.key;
    for (final provinceEntry in regionEntry.value.entries) {
      final fullProvinceId =
          ProvinceId.full(regionId, provinceEntry.key);
      if (!ownedProvinceIds.contains(fullProvinceId)) continue;
      out.addAll(provinceEntry.value);
    }
  }
  out.addAll(purchased);
  return out;
}

Set<String> _reachableOverOwnedLandFromNetwork({
  required Set<String> connected,
  required Set<String> ownedLandTiles,
  required Map<String, TileMapResult> tileMapByRegion,
  required Set<String> landProvinceIds,
}) {
  final reached = Set<String>.from(connected);
  final queue = Queue<String>.from(connected);
  while (queue.isNotEmpty) {
    final current = queue.removeFirst();
    for (final neighbor in _cardinalNeighbors(
      current,
      tileMapByRegion: tileMapByRegion,
      landProvinceIds: landProvinceIds,
    )) {
      if (!ownedLandTiles.contains(neighbor)) continue;
      if (reached.add(neighbor)) queue.add(neighbor);
    }
  }
  return reached;
}

List<String> _cardinalNeighbors(
  String tileKey, {
  required Map<String, TileMapResult> tileMapByRegion,
  required Set<String> landProvinceIds,
}) {
  final coords = parseTileKeyCoordinates(tileKey);
  if (coords == null || coords.x < 0 || coords.y < 0) return const [];
  final map = tileMapByRegion[coords.regionId];
  if (map == null) return const [];
  final out = <String>[];
  for (final d in kGridNeighborsCardinal4) {
    final nx = coords.x + d.$1;
    final ny = coords.y + d.$2;
    if (nx < 0 || nx >= map.width || ny < 0 || ny >= map.height) continue;
    final cellId = map.cell(nx, ny);
    final fullProvinceId = '${coords.regionId}|$cellId';
    if (!landProvinceIds.contains(cellId) &&
        !landProvinceIds.contains(fullProvinceId)) {
      continue;
    }
    out.add(CapitalTile.tileKey(coords.regionId, fullProvinceId, nx, ny));
  }
  return out;
}

/// Improved resource tiles that are reachable over owned land from the
/// capital-connected network but not yet in [connected] (Refs #4176 AC-F1).
List<String> connectivityClosureViolations({
  required Game game,
  required String playerId,
  required MapTopology topology,
  required Map<String, TileMapResult> tileMapByRegion,
}) {
  final connectivity = resolveConnectivity(
    game: game,
    tileMapByRegion: tileMapByRegion,
    topology: topology,
  );
  final connected = connectivity[playerId]?.connected ?? const {};
  final ownedLand = _ownedLandTilesForPlayer(game, playerId);
  final landProvinceIds = provinceNodeIds(topology);
  final reachable = _reachableOverOwnedLandFromNetwork(
    connected: connected,
    ownedLandTiles: ownedLand,
    tileMapByRegion: tileMapByRegion,
    landProvinceIds: landProvinceIds,
  );
  final violations = <String>[];
  for (final tileKey in improvedResourceTilesForPlayer(game, playerId)) {
    if (connected.contains(tileKey)) continue;
    if (!reachable.contains(tileKey)) continue;
    violations.add(tileKey);
  }
  return violations;
}

/// Count of capital-connected tiles for [playerId] after extraction connectivity.
int connectedTileCountForPlayer({
  required Game game,
  required String playerId,
  required MapTopology topology,
  required Map<String, TileMapResult> tileMapByRegion,
}) {
  final connectivity = resolveConnectivity(
    game: game,
    tileMapByRegion: tileMapByRegion,
    topology: topology,
  );
  return connectivity[playerId]?.connected.length ?? 0;
}
