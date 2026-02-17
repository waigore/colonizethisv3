/// Builder for InitGameMapViewData from game + tile maps + topology.
/// SPEC/program/map-data.md § Map view model for tools.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'init_game_map_view_data.dart';
import 'tile_map_visualization_shared.dart';

const String _regionOldWorld = 'oldWorld';
const String _regionNewWorld = 'newWorld';

InitGameMapViewData buildInitGameMapViewData({
  required Game game,
  required Map<String, TileMapResult> tileMapByRegion,
  required Map<String, MapTopology> topologyByRegion,
  required int cellSize,
  int? seed,
  String? configSummary,
}) {
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
  );
  final nwRegion = _buildRegionViewData(
    regionId: _regionNewWorld,
    tileMap: nwTileMap,
    topology: nwTopology,
    game: game,
    cellSize: cellSize,
    isOldWorld: false,
  );

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
}) {
  final seaZoneIds = {
    for (final n in topology.nodes)
      if (n.type == TopologyNodeType.seaZone) n.id
  };

  // Owner mapping differs per region.
  final ownerByProvinceId = <String, String>{};
  final provinces = isOldWorld
      ? game.worldState.oldWorld.provinces
      : game.worldState.newWorld.provinces;
  for (final p in provinces) {
    if (p.ownerId != null && p.ownerId!.isNotEmpty) {
      ownerByProvinceId[p.id] = p.ownerId!;
    }
  }

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
  );

  // Terrain palette: map TerrainType to its display colour from rules.
  final terrainColors = <TerrainType, Rgb>{};
  if (tileMap.terrainGrid != null) {
    for (final row in tileMap.terrainGrid!) {
      for (final t in row) {
        if (t != null && !terrainColors.containsKey(t)) {
          // Palette will be filled by renderers; we just track presence here.
          terrainColors[t] = (0, 0, 0);
        }
      }
    }
  }

  final cells = <CellViewData>[];
  for (var y = 0; y < tileMap.height; y++) {
    for (var x = 0; x < tileMap.width; x++) {
      final id = tileMap.cell(x, y);
      final isSea = seaZoneIds.contains(id);
      final terrain = tileMap.terrainAt(x, y);
      final resource = tileMap.resourceAt(x, y);
      cells.add(
        CellViewData(
          x: x,
          y: y,
          regionCellId: id,
          isSea: isSea,
          terrainTypeId: terrain?.name,
          resourceId: resource?.name,
          ownerFactionId: ownerByProvinceId[id],
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
  );
}

