part of 'game_setup_helpers.dart';

/// 7d. Province town assignment. For each province, set townTileKey: capital province = capital tile;
/// otherwise branch eligibility (seaboard, same-region BFS, overseas port) then centroid tie-break,
/// then shortest path to capital where applicable, then lexicographic tile key. SPEC/program/game-setup-pipeline.md.
Game assignProvinceTowns({
  required Game game,
  required Map<String, MapTopology> topologyByRegion,
  required Map<String, TileMapResult> tileMapByRegion,
}) {
  final tileKeysByRegion = game.worldState.tileKeysByRegionAndProvince;
  final ports = game.worldState.portsByProvinceSeaboard;
  final capitals = _collectCapitalOwnershipData(game);
  final coordToKey = _buildCoordToKeyByRegion(tileKeysByRegion);

  final oldProvinces = game.worldState.oldWorld.provinces.map((p) {
    final tk = _townTileKeyForProvince(
      p,
      tileKeysByRegion: tileKeysByRegion,
      ports: ports,
      capitals: capitals,
      coordToKeyByRegion: coordToKey,
      topologyByRegion: topologyByRegion,
      tileMapByRegion: tileMapByRegion,
    );
    return tk != null ? p.copyWith(townTileKey: tk) : p;
  }).toList();
  final newProvinces = game.worldState.newWorld.provinces.map((p) {
    final tk = _townTileKeyForProvince(
      p,
      tileKeysByRegion: tileKeysByRegion,
      ports: ports,
      capitals: capitals,
      coordToKeyByRegion: coordToKey,
      topologyByRegion: topologyByRegion,
      tileMapByRegion: tileMapByRegion,
    );
    return tk != null ? p.copyWith(townTileKey: tk) : p;
  }).toList();

  return game.copyWith(
    worldState: game.worldState.copyWith(
      oldWorld: RegionData(
        provinces: oldProvinces,
        units: game.worldState.oldWorld.units,
      ),
      newWorld: RegionData(
        provinces: newProvinces,
        units: game.worldState.newWorld.units,
      ),
    ),
  );
}

({
  Map<String, String> capitalTileKeyByOwner,
  Map<String, String> capitalProvinceIdByOwner,
})
_collectCapitalOwnershipData(Game game) {
  final capitalTileKeyByOwner = <String, String>{};
  final capitalProvinceIdByOwner = <String, String>{};

  void addCapital(
    String ownerId,
    String? provinceId,
    CapitalTile? capitalTile,
  ) {
    if (provinceId == null || capitalTile == null) return;
    capitalProvinceIdByOwner[ownerId] = provinceId;
    capitalTileKeyByOwner[ownerId] = capitalTile.toTileKey();
  }

  for (final p in game.players) {
    addCapital(p.id, p.capitalProvinceId, p.capitalTile);
  }
  for (final m in game.minorNations) {
    addCapital(m.id, m.capitalProvinceId, m.capitalTile);
  }
  for (final t in game.tribes) {
    addCapital(t.id, t.capitalProvinceId, t.capitalTile);
  }

  return (
    capitalTileKeyByOwner: capitalTileKeyByOwner,
    capitalProvinceIdByOwner: capitalProvinceIdByOwner,
  );
}

Map<String, Map<String, String>> _buildCoordToKeyByRegion(
  Map<String, Map<String, List<String>>> tileKeysByRegion,
) {
  final coordToKey = <String, Map<String, String>>{};
  for (final regionEntry in tileKeysByRegion.entries) {
    final regionId = regionEntry.key;
    final byProvince = regionEntry.value;
    final coordToTileKey = <String, String>{};
    for (final tileKey in byProvince.values.expand((tiles) => tiles)) {
      final coordKey = _coordKeyFromTileKey(tileKey);
      if (coordKey == null) continue;
      coordToTileKey[coordKey] = tileKey;
    }
    coordToKey[regionId] = coordToTileKey;
  }
  return coordToKey;
}

String? _coordKeyFromTileKey(String tileKey) {
  final parts = tileKey.split('|');
  if (parts.length < 4) return null;
  return '${parts[2]}|${parts[3]}';
}

Map<String, int> _bfsDistances({
  required String regionId,
  required String startTileKey,
  required Map<String, Map<String, String>> coordToKeyByRegion,
}) {
  final result = <String, int>{};
  final parts = startTileKey.split('|');
  if (parts.length < 4) return result;
  final coordToKey = coordToKeyByRegion[regionId];
  if (coordToKey == null) return result;
  final queue = <({int x, int y, int distance})>[];
  final key = '${parts[2]}|${parts[3]}';
  final sx = int.tryParse(parts[2]) ?? 0;
  final sy = int.tryParse(parts[3]) ?? 0;
  if (coordToKey[key] != null) {
    queue.add((x: sx, y: sy, distance: 0));
    result[coordToKey[key]!] = 0;
  }
  while (queue.isNotEmpty) {
    final item = queue.removeAt(0);
    for (final delta in const [
      [1, 0],
      [-1, 0],
      [0, 1],
      [0, -1],
    ]) {
      final nx = item.x + delta[0];
      final ny = item.y + delta[1];
      final tileKey = coordToKey['$nx|$ny'];
      if (tileKey != null && !result.containsKey(tileKey)) {
        result[tileKey] = item.distance + 1;
        queue.add((x: nx, y: ny, distance: item.distance + 1));
      }
    }
  }
  return result;
}

String? _portTileInProvince(
  String provinceId,
  Map<String, String> portsByProvinceSeaboard,
) {
  for (final entry in portsByProvinceSeaboard.entries) {
    if (entry.key.startsWith('$provinceId|')) return entry.value;
  }
  return null;
}

