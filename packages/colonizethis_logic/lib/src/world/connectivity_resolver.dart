import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:logger/logger.dart';

import 'province_lookup.dart';
import 'topology_helpers.dart';
import '../diplomacy/diplomacy_relation_lookup.dart';

final Logger _log = Logger();

/// Result of connectivity resolution: connected tile set and per-tile path transport cap.
/// SPEC/game/capital-and-connectivity, extraction-and-improvements: effective yield is
/// capped by min transport level along path to town then to capital; [pathTransportCap]
/// is that cap (max over paths of min road level on path).
class ConnectivityResult {
  const ConnectivityResult({
    required this.connected,
    this.pathTransportCap = const {},
  });

  final Set<String> connected;
  final Map<String, int> pathTransportCap;
}

/// Resolves which tiles are connected to each player's capital. SPEC/game/capital-and-connectivity.
///
/// Connectivity: from capital, BFS over land; edges are same-province adjacency;
/// we expand only from capital or tiles with road/port. Overseas: ports connected
/// by shared sea zone; from those ports, BFS within province by road/adjacency.
/// Also computes [ConnectivityResult.pathTransportCap]: for each connected tile,
/// the maximum over paths from capital of (min road/port level on that path).

/// Blockade state: per player, the set of port province ids (full prefixed) that are blockaded.
///
/// A province is blockaded for its owner when an **enemy fleet at war** with that owner is on
/// Blockade mission targeting it. **Diplomatic state:** only blockaders that are at war with the
/// province owner count; blockading a faction you are at peace with has no effect. **Same-region**
/// and **cross-region** blockades are both valid: the fleet's [Fleet.regionId] is where the fleet
/// is; [targetProvinceId] may be in any region (oldWorld, newWorld, etc.). SPEC/game/capital-and-connectivity.md § Blockade.
Map<String, Set<String>> computeBlockadedPortProvincesByPlayer(Game game) {
  final result = <String, Set<String>>{};
  for (final player in game.players) {
    result[player.id] = {};
  }
  final fleets = game.worldState.fleets;
  for (final fleet in fleets) {
    if (fleet.mission != FleetMission.blockade) continue;
    final targetProvinceId = fleet.targetProvinceId;
    if (targetProvinceId == null || targetProvinceId.isEmpty) continue;
    if (!ProvinceId.isPrefixed(targetProvinceId)) continue;
    final province = tryGetProvince(game.worldState, targetProvinceId);
    final ownerId = province?.ownerId;
    if (ownerId == null) continue;
    final blockaderId = fleet.ownerId;
    // Only factions at war with the province owner can blockade it.
    if (!factionsAtWar(game, blockaderId, ownerId)) continue;
    result[ownerId] ??= {};
    result[ownerId]!.add(targetProvinceId);
  }
  return result;
}

/// Returns per player id [ConnectivityResult] (connected set + path transport cap).
/// Players without capital or with no tile map get an empty result.
/// When [blockadedPortProvincesByPlayerId] is null, it is computed from [game] (fleets on Blockade mission, at war). SPEC/game/capital-and-connectivity.md § Blockade.
Map<String, ConnectivityResult> resolveConnectivity({
  required Game game,
  required Map<String, TileMapResult> tileMapByRegion,
  required MapTopology topology,
  Map<String, Set<String>>? blockadedPortProvincesByPlayerId,
}) {
  _log.d('logic: connectivity resolve start players=${game.players.length} regions=${tileMapByRegion.keys.join(",")}');
  final provinceIdsByType = provinceNodeIds(topology);
  final blockadedByPlayer =
      blockadedPortProvincesByPlayerId ?? computeBlockadedPortProvincesByPlayer(game);
  final result = <String, ConnectivityResult>{};

  for (final player in game.players) {
    final capital = player.capitalTile;
    if (capital == null || player.capitalProvinceId == null) {
      _log.d('logic: connectivity resolve player=${player.id} skipped (no capital)');
      result[player.id] = ConnectivityResult(connected: {});
      continue;
    }

    final cr = _connectedTilesForPlayer(
      game: game,
      playerId: player.id,
      capital: capital,
      tileMapByRegion: tileMapByRegion,
      topology: topology,
      provinceIdsByType: provinceIdsByType,
      blockadedPortProvinces: blockadedByPlayer[player.id] ?? const {},
    );
    result[player.id] = cr;
  }

  final summary = result.entries
      .map((e) => '${e.key}:${e.value.connected.length}')
      .join(' ');
  _log.d('logic: connectivity resolve end $summary');
  return result;
}

