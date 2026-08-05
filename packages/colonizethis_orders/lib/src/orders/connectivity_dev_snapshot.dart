import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import 'owned_tile_graph.dart';

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
  final ownedLandTiles = ownedLandTileKeysForPlayer(
    game: game,
    playerId: playerId,
  );
  final portInfo = portToProvinceSeaZone(game.worldState);
  final tileState = game.worldState.tileState;

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
  }
  for (final tileKey in ownedLandTiles) {
    if (tileState.roadLevel(tileKey) > 0) continue;
    if (!isTileAdjacentToRoadNetwork(
      tileKey: tileKey,
      worldState: game.worldState,
      portTileToProvinceSeaZone: portInfo,
      tileMapByRegion: tileMapByRegion,
      landProvinceIds: landProvinceIds,
    )) {
      continue;
    }
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
      : extensionDistancesOverOwnedLand(
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

bool _isDevTargetTile(Game game, String tileKey) {
  final resourceId = game.worldState.resourceByTileKey[tileKey];
  final level = game.worldState.tileState.improvementLevel(tileKey);
  return (resourceId != null && resourceId.isNotEmpty) || level >= 1;
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
