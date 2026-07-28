import 'dart:collection';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

/// Plan-time connectivity snapshot for development-target candidate ordering
/// and Full-AI civilian-work scoring (Refs #4176).
///
/// Built once per `suggestWorkOrders` pass when [tileMapByRegion] is supplied.
/// Pure over `(game, playerId, topology, tileMapByRegion)`.
class ConnectivityDevSnapshot {
  const ConnectivityDevSnapshot({
    required this.connected,
    required this.pathTransportCap,
    required this.extensionDistanceByTile,
    required this.seaZonesReachableFromCapital,
    required this.provincesWithUnconnectedDevTargets,
    required this.hasUnconnectedDevTargets,
    required this.frontierExtensionTiles,
    required this.bottleneckRailTiles,
    required this.adjacentToConnectedTiles,
  });

  /// Capital-connected tile set from [resolveConnectivity] (includes Town rule).
  final Set<String> connected;

  /// Per-tile path transport cap along connectivity paths from the capital.
  final Map<String, int> pathTransportCap;

  /// Minimum owned-land steps from each tile to the nearest unconnected
  /// resource/improved dev target; absent when unreachable over owned land.
  final Map<String, int> extensionDistanceByTile;

  /// Sea zones reachable from the player's capital by sea path.
  final Set<String> seaZonesReachableFromCapital;

  /// Full prefixed province ids holding at least one unconnected dev target.
  final Set<String> provincesWithUnconnectedDevTargets;

  /// When false, connectivity reordering is a no-op (baseline lex order).
  final bool hasUnconnectedDevTargets;

  /// Owned land tiles 4-adjacent to [connected] but not in [connected].
  final Set<String> frontierExtensionTiles;

  /// Connected road tiles whose path cap bottlenecks served improvements.
  final Set<String> bottleneckRailTiles;

  /// Unconnected tiles 4-adjacent to [connected] (improvement tier-1).
  final Set<String> adjacentToConnectedTiles;
}

/// Returns null when [tileMapByRegion] is null (connectivity ordering skipped).
ConnectivityDevSnapshot? buildConnectivityDevSnapshot({
  required Game game,
  required String playerId,
  required MapTopology topology,
  required Map<String, TileMapResult>? tileMapByRegion,
}) {
  if (tileMapByRegion == null || tileMapByRegion.isEmpty) return null;
  final player = game.playerById(playerId);
  final capital = player?.capitalTile;
  if (player == null || capital == null) return null;

  final connectivity = resolveConnectivity(
    game: game,
    tileMapByRegion: tileMapByRegion,
    topology: topology,
  );
  final result = connectivity[playerId];
  if (result == null) {
    return const ConnectivityDevSnapshot(
      connected: {},
      pathTransportCap: {},
      extensionDistanceByTile: {},
      seaZonesReachableFromCapital: {},
      provincesWithUnconnectedDevTargets: {},
      hasUnconnectedDevTargets: false,
      frontierExtensionTiles: {},
      bottleneckRailTiles: {},
      adjacentToConnectedTiles: {},
    );
  }

  final connected = result.connected;
  final pathTransportCap = result.pathTransportCap;
  final landProvinceIds = provinceNodeIds(topology);
  final ownedProvinceIds = _ownedProvinceIdsForPlayer(game, playerId);
  final purchasedTiles = game.worldState.purchasedTilesByTileKey.keys.toSet();
  final ownedLandTiles = _ownedLandTileKeys(
    game: game,
    ownedProvinceIds: ownedProvinceIds,
    purchasedTiles: purchasedTiles,
  );

  final frontierExtensionTiles = <String>{};
  final adjacentToConnectedTiles = <String>{};
  for (final tileKey in ownedLandTiles) {
    if (connected.contains(tileKey)) continue;
    if (!isTileAdjacentToConnectedSet(
      tileKey,
      connected,
      tileMapByRegion: tileMapByRegion,
      landProvinceIds: landProvinceIds,
    )) {
      continue;
    }
    adjacentToConnectedTiles.add(tileKey);
    frontierExtensionTiles.add(tileKey);
  }

  final bottleneckRailTiles = _bottleneckRailTiles(
    game: game,
    connected: connected,
    pathTransportCap: pathTransportCap,
  );

  final unconnectedTargets = <String>{};
  final provincesWithUnconnected = <String>{};
  for (final tileKey in ownedLandTiles) {
    if (!_isDevTargetTile(game, tileKey)) continue;
    if (connected.contains(tileKey)) continue;
    unconnectedTargets.add(tileKey);
    final provinceId = Unit.provinceIdFromTileKey(tileKey);
    if (provinceId != null) provincesWithUnconnected.add(provinceId);
  }

  final extensionDistanceByTile = unconnectedTargets.isEmpty
      ? const <String, int>{}
      : _extensionDistancesOverOwnedLand(
          startTargets: unconnectedTargets,
          ownedLandTiles: ownedLandTiles,
          tileMapByRegion: tileMapByRegion,
          landProvinceIds: landProvinceIds,
        );

  final seaReachable = _seaZonesReachableFromCapital(
    topology: topology,
    capital: capital,
  );

  return ConnectivityDevSnapshot(
    connected: connected,
    pathTransportCap: pathTransportCap,
    extensionDistanceByTile: extensionDistanceByTile,
    seaZonesReachableFromCapital: seaReachable,
    provincesWithUnconnectedDevTargets: provincesWithUnconnected,
    hasUnconnectedDevTargets: unconnectedTargets.isNotEmpty,
    frontierExtensionTiles: frontierExtensionTiles,
    bottleneckRailTiles: bottleneckRailTiles,
    adjacentToConnectedTiles: adjacentToConnectedTiles,
  );
}