Set<String> _provinceIdsFromTopology(MapTopology topology) {
  return topology.nodes
      .where((n) => n.type == TopologyNodeType.province)
      .map((n) => n.id)
      .toSet();
}

bool _topologyUsesPrefixedIds(MapTopology topology) {
  return topology.nodes.any((n) => n.id.contains('|'));
}

/// Sea zones reachable from [startSeaZoneIds] by following S–S edges in [topology]. SPEC/game/map-topology, capital-and-connectivity § Sea paths.
Set<String> _seaZonesReachableBySeaPath(
  MapTopology topology,
  Set<String> startSeaZoneIds,
) {
  final seaZoneIds = topology.nodes
      .where((n) => n.type == TopologyNodeType.seaZone)
      .map((n) => n.id)
      .toSet();
  final neighbours = <String, Set<String>>{};
  for (final e in topology.edges) {
    final a = e.id1;
    final b = e.id2;
    if (seaZoneIds.contains(a) && seaZoneIds.contains(b)) {
      neighbours.putIfAbsent(a, () => {}).add(b);
      neighbours.putIfAbsent(b, () => {}).add(a);
    }
  }
  final reachable = Set<String>.from(startSeaZoneIds);
  final queue = List<String>.from(startSeaZoneIds);
  while (queue.isNotEmpty) {
    final z = queue.removeAt(0);
    for (final n in neighbours[z] ?? {}) {
      if (reachable.contains(n)) continue;
      reachable.add(n);
      queue.add(n);
    }
  }
  return reachable;
}

/// Sea zone ids adjacent to province [localProvinceId] in topology (P–S edges).
Set<String> _seaZonesAdjacentToProvince(MapTopology topology, String localProvinceId) {
  final seaZoneIds = topology.nodes
      .where((n) => n.type == TopologyNodeType.seaZone)
      .map((n) => n.id)
      .toSet();
  final out = <String>{};
  for (final edge in topology.edges) {
    if (edge.id1 != localProvinceId && edge.id2 != localProvinceId) continue;
    final other = edge.id1 == localProvinceId ? edge.id2 : edge.id1;
    if (seaZoneIds.contains(other)) out.add(other);
  }
  return out;
}

/// True if the capital tile is adjacent to sea (seaboard). SPEC/game/capital-and-connectivity § Port connection to capital.
bool _isCapitalTileOnSeaboard(
  CapitalTile capital,
  Map<String, TileMapResult> tileMapByRegion,
  Set<String> provinceIdsByType,
) {
  final map = tileMapByRegion[capital.regionId];
  if (map == null) return false;
  final w = map.width;
  final h = map.height;
  for (final d in [(0, -1), (1, 0), (0, 1), (-1, 0)]) {
    final nx = capital.x + d.$1;
    final ny = capital.y + d.$2;
    if (nx < 0 || nx >= w || ny < 0 || ny >= h) return true;
    final cellId = map.cell(nx, ny);
    if (!provinceIdsByType.contains(cellId)) return true;
  }
  return false;
}

Set<String> _ownedProvinceIdsForPlayer(Game game, String playerId) {
  final owned = <String>{};
  for (final p in game.worldState.oldWorld.provinces) {
    if (p.ownerId == playerId) owned.add(p.id);
  }
  for (final p in game.worldState.newWorld.provinces) {
    if (p.ownerId == playerId) owned.add(p.id);
  }
  return owned;
}

/// Port tile key -> (fullProvinceId, seaZoneId). Built from portsByProvinceSeaboard.
/// Key format: fullProvinceId|seaZoneId (e.g. oldWorld|p1|sea1) or legacy provinceId|seaZoneId (2 parts).
Map<String, (String, String)> _portToProvinceSeaZone(WorldState worldState) {
  final out = <String, (String, String)>{};
  for (final e in worldState.portsByProvinceSeaboard.entries) {
    final key = e.key;
    final tileKey = e.value;
    final parts = key.split('|');
    if (parts.length >= 3) {
      out[tileKey] = ('${parts[0]}|${parts[1]}', parts[2]);
    } else if (parts.length >= 2) {
      out[tileKey] = (parts[0], parts[1]);
    }
  }
  return out;
}

int _transportLevelAtTile(WorldState worldState, String tileKey) {
  final portInfo = _portToProvinceSeaZone(worldState);
  if (portInfo.containsKey(tileKey)) return 4;
  final r = worldState.tileState.roadLevel(tileKey);
  return r > 0 ? r : 0;
}

