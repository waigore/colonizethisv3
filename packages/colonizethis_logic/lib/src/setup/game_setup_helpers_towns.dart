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

  final capitalTileKeyByOwner = <String, String>{};
  final capitalProvinceIdByOwner = <String, String>{};
  for (final p in game.players) {
    if (p.capitalProvinceId != null && p.capitalTile != null) {
      capitalProvinceIdByOwner[p.id] = p.capitalProvinceId!;
      capitalTileKeyByOwner[p.id] = p.capitalTile!.toTileKey();
    }
  }
  for (final m in game.minorNations) {
    if (m.capitalProvinceId != null && m.capitalTile != null) {
      capitalProvinceIdByOwner[m.id] = m.capitalProvinceId!;
      capitalTileKeyByOwner[m.id] = m.capitalTile!.toTileKey();
    }
  }
  for (final t in game.tribes) {
    if (t.capitalProvinceId != null && t.capitalTile != null) {
      capitalProvinceIdByOwner[t.id] = t.capitalProvinceId!;
      capitalTileKeyByOwner[t.id] = t.capitalTile!.toTileKey();
    }
  }

  final coordToKey = <String, Map<String, String>>{};
  for (final regionEntry in tileKeysByRegion.entries) {
    final regionId = regionEntry.key;
    final byProvince = regionEntry.value;
    final m = <String, String>{};
    for (final list in byProvince.values) {
      for (final tk in list) {
        final parts = tk.split('|');
        if (parts.length >= 4) {
          m['${parts[2]}|${parts[3]}'] = tk;
        }
      }
    }
    coordToKey[regionId] = m;
  }

  Map<String, int> bfsDistances(String regionId, String startTileKey) {
    final result = <String, int>{};
    final parts = startTileKey.split('|');
    if (parts.length < 4) return result;
    final m = coordToKey[regionId];
    if (m == null) return result;
    final queue = <({int x, int y, int distance})>[];
    final key = '${parts[2]}|${parts[3]}';
    final sx = int.tryParse(parts[2]) ?? 0;
    final sy = int.tryParse(parts[3]) ?? 0;
    if (m[key] != null) {
      queue.add((x: sx, y: sy, distance: 0));
      result[m[key]!] = 0;
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
        final tileKey = m['$nx|$ny'];
        if (tileKey != null && !result.containsKey(tileKey)) {
          result[tileKey] = item.distance + 1;
          queue.add((x: nx, y: ny, distance: item.distance + 1));
        }
      }
    }
    return result;
  }

  String? portTileInProvince(String provinceId) {
    for (final entry in ports.entries) {
      if (entry.key.startsWith('$provinceId|')) return entry.value;
    }
    return null;
  }

  Set<String> provinceSeaZones(String provinceId) {
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

  bool tileKeyAdjacentToProvinceSeaZone({
    required String tileKey,
    required String provinceId,
    required Set<String> seaZoneIds,
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

  String? townTileKeyForProvince(Province p) {
    final ownerId = p.ownerId;
    final tiles = tileKeysByRegion[p.regionId]?[p.id] ?? [];
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

    final capProvinceId = capitalProvinceIdByOwner[ownerId];
    final capTileKey = capitalTileKeyByOwner[ownerId];
    if (p.id == capProvinceId && capTileKey != null) return capTileKey;
    if (tiles.isEmpty) return null;

    final centroid = provinceTownCentroidFromTileKeys(tiles);
    final sameRegion =
        capProvinceId != null &&
        ProvinceId.regionIdFrom(capProvinceId) == p.regionId;
    final regionTopology = topologyByRegion[p.regionId];
    final isSeaBoundProvince =
        regionTopology != null &&
        isProvinceSeaBound(regionTopology, ProvinceId.localIdFrom(p.id));
    if (isSeaBoundProvince) {
      final seaZoneIds = provinceSeaZones(p.id);
      final coastalCandidates = tiles
          .where(
            (tk) => tileKeyAdjacentToProvinceSeaZone(
              tileKey: tk,
              provinceId: p.id,
              seaZoneIds: seaZoneIds,
            ),
          )
          .toList();
      if (coastalCandidates.isNotEmpty) {
        final distances = sameRegion && capTileKey != null
            ? bfsDistances(p.regionId, capTileKey)
            : const <String, int>{};
        return pickTownTileByCentroidAndBfs(
          candidates: coastalCandidates,
          centroidX: centroid.x,
          centroidY: centroid.y,
          bfsFromCapital: distances,
        );
      }
      gameSetupLog.w(
        'seaboard town fallback for province=${p.id}: '
        'topology is sea-bound but no sea-zone-adjacent tile candidate found',
      );
    }
    if (sameRegion && capTileKey != null) {
      final distances = bfsDistances(p.regionId, capTileKey);
      return pickTownTileByCentroidAndBfs(
        candidates: tiles,
        centroidX: centroid.x,
        centroidY: centroid.y,
        bfsFromCapital: distances,
      );
    }
    final portTile = portTileInProvince(p.id);
    if (portTile != null) return portTile;
    return pickTownTileByCentroidAndBfs(
      candidates: tiles,
      centroidX: centroid.x,
      centroidY: centroid.y,
      bfsFromCapital: const {},
    );
  }

  final oldProvinces = game.worldState.oldWorld.provinces.map((p) {
    final tk = townTileKeyForProvince(p);
    return tk != null ? p.copyWith(townTileKey: tk) : p;
  }).toList();
  final newProvinces = game.worldState.newWorld.provinces.map((p) {
    final tk = townTileKeyForProvince(p);
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
