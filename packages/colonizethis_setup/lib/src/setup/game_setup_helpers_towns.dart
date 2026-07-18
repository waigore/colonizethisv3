// SPEC/program/game-setup-pipeline.md §7d — province town assignment (importable library).
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_world/colonizethis_world.dart';
import 'faction_setup_helpers.dart';
import 'game_setup_context.dart';
import 'game_setup_plains_conversion.dart';
import 'game_setup_town_tile_ranking.dart';
import 'grid_bfs.dart';
import 'setup_road_wiring.dart';
import 'setup_topology_adjacency.dart';

/// 7d. Province town assignment. For each province, set townTileKey: capital province = capital tile;
/// otherwise branch eligibility (seaboard, same-region BFS, overseas port) then prefer plains among
/// candidates, then centroid/BFS/lex ranking; convert selected non-plains tile to plains.
/// SPEC/program/game-setup-pipeline.md; SPEC/game/capital-and-connectivity.md § Town.
Game assignProvinceTowns({
  required Game game,
  required Map<String, MapTopology> topologyByRegion,
  required Map<String, TileMapResult> tileMapByRegion,
}) {
  final tileKeysByRegion = game.worldState.tileKeysByRegionAndProvince;
  final ports = game.worldState.portsByProvinceSeaboard;
  final capitalData = collectCapitalMapsByOwner(game);
  final coordToKey = coordToTileKeyByRegion(tileKeysByRegion);

  var outGame = game;

  List<Province> assignTownsInRegion(List<Province> provinces) {
    final next = <Province>[];
    for (final p in provinces) {
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
      if (tk == null) {
        next.add(p);
        continue;
      }
      final ensured = ensureTileIsPlains(
        game: outGame,
        tileMapByRegion: tileMapByRegion,
        tileKey: tk,
      );
      outGame = ensured.game;
      next.add(p.copyWith(townTileKey: tk));
    }
    return next;
  }

  final ow = outGame.worldState.oldWorld;
  final nw = outGame.worldState.newWorld;
  return outGame.copyWith(
    worldState: outGame.worldState.copyWith(
      oldWorld: RegionData(
        provinces: assignTownsInRegion(ow.provinces),
        units: ow.units,
      ),
      newWorld: RegionData(
        provinces: assignTownsInRegion(nw.provinces),
        units: nw.units,
      ),
    ),
  );
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
  final regionMap = tileMapByRegion[province.regionId];
  if (ownerId == null) {
    return _pickTownWithoutOwner(tiles, regionMap);
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
          (tileKey) => tileKeyAdjacentToAnySeaZone(
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
        candidates: preferPlainsTownCandidates(
          candidates: coastalCandidates,
          tileMap: regionMap,
        ),
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
      candidates: preferPlainsTownCandidates(
        candidates: tiles,
        tileMap: regionMap,
      ),
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
    candidates: preferPlainsTownCandidates(
      candidates: tiles,
      tileMap: regionMap,
    ),
    centroidX: centroid.x,
    centroidY: centroid.y,
    bfsFromCapital: const {},
  );
}

String? _pickTownWithoutOwner(List<String> tiles, TileMapResult? tileMap) {
  if (tiles.isEmpty) {
    return null;
  }
  final centroid = provinceTownCentroidFromTileKeys(tiles);
  return pickTownTileByCentroidAndBfs(
    candidates: preferPlainsTownCandidates(
      candidates: tiles,
      tileMap: tileMap,
    ),
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