ConnectivityResult _connectedTilesForPlayer({
  required Game game,
  required String playerId,
  required CapitalTile capital,
  required Map<String, TileMapResult> tileMapByRegion,
  required MapTopology topology,
  required Set<String> provinceIdsByType,
  Set<String> blockadedPortProvinces = const {},
}) {
  final worldState = game.worldState;
  final tileState = worldState.tileState;
  final owned = _ownedProvinceIdsForPlayer(game, playerId);
  if (!owned.contains(capital.provinceId)) {
    return const ConnectivityResult(connected: {});
  }

  final capitalRegionId = capital.regionId;
  final mapOpt = tileMapByRegion[capitalRegionId];
  if (mapOpt == null) return const ConnectivityResult(connected: {});

  final capitalKey = capital.toTileKey();
  final portInfo = _portToProvinceSeaZone(worldState);
  final connected = <String>{capitalKey};
  final pathCap = <String, int>{};
  pathCap[capitalKey] = _transportLevelAtTile(worldState, capitalKey);
  final queue = <String>[capitalKey];

  while (queue.isNotEmpty) {
    final key = queue.removeAt(0);
    final parts = key.split('|');
    if (parts.length != 4) continue;
    final regionId = parts[0];
    final localProvinceId = parts[1];
    final fullProvinceId = '$regionId|$localProvinceId';
    final x = int.tryParse(parts[2]) ?? -1;
    final y = int.tryParse(parts[3]) ?? -1;
    if (x < 0 || y < 0) continue;

    if (!owned.contains(fullProvinceId)) continue;

    final map = tileMapByRegion[regionId];
    if (map == null) continue;

    final hasRoadOrPort = (tileState.roadLevel(key) > 0) || portInfo.containsKey(key);
    final canExpand = (key == capitalKey) || hasRoadOrPort;

    if (!canExpand) continue;

    final bottleneckU = pathCap[key] ?? 0;
    for (final n in _adjacentTileKeys(regionId, localProvinceId, x, y, map, provinceIdsByType)) {
      final transportN = _transportLevelAtTile(worldState, n);
      final candidate = bottleneckU < transportN ? bottleneckU : transportN;
      final existing = pathCap[n] ?? -1;
      if (candidate > existing) {
        pathCap[n] = candidate;
        if (!connected.contains(n)) {
          connected.add(n);
          queue.add(n);
        } else {
          queue.add(n);
        }
      } else if (!connected.contains(n)) {
        connected.add(n);
        pathCap[n] = candidate;
        queue.add(n);
      }
    }
  }

  // Port connection rule: (1) capital on seaboard → ports reachable via sea-path (BFS S–S); (2) else only ports reachable by road/rail from capital. SPEC/game/capital-and-connectivity § Port connection to capital, Sea paths.
  final capitalRegionPortKeys = <String>{};
  for (final k in connected) {
    final info = portInfo[k];
    if (info == null) continue;
    final parts = k.split('|');
    if (parts.isEmpty) continue;
    if (parts[0] == capitalRegionId) capitalRegionPortKeys.add(k);
  }

  final seaConnectedPortKeys = <String>{};
  final capitalProvinceBlockaded = blockadedPortProvinces.contains(capital.provinceId);
  final capitalOnSeaboard = _isCapitalTileOnSeaboard(
    capital,
    tileMapByRegion,
    provinceIdsByType,
  );
  if (capitalOnSeaboard && !capitalProvinceBlockaded) {
    final prefixedTopology = _topologyUsesPrefixedIds(topology);
    final provinceIdForLookup = prefixedTopology
        ? capital.provinceId
        : ProvinceId.localIdFrom(capital.provinceId);
    final capitalSeaZones = _seaZonesAdjacentToProvince(topology, provinceIdForLookup);
    final seaReachable = _seaZonesReachableBySeaPath(topology, capitalSeaZones);
    for (final e in worldState.portsByProvinceSeaboard.entries) {
      final provSea = e.key;
      final tileKey = e.value;
      final parts = provSea.split('|');
      final seaZoneId = parts.length >= 3 ? parts[2] : (parts.length >= 2 ? parts[1] : null);
      final fullProvinceId = parts.length >= 3 ? '${parts[0]}|${parts[1]}' : (parts.length >= 2 ? parts[0] : null);
      if (seaZoneId == null || fullProvinceId == null) continue;
      if (blockadedPortProvinces.contains(fullProvinceId)) continue;
      final seaZoneIdForReachable = prefixedTopology && parts.length >= 3
          ? '${parts[0]}|$seaZoneId'
          : seaZoneId;
      if (!seaReachable.contains(seaZoneIdForReachable)) continue;
      if (!owned.contains(fullProvinceId)) continue;
      seaConnectedPortKeys.add(tileKey);
    }
  } else if (!capitalOnSeaboard) {
    for (final portKey in capitalRegionPortKeys) {
      final parts = portKey.split('|');
      if (parts.length >= 2) {
        final fullProvinceId = parts.length >= 3 ? '${parts[0]}|${parts[1]}' : parts[0];
        if (!blockadedPortProvinces.contains(fullProvinceId)) {
          seaConnectedPortKeys.add(portKey);
        }
      } else {
        seaConnectedPortKeys.add(portKey);
      }
    }
  }
  // When capital province is blockaded, seaConnectedPortKeys stays empty (no sea connectivity). SPEC § Blockade.

  for (final portKey in seaConnectedPortKeys) {
    if (connected.contains(portKey)) continue;
    final parts = portKey.split('|');
    if (parts.length != 4) continue;
    final regionId = parts[0];
    final fullProvinceId = '$regionId|${parts[1]}';
    if (!owned.contains(fullProvinceId)) continue;
    final map = tileMapByRegion[regionId];
    if (map == null) continue;
    final x = int.tryParse(parts[2]) ?? -1;
    final y = int.tryParse(parts[3]) ?? -1;
    if (x < 0 || y < 0) continue;

    connected.add(portKey);
    pathCap[portKey] = 4;
    queue.add(portKey);
  }

  while (queue.isNotEmpty) {
    final key = queue.removeAt(0);
    final parts = key.split('|');
    if (parts.length != 4) continue;
    final regionId = parts[0];
    final provinceId = parts[1];
    final x = int.tryParse(parts[2]) ?? -1;
    final y = int.tryParse(parts[3]) ?? -1;
    if (x < 0 || y < 0) continue;

    final hasRoadOrPort = (tileState.roadLevel(key) > 0) || portInfo.containsKey(key);
    final canExpand = hasRoadOrPort;

    if (!canExpand) continue;

    final map = tileMapByRegion[regionId];
    if (map == null) continue;

    final bottleneckU = pathCap[key] ?? 0;
    for (final n in _adjacentTileKeys(regionId, provinceId, x, y, map, provinceIdsByType)) {
      final transportN = _transportLevelAtTile(worldState, n);
      final candidate = bottleneckU < transportN ? bottleneckU : transportN;
      final existing = pathCap[n] ?? -1;
      if (candidate > existing) {
        pathCap[n] = candidate;
        if (!connected.contains(n)) {
          connected.add(n);
          queue.add(n);
        } else {
          queue.add(n);
        }
      } else if (!connected.contains(n)) {
        connected.add(n);
        pathCap[n] = candidate;
        queue.add(n);
      }
    }
  }

  // SPEC § Blockade: no tiles in a blockaded port province contribute; remove any tile in such a province (except capital province: its tiles remain when it is blockaded, only sea connectivity is severed).
  if (blockadedPortProvinces.isNotEmpty) {
    for (final key in connected.toList()) {
      final parts = key.split('|');
      if (parts.length >= 2) {
        final fullProvinceId =
            parts.length >= 3 ? '${parts[0]}|${parts[1]}' : parts[0];
        if (blockadedPortProvinces.contains(fullProvinceId) &&
            fullProvinceId != capital.provinceId) {
          connected.remove(key);
          pathCap.remove(key);
        }
      }
    }
  }

  return ConnectivityResult(connected: connected, pathTransportCap: pathCap);
}

/// Adjacent tile keys (4-neighbour). Includes tiles in same or neighbouring provinces (any land cell). Tile key uses neighbour's province id.
List<String> _adjacentTileKeys(
  String regionId,
  String provinceId,
  int x,
  int y,
  TileMapResult map,
  Set<String> provinceIdsByType,
) {
  final out = <String>[];
  final w = map.width;
  final h = map.height;
  for (final d in [
    (0, -1),
    (1, 0),
    (0, 1),
    (-1, 0),
  ]) {
    final nx = x + d.$1;
    final ny = y + d.$2;
    if (nx < 0 || nx >= w || ny < 0 || ny >= h) continue;
    final cellId = map.cell(nx, ny);
    if (!provinceIdsByType.contains(cellId)) continue;
    final fullProvinceId = '$regionId|$cellId';
    out.add(CapitalTile.tileKey(regionId, fullProvinceId, nx, ny));
  }
  return out;
}
