// SPEC/program/game-setup-pipeline.md §7d — province town assignment (importable library).
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_world/colonizethis_world.dart';
import 'game_setup_context.dart';
import 'game_setup_town_tile_ranking.dart';
import 'grid_bfs.dart';
import 'setup_topology_adjacency.dart';

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
  final capitalData = _collectCapitalData(game);
  final coordToKey = _buildCoordToTileKeyByRegion(tileKeysByRegion);

  Province assignTownTile(Province p) {
    final tk = _townTileKeyForProvince(
      province: p,
      tileKeysByRegion: tileKeysByRegion,
      capitalProvinceIdByOwner: capitalData.capitalProvinceIdByOwner,
      capitalTileKeyByOwner: capitalData.capitalTileKeyByOwner,
      topologyByRegion: topologyByRegion,
      tileMapByRegion: tileMapByRegion,
      portsByProvinceSeaboard: ports,
      coordToKeyByRegion: coordToKey,
    );
    return tk != null ? p.copyWith(townTileKey: tk) : p;
  }

  return game.copyWith(
    worldState: game.worldState.mapBothRegions(
      (_, region) => RegionData(
        provinces: region.provinces.map(assignTownTile).toList(),
        units: region.units,
      ),
    ),
  );
}

({
  Map<String, String> capitalProvinceIdByOwner,
  Map<String, String> capitalTileKeyByOwner,
})
_collectCapitalData(Game game) {
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
  return (
    capitalProvinceIdByOwner: capitalProvinceIdByOwner,
    capitalTileKeyByOwner: capitalTileKeyByOwner,
  );
}

Map<String, Map<String, String>> _buildCoordToTileKeyByRegion(
  Map<String, Map<String, List<String>>> tileKeysByRegion,
) {
  final coordToKey = <String, Map<String, String>>{};
  for (final regionEntry in tileKeysByRegion.entries) {
    final regionId = regionEntry.key;
    final byProvince = regionEntry.value;
    final map = <String, String>{};
    for (final list in byProvince.values) {
      for (final tileKey in list) {
        _addCoordMappingIfPresent(map, tileKey);
      }
    }
    coordToKey[regionId] = map;
  }
  return coordToKey;
}

void _addCoordMappingIfPresent(Map<String, String> out, String tileKey) {
  final coords = parseTileKeyCoordinates(tileKey);
  if (coords == null) return;
  out[gridCoordKey(coords.x, coords.y)] = tileKey;
}

String? _townTileKeyForProvince({
  required Province province,
  required Map<String, Map<String, List<String>>> tileKeysByRegion,
  required Map<String, String> capitalProvinceIdByOwner,
  required Map<String, String> capitalTileKeyByOwner,
  required Map<String, MapTopology> topologyByRegion,
  required Map<String, TileMapResult> tileMapByRegion,
  required Map<String, String> portsByProvinceSeaboard,
  required Map<String, Map<String, String>> coordToKeyByRegion,
}) {
  final ownerId = province.ownerId;
  final tiles = tileKeysByRegion[province.regionId]?[province.id] ?? [];
  if (ownerId == null) {
    return _pickTownWithoutOwner(tiles);
  }

  final capProvinceId = capitalProvinceIdByOwner[ownerId];
  final capTileKey = capitalTileKeyByOwner[ownerId];
  if (province.id == capProvinceId && capTileKey != null) {
    return capTileKey;
  }
  if (tiles.isEmpty) {
    return null;
  }

  final centroid = provinceTownCentroidFromTileKeys(tiles);
  final sameRegion =
      capProvinceId != null &&
      ProvinceId.regionIdFrom(capProvinceId) == province.regionId;
  final regionTopology = topologyByRegion[province.regionId];
  final isSeaBoundProvince =
      regionTopology != null &&
      isProvinceSeaBound(regionTopology, ProvinceId.localIdFrom(province.id));
  if (isSeaBoundProvince) {
    final seaZoneIds = seaZonesAdjacentToProvince(
      regionTopology,
      ProvinceId.localIdFrom(province.id),
    );
    final coastalCandidates = tiles
        .where(
          (tileKey) => _tileKeyAdjacentToProvinceSeaZone(
            tileKey: tileKey,
            provinceId: province.id,
            seaZoneIds: seaZoneIds,
            tileMapByRegion: tileMapByRegion,
            topologyByRegion: topologyByRegion,
          ),
        )
        .toList();
    if (coastalCandidates.isNotEmpty) {
      final distances = sameRegion && capTileKey != null
          ? _bfsDistances(
              regionId: province.regionId,
              startTileKey: capTileKey,
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
  if (sameRegion && capTileKey != null) {
    final distances = _bfsDistances(
      regionId: province.regionId,
      startTileKey: capTileKey,
      coordToKeyByRegion: coordToKeyByRegion,
    );
    return pickTownTileByCentroidAndBfs(
      candidates: tiles,
      centroidX: centroid.x,
      centroidY: centroid.y,
      bfsFromCapital: distances,
    );
  }
  final portTile = _portTileInProvince(
    provinceId: province.id,
    portsByProvinceSeaboard: portsByProvinceSeaboard,
  );
  if (portTile != null) {
    return portTile;
  }
  return pickTownTileByCentroidAndBfs(
    candidates: tiles,
    centroidX: centroid.x,
    centroidY: centroid.y,
    bfsFromCapital: const {},
  );
}

String? _pickTownWithoutOwner(List<String> tiles) {
  if (tiles.isEmpty) {
    return null;
  }
  final centroid = provinceTownCentroidFromTileKeys(tiles);
  return pickTownTileByCentroidAndBfs(
    candidates: tiles,
    centroidX: centroid.x,
    centroidY: centroid.y,
    bfsFromCapital: const {},
  );
}

Map<String, int> _bfsDistances({
  required String regionId,
  required String startTileKey,
  required Map<String, Map<String, String>> coordToKeyByRegion,
}) {
  final startCoords = parseTileKeyCoordinates(startTileKey);
  if (startCoords == null) return const <String, int>{};
  final map = coordToKeyByRegion[regionId];
  if (map == null) return const <String, int>{};
  return bfsGridDistances(
    startX: startCoords.x,
    startY: startCoords.y,
    coordToKey: map,
  );
}

String? _portTileInProvince({
  required String provinceId,
  required Map<String, String> portsByProvinceSeaboard,
}) {
  for (final entry in portsByProvinceSeaboard.entries) {
    if (entry.key.startsWith('$provinceId|')) {
      return entry.value;
    }
  }
  return null;
}

bool _tileKeyAdjacentToProvinceSeaZone({
  required String tileKey,
  required String provinceId,
  required Set<String> seaZoneIds,
  required Map<String, TileMapResult> tileMapByRegion,
  required Map<String, MapTopology> topologyByRegion,
}) {
  if (seaZoneIds.isEmpty) {
    return false;
  }
  final regionId = ProvinceId.regionIdFrom(provinceId);
  final map = tileMapByRegion[regionId];
  final topology = topologyByRegion[regionId];
  if (map == null || topology == null) {
    return false;
  }
  final coords = parseTileKeyCoordinates(tileKey);
  if (coords == null) return false;
  final provinceIds = provinceNodeIds(topology);
  return anyCardinalNeighborCell(coords.x, coords.y, map, (cellId) {
    if (provinceIds.contains(cellId)) return false;
    return seaZoneIds.contains(cellId);
  });
}
