import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../constants.dart';

/// Resolves which tiles are connected to each player's capital. SPEC/game/capital-and-connectivity.
///
/// Connectivity: from capital, BFS over land; edges are same-province adjacency;
/// we expand only from capital or tiles with road/port. Overseas: ports connected
/// by shared sea zone; from those ports, BFS within province by road/adjacency.

/// Returns per player id the set of connected tile keys (format "regionId|provinceId|x|y").
/// Players without capital or with no tile map get an empty set.
Map<String, Set<String>> resolveConnectivity({
  required Game game,
  required Map<String, TileMapResult> tileMapByRegion,
  required MapTopology topology,
}) {
  final provinceIdsByType = _provinceIdsFromTopology(topology);
  final result = <String, Set<String>>{};

  for (final player in game.players) {
    final capital = player.capitalTile;
    if (capital == null || player.capitalProvinceId == null) {
      result[player.id] = {};
      continue;
    }

    final connected = _connectedTilesForPlayer(
      game: game,
      playerId: player.id,
      capital: capital,
      tileMapByRegion: tileMapByRegion,
      topology: topology,
      provinceIdsByType: provinceIdsByType,
    );
    result[player.id] = connected;
  }

  return result;
}

Set<String> _provinceIdsFromTopology(MapTopology topology) {
  return topology.nodes
      .where((n) => n.type == TopologyNodeType.province)
      .map((n) => n.id)
      .toSet();
}

RegionData _regionData(Game game, String regionId) {
  if (regionId == kRegionOldWorld) return game.worldState.oldWorld;
  if (regionId == kRegionNewWorld) return game.worldState.newWorld;
  return const RegionData();
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

Set<String> _connectedTilesForPlayer({
  required Game game,
  required String playerId,
  required CapitalTile capital,
  required Map<String, TileMapResult> tileMapByRegion,
  required MapTopology topology,
  required Set<String> provinceIdsByType,
}) {
  final worldState = game.worldState;
  final tileState = worldState.tileState;
  final owned = _ownedProvinceIdsForPlayer(game, playerId);
  if (!owned.contains(capital.provinceId)) return {};

  final capitalRegionId = capital.regionId;
  final mapOpt = tileMapByRegion[capitalRegionId];
  if (mapOpt == null) return {};

  final capitalKey = capital.toTileKey();
  final connected = <String>{capitalKey};
  final queue = <String>[capitalKey];

  final portInfo = _portToProvinceSeaZone(worldState);

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

    final region = _regionData(game, regionId);
    final map = tileMapByRegion[regionId];
    if (map == null) continue;

    final hasRoadOrPort = (tileState.roadLevel(key) > 0) || portInfo.containsKey(key);
    final canExpand = (key == capitalKey) || hasRoadOrPort;

    if (!canExpand) continue;

    for (final n in _adjacentTileKeys(regionId, localProvinceId, x, y, map, provinceIdsByType)) {
      if (connected.contains(n)) continue;
      connected.add(n);
      queue.add(n);
    }
  }

  // Overseas: port tile keys that are connected and in the capital region.
  final capitalRegionPortKeys = <String>{};
  for (final k in connected) {
    final info = portInfo[k];
    if (info == null) continue;
    final parts = k.split('|');
    if (parts.isEmpty) continue;
    if (parts[0] == capitalRegionId) capitalRegionPortKeys.add(k);
  }

  final seaZoneToPortKeys = <String, Set<String>>{};
  for (final e in worldState.portsByProvinceSeaboard.entries) {
    final provSea = e.key;
    final tileKey = e.value;
    final parts = provSea.split('|');
    if (parts.length >= 3) {
      final seaZoneId = parts[2];
      seaZoneToPortKeys.putIfAbsent(seaZoneId, () => {}).add(tileKey);
    } else if (parts.length >= 2) {
      final seaZoneId = parts[1];
      seaZoneToPortKeys.putIfAbsent(seaZoneId, () => {}).add(tileKey);
    }
  }

  final seaConnectedPortKeys = <String>{};
  for (final portKey in capitalRegionPortKeys) {
    final info = portInfo[portKey];
    if (info == null) continue;
    final (_, seaZoneId) = info;
    for (final other in seaZoneToPortKeys[seaZoneId] ?? {}) {
      final otherInfo = portInfo[other];
      if (otherInfo == null) continue;
      final (otherProv, _) = otherInfo;
      if (owned.contains(otherProv)) seaConnectedPortKeys.add(other);
    }
  }

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

    for (final n in _adjacentTileKeys(regionId, provinceId, x, y, map, provinceIdsByType)) {
      if (connected.contains(n)) continue;
      connected.add(n);
      queue.add(n);
    }
  }

  return connected;
}

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
    if (cellId != provinceId) continue;
    out.add(CapitalTile.tileKey(regionId, provinceId, nx, ny));
  }
  return out;
}
