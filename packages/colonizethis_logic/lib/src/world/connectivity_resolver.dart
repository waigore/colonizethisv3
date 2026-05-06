import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/package_logger.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../utils/graph_traversal.dart';
import 'naval.dart';
import 'province_lookup.dart';
import 'tile_key_coordinates.dart';
import 'topology_helpers.dart';
import '../diplomacy/diplomacy_relation_lookup.dart';

final _log = packageLogger();

/// Result of connectivity resolution: connected tile set and per-tile path transport cap.
/// SPEC/game/capital-and-connectivity, extraction-and-improvements: effective yield is
/// capped by min transport level along path to town then to capital; [pathTransportCap]
/// is that cap (max over paths of min road level on path).
///
/// [connectedByRoadRule] is the tile set before § Town rule expansion (Road rule + sea
/// port wiring per resolver). Used for extraction town-development caps.
class ConnectivityResult {
  const ConnectivityResult({
    required this.connected,
    this.pathTransportCap = const {},
    this.connectedByRoadRule = const {},
  });

  final Set<String> connected;
  final Map<String, int> pathTransportCap;

  /// Tiles reachable under Road rule + overseas/port phases **before** 4-adjacent town closure.
  final Set<String> connectedByRoadRule;
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
/// A province is blockaded for its owner when an **enemy fleet at sea** (at war) is on Blockade
/// mission targeting it and the fleet's sea zone is **adjacent to that province's port**.
/// SPEC/game/capital-and-connectivity.md § Blockade.
Map<String, Set<String>> computeBlockadedPortProvincesByPlayer(
  Game game,
  MapTopology topology,
) {
  final result = <String, Set<String>>{};
  for (final player in game.players) {
    result[player.id] = {};
  }
  final fleets = game.worldState.fleets;
  for (final fleet in fleets) {
    if (fleet.mission != FleetMission.blockade) continue;
    if (!fleet.isAtSea || fleet.seaZoneId == null) continue;
    final targetProvinceId = fleet.targetProvinceId;
    if (targetProvinceId == null || targetProvinceId.isEmpty) continue;
    if (!ProvinceId.isPrefixed(targetProvinceId)) continue;
    final adjacentSeaZones = seaZoneIdsAdjacentToProvince(
      topology,
      targetProvinceId,
    );
    if (!adjacentSeaZones.contains(fleet.seaZoneId)) continue;
    final province = game.worldState.tryGetProvince(targetProvinceId);
    final ownerId = province?.ownerId;
    if (ownerId == null) continue;
    final blockaderId = fleet.ownerId;
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
  _log.d(
    'connectivity resolve start players=${game.players.length} regions=${tileMapByRegion.keys.join(",")}',
  );
  final provinceIdsByType = provinceNodeIds(topology);
  final blockadedByPlayer =
      blockadedPortProvincesByPlayerId ??
      computeBlockadedPortProvincesByPlayer(game, topology);
  final result = <String, ConnectivityResult>{};

  for (final player in game.players) {
    final capital = player.capitalTile;
    if (capital == null || player.capitalProvinceId == null) {
      _log.d('connectivity resolve player=${player.id} skipped (no capital)');
      result[player.id] = const ConnectivityResult(connected: {});
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
  _log.d('connectivity resolve end $summary');
  return result;
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
  return breadthFirstReachableInSubgraph(
    startSeaZoneIds,
    neighbours,
    seaZoneIds,
  );
}

/// Sea zone ids adjacent to province [localProvinceId] in topology (P–S edges).
Set<String> _seaZonesAdjacentToProvince(
  MapTopology topology,
  String localProvinceId,
) {
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
    if (!_isLandProvinceGridCell(cellId, capital.regionId, provinceIdsByType)) {
      return true;
    }
  }
  return false;
}

Set<String> _ownedProvinceIdsForPlayer(Game game, String playerId) {
  final owned = <String>{};
  for (final p in allProvinces(game.worldState)) {
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

void _tryEnqueueSeaConnectedPortExpansion({
  required String portKey,
  required Set<String> connected,
  required Set<String> owned,
  required Map<String, TileMapResult> tileMapByRegion,
  required Map<String, int> pathCap,
  required List<String> expansionSeedQueue,
}) {
  if (connected.contains(portKey)) return;
  final coords = parseTileKeyCoordinates(portKey);
  if (coords == null) return;
  final fullProvinceId = '${coords.regionId}|${coords.provinceLocalId}';
  if (!owned.contains(fullProvinceId)) return;
  if (tileMapByRegion[coords.regionId] == null) return;
  if (coords.x < 0 || coords.y < 0) return;

  connected.add(portKey);
  pathCap[portKey] = 4;
  expansionSeedQueue.add(portKey);
}

void _removeBlockadedPortTilesExceptCapital({
  required Set<String> connected,
  required Map<String, int> pathCap,
  required Set<String> blockadedPortProvinces,
  required String capitalProvinceId,
}) {
  for (final key in connected.toList()) {
    final parts = key.split('|');
    if (parts.length < 2) continue;
    final fullProvinceId = parts.length >= 3
        ? '${parts[0]}|${parts[1]}'
        : parts[0];
    if (!blockadedPortProvinces.contains(fullProvinceId)) continue;
    if (fullProvinceId == capitalProvinceId) continue;
    connected.remove(key);
    pathCap.remove(key);
  }
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
  _runConnectivityPropagation(
    queue: <String>[capitalKey],
    connected: connected,
    pathCap: pathCap,
    worldState: worldState,
    tileMapByRegion: tileMapByRegion,
    provinceIdsByType: provinceIdsByType,
    ownedProvinceIds: owned,
    canExpandFrom: (tileKey) =>
        (tileKey == capitalKey) ||
        (tileState.roadLevel(tileKey) > 0) ||
        portInfo.containsKey(tileKey),
  );

  // Port connection rule: (1) capital on seaboard → ports reachable via sea-path (BFS S–S); (2) else only ports reachable by road/rail from capital. SPEC/game/capital-and-connectivity § Port connection to capital, Sea paths.
  final capitalRegionPortKeys = <String>{};
  for (final k in connected) {
    final info = portInfo[k];
    if (info == null) continue;
    final parts = k.split('|');
    if (parts.isEmpty) continue;
    if (parts[0] == capitalRegionId) capitalRegionPortKeys.add(k);
  }

  final seaConnectedPortKeys = _seaConnectedPortKeysForCapital(
    capital: capital,
    worldState: worldState,
    topology: topology,
    tileMapByRegion: tileMapByRegion,
    provinceIdsByType: provinceIdsByType,
    ownedProvinceIds: owned,
    blockadedPortProvinces: blockadedPortProvinces,
    capitalRegionPortKeys: capitalRegionPortKeys,
  );
  // When capital province is blockaded, seaConnectedPortKeys stays empty (no sea connectivity). SPEC § Blockade.

  final expansionSeedQueue = <String>[];
  for (final portKey in seaConnectedPortKeys) {
    _tryEnqueueSeaConnectedPortExpansion(
      portKey: portKey,
      connected: connected,
      owned: owned,
      tileMapByRegion: tileMapByRegion,
      pathCap: pathCap,
      expansionSeedQueue: expansionSeedQueue,
    );
  }

  _runConnectivityPropagation(
    queue: expansionSeedQueue,
    connected: connected,
    pathCap: pathCap,
    worldState: worldState,
    tileMapByRegion: tileMapByRegion,
    provinceIdsByType: provinceIdsByType,
    ownedProvinceIds: owned,
    canExpandFrom: (tileKey) =>
        (tileState.roadLevel(tileKey) > 0) || portInfo.containsKey(tileKey),
  );

  // SPEC § Blockade: no tiles in a blockaded port province contribute; remove any tile in such a province (except capital province: its tiles remain when it is blockaded, only sea connectivity is severed).
  if (blockadedPortProvinces.isNotEmpty) {
    _removeBlockadedPortTilesExceptCapital(
      connected: connected,
      pathCap: pathCap,
      blockadedPortProvinces: blockadedPortProvinces,
      capitalProvinceId: capital.provinceId,
    );
  }

  final connectedByRoadRule = Set<String>.from(connected);
  _applyTownRuleConnectivityClosure(
    game: game,
    playerId: playerId,
    owned: owned,
    tileMapByRegion: tileMapByRegion,
    provinceIdsByType: provinceIdsByType,
    worldState: worldState,
    connected: connected,
    pathCap: pathCap,
  );

  return ConnectivityResult(
    connected: connected,
    pathTransportCap: pathCap,
    connectedByRoadRule: connectedByRoadRule,
  );
}

void _runConnectivityPropagation({
  required List<String> queue,
  required Set<String> connected,
  required Map<String, int> pathCap,
  required WorldState worldState,
  required Map<String, TileMapResult> tileMapByRegion,
  required Set<String> provinceIdsByType,
  required Set<String> ownedProvinceIds,
  required bool Function(String tileKey) canExpandFrom,
}) {
  propagateConnectivityBottleneckQueue(
    queue: queue,
    connected: connected,
    pathCap: pathCap,
    shouldExpandEdgesFrom: (key) {
      final coords = parseTileKeyCoordinates(key);
      if (coords == null) return false;
      final fullProvinceId = '${coords.regionId}|${coords.provinceLocalId}';
      if (coords.x < 0 || coords.y < 0) return false;
      if (!ownedProvinceIds.contains(fullProvinceId)) return false;
      final map = tileMapByRegion[coords.regionId];
      if (map == null) return false;
      return canExpandFrom(key);
    },
    neighborsOf: (key) {
      final coords = parseTileKeyCoordinates(key);
      if (coords == null) return const <String>[];
      if (coords.x < 0 || coords.y < 0) return const <String>[];
      final map = tileMapByRegion[coords.regionId];
      if (map == null) return const <String>[];
      return _adjacentTileKeys(
        coords.regionId,
        coords.provinceLocalId,
        coords.x,
        coords.y,
        map,
        provinceIdsByType,
      );
    },
    transportLevelAt: (neighbor) => _transportLevelAtTile(worldState, neighbor),
  );
}

Set<String> _seaConnectedPortKeysForCapital({
  required CapitalTile capital,
  required WorldState worldState,
  required MapTopology topology,
  required Map<String, TileMapResult> tileMapByRegion,
  required Set<String> provinceIdsByType,
  required Set<String> ownedProvinceIds,
  required Set<String> blockadedPortProvinces,
  required Set<String> capitalRegionPortKeys,
}) {
  final out = <String>{};
  final capitalProvinceBlockaded = blockadedPortProvinces.contains(
    capital.provinceId,
  );
  final capitalOnSeaboard = _isCapitalTileOnSeaboard(
    capital,
    tileMapByRegion,
    provinceIdsByType,
  );
  if (capitalOnSeaboard && !capitalProvinceBlockaded) {
    final prefixedTopology = _topologyUsesPrefixedIds(topology);
    final provinceIdForLookup = prefixedTopology
        ? capital.provinceId
        : (ProvinceId.isPrefixed(capital.provinceId)
              ? ProvinceId.localIdFrom(capital.provinceId)
              : capital.provinceId);
    final capitalSeaZones = _seaZonesAdjacentToProvince(
      topology,
      provinceIdForLookup,
    );
    final seaReachable = _seaZonesReachableBySeaPath(topology, capitalSeaZones);
    for (final entry in worldState.portsByProvinceSeaboard.entries) {
      final portMeta = _decodePortEntry(entry.key);
      if (portMeta == null) continue;
      if (blockadedPortProvinces.contains(portMeta.fullProvinceId)) continue;
      final seaZoneIdForReachable = prefixedTopology && portMeta.isPrefixedKey
          ? '${portMeta.regionId}|${portMeta.seaZoneId}'
          : portMeta.seaZoneId;
      if (!seaReachable.contains(seaZoneIdForReachable)) continue;
      if (!ownedProvinceIds.contains(portMeta.fullProvinceId)) continue;
      out.add(entry.value);
    }
    return out;
  }
  if (!capitalOnSeaboard) {
    for (final portKey in capitalRegionPortKeys) {
      final portProvinceId = _fullProvinceIdFromTileKey(portKey);
      if (portProvinceId == null) {
        out.add(portKey);
        continue;
      }
      if (!blockadedPortProvinces.contains(portProvinceId)) {
        out.add(portKey);
      }
    }
  }
  return out;
}

String? _fullProvinceIdFromTileKey(String tileKey) {
  final coords = parseTileKeyCoordinates(tileKey);
  if (coords == null) return null;
  return '${coords.regionId}|${coords.provinceLocalId}';
}

({
  String fullProvinceId,
  String seaZoneId,
  String regionId,
  bool isPrefixedKey,
})?
_decodePortEntry(String portKey) {
  final parts = portKey.split('|');
  if (parts.length >= 3) {
    return (
      fullProvinceId: '${parts[0]}|${parts[1]}',
      seaZoneId: parts[2],
      regionId: parts[0],
      isPrefixedKey: true,
    );
  }
  if (parts.length >= 2) {
    return (
      fullProvinceId: parts[0],
      seaZoneId: parts[1],
      regionId: '',
      isPrefixedKey: false,
    );
  }
  return null;
}

/// § Connectivity (Game Rule) Town rule: 4-adjacent to a connected town in the **same** province.
void _applyTownRuleConnectivityClosure({
  required Game game,
  required String playerId,
  required Set<String> owned,
  required Map<String, TileMapResult> tileMapByRegion,
  required Set<String> provinceIdsByType,
  required WorldState worldState,
  required Set<String> connected,
  required Map<String, int> pathCap,
}) {
  var changed = true;
  while (changed) {
    changed = false;
    for (final province in allProvinces(game.worldState)) {
      if (province.ownerId != playerId) continue;
      final tk = province.townTileKey;
      if (tk == null || !connected.contains(tk)) continue;
      final coords = parseTileKeyCoordinates(tk);
      if (coords == null) continue;
      if (coords.x < 0 || coords.y < 0) continue;
      final map = tileMapByRegion[coords.regionId];
      if (map == null) continue;
      for (final d in [(0, -1), (1, 0), (0, 1), (-1, 0)]) {
        final nx = coords.x + d.$1;
        final ny = coords.y + d.$2;
        if (nx < 0 || nx >= map.width || ny < 0 || ny >= map.height) continue;
        final cell = map.cell(nx, ny);
        if (!_isLandProvinceGridCell(
          cell,
          coords.regionId,
          provinceIdsByType,
        )) {
          continue;
        }
        if (cell != coords.provinceLocalId) continue;
        final nKey = CapitalTile.tileKey(coords.regionId, province.id, nx, ny);
        if (connected.contains(nKey)) continue;
        connected.add(nKey);
        pathCap[nKey] = pathCap[tk] ?? _transportLevelAtTile(worldState, tk);
        changed = true;
      }
    }
  }
}

/// Tile grids use local province ids (`p2`); [buildCombinedTopology] uses prefixed node ids (`oldWorld|p2`).
bool _isLandProvinceGridCell(
  String localCellId,
  String regionId,
  Set<String> landProvinceNodeIds,
) {
  if (landProvinceNodeIds.contains(localCellId)) return true;
  return landProvinceNodeIds.contains(ProvinceId.full(regionId, localCellId));
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
  for (final d in [(0, -1), (1, 0), (0, 1), (-1, 0)]) {
    final nx = x + d.$1;
    final ny = y + d.$2;
    if (nx < 0 || nx >= w || ny < 0 || ny >= h) continue;
    final cellId = map.cell(nx, ny);
    if (!_isLandProvinceGridCell(cellId, regionId, provinceIdsByType)) continue;
    final fullProvinceId = '$regionId|$cellId';
    out.add(CapitalTile.tileKey(regionId, fullProvinceId, nx, ny));
  }
  return out;
}