Set<String> _provinceSeaZones(
  String provinceId,
  Map<String, MapTopology> topologyByRegion,
) {
  final regionId = ProvinceId.regionIdFrom(provinceId);
  final topology = topologyByRegion[regionId];
  if (topology == null) return const <String>{};
  final localProvinceId = ProvinceId.localIdFrom(provinceId);
  final out = <String>{};
  for (final edge in topology.edges) {
    if (edge.id1 != localProvinceId && edge.id2 != localProvinceId) continue;
    final other = edge.id1 == localProvinceId ? edge.id2 : edge.id1;
    for (final node in topology.nodes) {
      if (node.id == other && node.type == TopologyNodeType.seaZone) {
        out.add(other);
        break;
      }
    }
  }
  return out;
}

bool _tileKeyAdjacentToProvinceSeaZone({
  required String tileKey,
  required String provinceId,
  required Set<String> seaZoneIds,
  required Map<String, TileMapResult> tileMapByRegion,
  required Map<String, MapTopology> topologyByRegion,
}) {
  if (seaZoneIds.isEmpty) return false;
  final regionId = ProvinceId.regionIdFrom(provinceId);
  final map = tileMapByRegion[regionId];
  final topology = topologyByRegion[regionId];
  if (map == null || topology == null) return false;
  final parts = tileKey.split('|');
  if (parts.length < 4) return false;
  final x = int.tryParse(parts[2]);
  final y = int.tryParse(parts[3]);
  if (x == null || y == null) return false;

  final provinceIds = topology.nodes
      .where((n) => n.type == TopologyNodeType.province)
      .map((n) => n.id)
      .toSet();

  for (final d in const [(0, -1), (1, 0), (0, 1), (-1, 0)]) {
    final nx = x + d.$1;
    final ny = y + d.$2;
    if (nx < 0 || nx >= map.width || ny < 0 || ny >= map.height) continue;
    final cellId = map.cell(nx, ny);
    if (provinceIds.contains(cellId)) continue;
    if (seaZoneIds.contains(cellId)) return true;
  }
  return false;
}

String? _townTileKeyForProvince(
  Province province, {
  required Map<String, Map<String, List<String>>> tileKeysByRegion,
  required Map<String, String> ports,
  required ({
    Map<String, String> capitalTileKeyByOwner,
    Map<String, String> capitalProvinceIdByOwner,
  })
  capitals,
  required Map<String, Map<String, String>> coordToKeyByRegion,
  required Map<String, MapTopology> topologyByRegion,
  required Map<String, TileMapResult> tileMapByRegion,
}) {
  final ownerId = province.ownerId;
  final tiles = tileKeysByRegion[province.regionId]?[province.id] ?? [];
  if (ownerId == null) {
    if (tiles.isEmpty) return null;
    final c = provinceTownCentroidFromTileKeys(tiles);
    return pickTownTileByCentroidAndBfs(
      candidates: tiles,
      centroidX: c.x,
      centroidY: c.y,
      bfsFromCapital: const {},
    );
  }

  final capitalProvinceId = capitals.capitalProvinceIdByOwner[ownerId];
  final capitalTileKey = capitals.capitalTileKeyByOwner[ownerId];
  if (province.id == capitalProvinceId && capitalTileKey != null) {
    return capitalTileKey;
  }
  if (tiles.isEmpty) return null;

  final centroid = provinceTownCentroidFromTileKeys(tiles);
  final sameRegion =
      capitalProvinceId != null &&
      ProvinceId.regionIdFrom(capitalProvinceId) == province.regionId;
  final regionTopology = topologyByRegion[province.regionId];
  final isSeaBoundProvince =
      regionTopology != null &&
      isProvinceSeaBound(regionTopology, ProvinceId.localIdFrom(province.id));
  if (isSeaBoundProvince) {
    final seaZoneIds = _provinceSeaZones(province.id, topologyByRegion);
    final coastalCandidates = tiles
        .where(
          (tk) => _tileKeyAdjacentToProvinceSeaZone(
            tileKey: tk,
            provinceId: province.id,
            seaZoneIds: seaZoneIds,
            tileMapByRegion: tileMapByRegion,
            topologyByRegion: topologyByRegion,
          ),
        )
        .toList();
    if (coastalCandidates.isNotEmpty) {
      final distances = sameRegion && capitalTileKey != null
          ? _bfsDistances(
              regionId: province.regionId,
              startTileKey: capitalTileKey,
              coordToKeyByRegion: coordToKeyByRegion,
            )
          : const <String, int>{};
      return pickTownTileByCentroidAndBfs(
        candidates: coastalCandidates,
        centroidX: centroid.x,
        centroidY: centroid.y,
        bfsFromCapital: distances,
      );
    }
    gameSetupLog.w(
      'seaboard town fallback for province=${province.id}: '
      'topology is sea-bound but no sea-zone-adjacent tile candidate found',
    );
  }
  if (sameRegion && capitalTileKey != null) {
    final distances = _bfsDistances(
      regionId: province.regionId,
      startTileKey: capitalTileKey,
      coordToKeyByRegion: coordToKeyByRegion,
    );
    return pickTownTileByCentroidAndBfs(
      candidates: tiles,
      centroidX: centroid.x,
      centroidY: centroid.y,
      bfsFromCapital: distances,
    );
  }
  final portTile = _portTileInProvince(province.id, ports);
  if (portTile != null) return portTile;
  return pickTownTileByCentroidAndBfs(
    candidates: tiles,
    centroidX: centroid.x,
    centroidY: centroid.y,
    bfsFromCapital: const {},
  );
}