Set<String> _ownedProvinceIdsForPlayer(Game game, String playerId) {
  final out = <String>{};
  for (final province in game.worldState.oldWorld.provinces) {
    if (province.ownerId == playerId) out.add(province.id);
  }
  for (final province in game.worldState.newWorld.provinces) {
    if (province.ownerId == playerId) out.add(province.id);
  }
  return out;
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
      final localProvinceId = provinceEntry.key;
      final fullProvinceId = ProvinceId.full(regionId, localProvinceId);
      if (!ownedProvinceIds.contains(fullProvinceId)) continue;
      out.addAll(provinceEntry.value);
    }
  }
  out.addAll(purchasedTiles);
  return out;
}

bool _isDevTargetTile(Game game, String tileKey) {
  final resourceId = game.worldState.resourceByTileKey[tileKey];
  final level = game.worldState.tileState.improvementLevel(tileKey);
  return (resourceId != null && resourceId.isNotEmpty) || level >= 1;
}

Map<String, int> _extensionDistancesOverOwnedLand({
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
    for (final neighbor in _cardinalNeighborTileKeys(
      current,
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

List<String> _cardinalNeighborTileKeys(
  String tileKey, {
  required Map<String, TileMapResult> tileMapByRegion,
  required Set<String> landProvinceIds,
}) {
  final coords = parseTileKeyCoordinates(tileKey);
  if (coords == null) return const [];
  if (coords.x < 0 || coords.y < 0) return const [];
  final map = tileMapByRegion[coords.regionId];
  if (map == null) return const [];
  final out = <String>[];
  final w = map.width;
  final h = map.height;
  for (final d in kGridNeighborsCardinal4) {
    final nx = coords.x + d.$1;
    final ny = coords.y + d.$2;
    if (nx < 0 || nx >= w || ny < 0 || ny >= h) continue;
    final cellId = map.cell(nx, ny);
    final fullProvinceId = '$coords.regionId|$cellId';
    if (!landProvinceIds.contains(cellId) &&
        !landProvinceIds.contains(fullProvinceId)) {
      continue;
    }
    out.add(CapitalTile.tileKey(coords.regionId, fullProvinceId, nx, ny));
  }
  return out;
}

Set<String> _seaZonesReachableFromCapital({
  required MapTopology topology,
  required CapitalTile capital,
}) {
  final prefixedTopology = topologyUsesPrefixedIds(topology);
  final provinceIdForLookup = prefixedTopology
      ? capital.provinceId
      : (ProvinceId.isPrefixed(capital.provinceId)
            ? ProvinceId.localIdFrom(capital.provinceId)
            : capital.provinceId);
  final capitalSeaZones = seaZoneIdsAdjacentToProvince(
    topology,
    provinceIdForLookup,
    regionId: ProvinceId.isPrefixed(capital.provinceId)
        ? ProvinceId.regionIdFrom(capital.provinceId)
        : null,
  );
  if (capitalSeaZones.isEmpty) return const {};
  return seaZonesReachableBySeaPath(topology, capitalSeaZones);
}

Set<String> _bottleneckRailTiles({
  required Game game,
  required Set<String> connected,
  required Map<String, int> pathTransportCap,
}) {
  final out = <String>{};
  final tileState = game.worldState.tileState;
  final resourceByTile = game.worldState.resourceByTileKey;
  for (final tileKey in connected) {
    final cap = pathTransportCap[tileKey] ?? 0;
    if (cap >= 4) continue;
    var servesBottleneck = false;
    for (final servedTile in connected) {
      final resourceId = resourceByTile[servedTile];
      if (resourceId == null || resourceId.isEmpty) continue;
      final level = tileState.improvementLevel(servedTile);
      if (level < 1) continue;
      final servedCap = pathTransportCap[servedTile] ?? 0;
      if (servedCap <= cap && level > cap) {
        servesBottleneck = true;
        break;
      }
    }
    if (servesBottleneck) out.add(tileKey);
  }
  return out;
}

/// True when [tileKey] is 4-adjacent to any tile in [connected].
bool isTileAdjacentToConnectedSet(
  String tileKey,
  Set<String> connected, {
  required Map<String, TileMapResult> tileMapByRegion,
  required Set<String> landProvinceIds,
}) {
  for (final neighbor in _cardinalNeighborTileKeys(
    tileKey,
    tileMapByRegion: tileMapByRegion,
    landProvinceIds: landProvinceIds,
  )) {
    if (connected.contains(neighbor)) return true;
  }
  return false;
}
