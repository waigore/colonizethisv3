/// Builder for InitGameMapViewData from game + tile maps + topology.
/// SPEC/program/map-data.md § Map view model for tools.

import 'dart:convert';
import 'dart:io';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:logger/logger.dart';

import 'init_game_map_view_data.dart';
import 'tile_map_visualization_shared.dart';

const String _regionOldWorld = 'oldWorld';
const String _regionNewWorld = 'newWorld';

// #region agent log
const String _agentDebugLogPath =
    '/Users/waigore/Documents/GitHub/colonizethisv3/.cursor/debug-9f02df.log';

void _agentDebugLog({
  required String runId,
  required String hypothesisId,
  required String location,
  required String message,
  required Map<String, Object?> data,
}) {
  try {
    final payload = <String, Object?>{
      'sessionId': '9f02df',
      'runId': runId,
      'hypothesisId': hypothesisId,
      'location': location,
      'message': message,
      'data': data,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    final line = '${jsonEncode(payload)}\n';
    File(_agentDebugLogPath).writeAsStringSync(
      line,
      mode: FileMode.append,
      flush: false,
    );
  } catch (_) {
    // Swallow all errors in debug logger.
  }
}
// #endregion

InitGameMapViewData buildInitGameMapViewData({
  required Game game,
  required Map<String, TileMapResult> tileMapByRegion,
  required Map<String, MapTopology> topologyByRegion,
  required int cellSize,
  int? seed,
  String? configSummary,
  Map<String, (int r, int g, int b)>? greatPowerColorOverride,
}) {
  Logger().i('map: buildInitGameMapViewData start gameId=${game.id}');
  final owTileMap = tileMapByRegion[_regionOldWorld]!;
  final nwTileMap = tileMapByRegion[_regionNewWorld]!;
  final owTopology = topologyByRegion[_regionOldWorld]!;
  final nwTopology = topologyByRegion[_regionNewWorld]!;

  final owRegion = _buildRegionViewData(
    regionId: _regionOldWorld,
    tileMap: owTileMap,
    topology: owTopology,
    game: game,
    cellSize: cellSize,
    isOldWorld: true,
    greatPowerColorOverride: greatPowerColorOverride,
  );
  final nwRegion = _buildRegionViewData(
    regionId: _regionNewWorld,
    tileMap: nwTileMap,
    topology: nwTopology,
    game: game,
    cellSize: cellSize,
    isOldWorld: false,
    greatPowerColorOverride: greatPowerColorOverride,
  );

  Logger().i('map: buildInitGameMapViewData end');
  return InitGameMapViewData(
    oldWorld: owRegion,
    newWorld: nwRegion,
    seed: seed,
    configSummary: configSummary,
  );
}

RegionMapViewData _buildRegionViewData({
  required String regionId,
  required TileMapResult tileMap,
  required MapTopology topology,
  required Game game,
  required int cellSize,
  required bool isOldWorld,
  Map<String, (int r, int g, int b)>? greatPowerColorOverride,
}) {
  final seaZoneIds = {
    for (final n in topology.nodes)
      if (n.type == TopologyNodeType.seaZone) n.id
  };

  // Owner and province display name by province id.
  final ownerByProvinceId = <String, String>{};
  final provinceDisplayNameById = <String, String>{};
  final provinces = isOldWorld
      ? game.worldState.oldWorld.provinces
      : game.worldState.newWorld.provinces;
  for (final p in provinces) {
    if (p.ownerId != null && p.ownerId!.isNotEmpty) {
      ownerByProvinceId[p.id] = p.ownerId!;
    }
    if (p.displayName != null && p.displayName!.isNotEmpty) {
      provinceDisplayNameById[p.id] = p.displayName!;
    }
  }

  // #region agent log
  _agentDebugLog(
    runId: 'pre-fix-1',
    hypothesisId: 'H1-H2-H5',
    location: 'init_game_map_view_builder.dart:_buildRegionViewData',
    message: 'Province ownership mapping built for region',
    data: {
      'regionId': regionId,
      'isOldWorld': isOldWorld,
      'provinceCount': provinces.length,
      'ownedProvinceCount': ownerByProvinceId.length,
      'sampleProvinceIds': provinces.take(5).map((p) => p.id).toList(),
      'sampleOwnerProvinceKeys': ownerByProvinceId.keys.take(5).toList(),
    },
  );
  // #endregion

  // Collect faction ids by type for ownership colours.
  final greatPowerIds = <String>[];
  final minorNationIds = <String>[];
  final tribeIds = <String>[];
  for (final p in game.players) {
    greatPowerIds.add(p.id);
  }
  for (final m in game.minorNations) {
    minorNationIds.add(m.id);
  }
  for (final t in game.tribes) {
    tribeIds.add(t.id);
  }
  final factionColors = factionOwnershipColorMap(
    greatPowerIds: greatPowerIds,
    minorNationIds: minorNationIds,
    tribeIds: tribeIds,
    greatPowerColorOverride: greatPowerColorOverride,
  );

  // Terrain palette: same as base tile map PNG (shared terrainColorRgb).
  final terrainColors = <TerrainType, Rgb>{};
  if (tileMap.terrainGrid != null) {
    for (final row in tileMap.terrainGrid!) {
      for (final t in row) {
        if (t != null && !terrainColors.containsKey(t)) {
          terrainColors[t] = terrainColorRgb[t]!;
        }
      }
    }
  }

  final tileState = game.worldState.tileState;
  final cells = <CellViewData>[];
  for (var y = 0; y < tileMap.height; y++) {
    for (var x = 0; x < tileMap.width; x++) {
      final localId = tileMap.cell(x, y);
      final isSea = seaZoneIds.contains(localId);
      final terrain = tileMap.terrainAt(x, y);
      final resource = tileMap.resourceAt(x, y);
      // Tile key for improvement/road lookup: regionId|provinceId|x|y (provinceId = regionCellId for land).
      final tileKey = '$regionId|$localId|$x|$y';
      final improvement = isSea ? null : tileState.improvementLevel(tileKey);
      final road = isSea ? null : tileState.roadLevel(tileKey);
      final fullProvinceId =
          isSea ? null : ProvinceId.full(regionId, localId);
      cells.add(
        CellViewData(
          x: x,
          y: y,
          regionCellId: localId,
          isSea: isSea,
          terrainTypeId: terrain?.name,
          terrainType: terrain,
          resourceId: resource?.name,
          ownerFactionId:
              fullProvinceId != null ? ownerByProvinceId[fullProvinceId] : null,
          provinceDisplayName: isSea
              ? null
              : (fullProvinceId != null
                  ? provinceDisplayNameById[fullProvinceId]
                  : null),
          improvementLevel: isSea ? null : improvement,
          roadLevel: isSea ? null : road,
        ),
      );
    }
  }

  // Capital markers.
  final capitals = <CapitalMarkerView>[];
  for (final p in game.players) {
    final cap = p.capitalTile;
    if (cap != null && cap.regionId == regionId) {
      capitals.add(
        CapitalMarkerView(
          factionId: p.id,
          displayName: p.displayName,
          x: cap.x,
          y: cap.y,
        ),
      );
    }
  }
  for (final m in game.minorNations) {
    final cap = m.capitalTile;
    if (cap != null && cap.regionId == regionId) {
      capitals.add(
        CapitalMarkerView(
          factionId: m.id,
          displayName: m.displayName ?? m.id,
          x: cap.x,
          y: cap.y,
        ),
      );
    }
  }
  for (final t in game.tribes) {
    final cap = t.capitalTile;
    if (cap != null && cap.regionId == regionId) {
      capitals.add(
        CapitalMarkerView(
          factionId: t.id,
          displayName: t.displayName ?? t.id,
          x: cap.x,
          y: cap.y,
        ),
      );
    }
  }

  // Province id → representative tile (x,y) for units overlay.
  final provinceToTile = <String, (int x, int y)>{};
  for (var y = 0; y < tileMap.height; y++) {
    for (var x = 0; x < tileMap.width; x++) {
      final localId = tileMap.cell(x, y);
      if (seaZoneIds.contains(localId)) {
        continue;
      }
      final fullProvinceId = ProvinceId.full(regionId, localId);
      if (!provinceToTile.containsKey(fullProvinceId)) {
        provinceToTile[fullProvinceId] = (x, y);
      }
    }
  }

  // Unit markers: one per unit, placed at province representative tile.
  final unitMarkers = <UnitMarkerView>[];
  final regionUnits = isOldWorld
      ? game.worldState.oldWorld.units
      : game.worldState.newWorld.units;
  for (final u in regionUnits) {
    final tile = provinceToTile[u.provinceId];
    if (tile != null) {
      unitMarkers.add(UnitMarkerView(
        x: tile.$1,
        y: tile.$2,
        ownerFactionId: u.ownerId,
      ));
    }
  }

  // Port markers from world state.
  final ports = <PortMarkerView>[];
  final portsByProvinceSeaboard = game.worldState.portsByProvinceSeaboard;
  portsByProvinceSeaboard.forEach((key, tileKey) {
    final parts = tileKey.split('|');
    if (parts.length < 4) {
      return;
    }
    final regId = parts[0];
    if (regId != regionId) {
      return;
    }
    final provinceId = parts[1];
    final x = int.tryParse(parts[2]);
    final y = int.tryParse(parts[3]);
    if (x == null || y == null) {
      return;
    }
    ports.add(
      PortMarkerView(
        x: x,
        y: y,
        provinceId: provinceId,
        seaZoneId: '',
        seaboardKey: key,
      ),
    );
  });

  return RegionMapViewData(
    regionId: regionId,
    width: tileMap.width,
    height: tileMap.height,
    cellSize: cellSize,
    cells: cells,
    capitalMarkers: capitals,
    portMarkers: ports,
    factionColors: factionColors,
    terrainColors: terrainColors,
    unitMarkers: unitMarkers,
  );
}

