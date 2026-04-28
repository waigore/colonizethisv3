/// Builder for InitGameMapViewData from game + tile maps + topology.
/// SPEC/program/map-visualization.md § Map view model for tools.
library;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_map/package_logger.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'combine_region_topologies.dart';
import 'init_game_map_view_data.dart';
import 'port_icon_placement.dart';
import 'sea_zone_centroid_tile.dart';
import 'tile_map_visualization_shared.dart';

final _log = packageLogger();

const String _regionOldWorld = 'oldWorld';
const String _regionNewWorld = 'newWorld';

String _normalizeCivilianTypeForPriority(String type) {
  return type.toLowerCase().replaceAll(RegExp(r'[\s_\-]'), '');
}

int _civilianIconPriorityForType(String type) {
  final normalized = _normalizeCivilianTypeForPriority(type);
  // Lower number = higher icon priority.
  switch (normalized) {
    case 'builder':
      return 0;
    case 'engineer':
      return 1;
    case 'railbuilder':
      return 2;
    case 'explorer':
      return 3;
    case 'merchant':
      return 4;
    case 'spy':
      return 5;
    default:
      return 999;
  }
}

bool _isCivilianUnitType(String unitType) {
  final role = unitRoleForType(unitType);
  if (role == null) {
    return false;
  }
  return role != UnitRole.military && role != UnitRole.naval;
}

String _homeFleetIdForMapMarker(String playerId) => 'fleet_$playerId';

bool _fleetAtHumanCapital(Game game, String playerId, Fleet fleet) {
  if (!fleet.isInPort || fleet.inPortAtProvinceId == null) {
    return false;
  }
  final player = game.players.firstWhere(
    (p) => p.id == playerId,
    orElse: () => game.players.first,
  );
  if (!player.isHuman) {
    return false;
  }
  final cap = player.capitalTile;
  if (cap == null) {
    return false;
  }
  final capParts = cap.toTileKey().split('|');
  if (capParts.length < 2) {
    return false;
  }
  final capReg = capParts[0];
  final capProvLocal = capParts[1];
  if (fleet.regionId != capReg) {
    return false;
  }
  final port = fleet.inPortAtProvinceId!;
  return port == capProvLocal || port == '$capReg|$capProvLocal';
}

bool _includeFleetForTileMarker(
  Game game,
  Fleet f,
  String regionId,
  Set<String> humanIds,
) {
  if (!humanIds.contains(f.ownerId) || f.regionId != regionId) {
    return false;
  }
  if (f.shipTypeIds.isNotEmpty) {
    return true;
  }
  return f.id == _homeFleetIdForMapMarker(f.ownerId) &&
      _fleetAtHumanCapital(game, f.ownerId, f);
}

String? _inPortFleetMarkerTileKey({
  required Game game,
  required String regionId,
  required Province province,
  required TileMapResult tileMap,
  required Set<String> seaZoneIds,
}) {
  final localProvinceId = ProvinceId.localIdFrom(province.id);
  final tileKey = harborDrawableSeaTileKeyForPortProvince(
    game: game,
    regionId: regionId,
    localProvinceId: localProvinceId,
    tileMap: tileMap,
    seaZoneIds: seaZoneIds,
    contextLabel: 'fleet marker region=$regionId province=$localProvinceId',
  );
  if (tileKey == null) {
    _log.w(
      'map: in-port fleet marker skipped: no portsByProvinceSeaboard entry '
      'for region=$regionId province=$localProvinceId',
    );
  }
  return tileKey;
}

(int?, int?) _xyFromMapTileKey(String tileKey) {
  final parts = tileKey.split('|');
  if (parts.length < 4) {
    return (null, null);
  }
  final x = int.tryParse(parts[parts.length - 2]);
  final y = int.tryParse(parts[parts.length - 1]);
  return (x, y);
}

List<FleetTileMarkerView> _buildFleetTileMarkersForRegion({
  required Game game,
  required String regionId,
  required List<Province> provinces,
  required TileMapResult tileMap,
  required Set<String> seaZoneIds,
}) {
  final humanIds = game.players
      .where((p) => p.isHuman)
      .map((p) => p.id)
      .toSet();
  if (humanIds.isEmpty) {
    return const [];
  }

  final provinceMap = <String, Province>{
    for (final p in provinces) ...{'${p.regionId}|${p.id}': p, p.id: p},
  };

  final byLocation = <String, List<Fleet>>{};

  for (final f in game.worldState.fleets) {
    if (!_includeFleetForTileMarker(game, f, regionId, humanIds)) {
      continue;
    }
    if (f.isAtSea && f.seaZoneId != null) {
      final z = f.seaZoneId!;
      final zoneKey = z.contains('|') ? z : '$regionId|$z';
      byLocation.putIfAbsent('sea:$zoneKey', () => []).add(f);
    } else if (f.inPortAtProvinceId != null) {
      final province =
          provinceMap['$regionId|${f.inPortAtProvinceId}'] ??
          provinceMap[f.inPortAtProvinceId!];
      if (province == null) {
        continue;
      }
      byLocation
          .putIfAbsent('port:${province.regionId}|${province.id}', () => [])
          .add(f);
    }
  }

  final markers = <FleetTileMarkerView>[];
  for (final entry in byLocation.entries) {
    final scopeKey = entry.key;
    final fleets = entry.value.toList()..sort((a, b) => a.id.compareTo(b.id));
    final fleetIds = fleets.map((fl) => fl.id).toList();

    String? tileKey;
    if (scopeKey.startsWith('sea:')) {
      final zoneKey = scopeKey.substring(4);
      final local = zoneKey.contains('|') ? zoneKey.split('|').last : zoneKey;
      tileKey = seaZoneCentroidTileKey(
        tileMap: tileMap,
        regionId: regionId,
        localSeaZoneId: local,
        seaZoneNodeIds: seaZoneIds,
      );
    } else if (scopeKey.startsWith('port:')) {
      final fullProv = scopeKey.substring(5);
      final province = provinceMap[fullProv];
      if (province != null) {
        tileKey = _inPortFleetMarkerTileKey(
          game: game,
          regionId: regionId,
          province: province,
          tileMap: tileMap,
          seaZoneIds: seaZoneIds,
        );
      }
    }
    if (tileKey == null) {
      continue;
    }
    final xy = _xyFromMapTileKey(tileKey);
    final x = xy.$1;
    final y = xy.$2;
    if (x == null || y == null) {
      continue;
    }
    markers.add(
      FleetTileMarkerView(
        tileKey: tileKey,
        x: x,
        y: y,
        locationScopeKey: scopeKey,
        fleetIds: fleetIds,
        stackCount: fleetIds.length,
      ),
    );
  }
  markers.sort((a, b) {
    final yc = a.y.compareTo(b.y);
    if (yc != 0) {
      return yc;
    }
    final xc = a.x.compareTo(b.x);
    if (xc != 0) {
      return xc;
    }
    return a.tileKey.compareTo(b.tileKey);
  });
  return markers;
}

InitGameMapViewData buildInitGameMapViewData({
  required Game game,
  required Map<String, TileMapResult> tileMapByRegion,
  required Map<String, MapTopology> topologyByRegion,
  required int cellSize,
  int? seed,
  String? configSummary,
  Map<String, (int r, int g, int b)>? greatPowerColorOverride,

  /// Optional per-tile visibility for the current player view, keyed by tile
  /// key `regionId|provinceId|x|y`. When omitted, all tiles are treated as
  /// [TileVisibility.visible] in the view data.
  Map<String, TileVisibility>? visibilityByTile,

  /// Optional warp links for rendering warp zone indicators.
  List<WarpLink>? warpLinks,

  /// Optional per-tile extraction units for map overlays, keyed by tile key
  /// `regionId|provinceId|x|y`.
  Map<String, int>? resourceExtractionUnitsByTile,

  /// Optional per-tile effective transported extraction units for map overlays.
  Map<String, int>? resourceExtractionEffectiveUnitsByTile,

  /// Optional per-tile transport-blocked extraction units for map overlays.
  Map<String, int>? resourceExtractionBlockedUnitsByTile,
}) {
  _log.i('buildInitGameMapViewData start gameId=${game.id}');
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
    visibilityByTile: visibilityByTile,
    warpLinks: warpLinks,
    resourceExtractionUnitsByTile: resourceExtractionUnitsByTile,
    resourceExtractionEffectiveUnitsByTile:
        resourceExtractionEffectiveUnitsByTile,
    resourceExtractionBlockedUnitsByTile: resourceExtractionBlockedUnitsByTile,
  );
  final nwRegion = _buildRegionViewData(
    regionId: _regionNewWorld,
    tileMap: nwTileMap,
    topology: nwTopology,
    game: game,
    cellSize: cellSize,
    isOldWorld: false,
    greatPowerColorOverride: greatPowerColorOverride,
    visibilityByTile: visibilityByTile,
    warpLinks: warpLinks,
    resourceExtractionUnitsByTile: resourceExtractionUnitsByTile,
    resourceExtractionEffectiveUnitsByTile:
        resourceExtractionEffectiveUnitsByTile,
    resourceExtractionBlockedUnitsByTile: resourceExtractionBlockedUnitsByTile,
  );

  _log.i('buildInitGameMapViewData end');
  final combinedTopology = combineRegionTopologies(
    topologyByRegion: topologyByRegion,
    warpLinks: warpLinks ?? const [],
  );
  return InitGameMapViewData(
    oldWorld: owRegion,
    newWorld: nwRegion,
    combinedTopology: combinedTopology,
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
  Map<String, TileVisibility>? visibilityByTile,
  List<WarpLink>? warpLinks,
  Map<String, int>? resourceExtractionUnitsByTile,
  Map<String, int>? resourceExtractionEffectiveUnitsByTile,
  Map<String, int>? resourceExtractionBlockedUnitsByTile,
}) {
  final provinceMeta = _buildProvinceMetadata(
    game: game,
    isOldWorld: isOldWorld,
    topology: topology,
  );
  final factionData = _buildFactionColorData(
    game: game,
    greatPowerColorOverride: greatPowerColorOverride,
  );
  final cellAndUnitData = _buildCellAndUnitData(
    game: game,
    regionId: regionId,
    tileMap: tileMap,
    isOldWorld: isOldWorld,
    provinces: provinceMeta.provinces,
    seaZoneIds: provinceMeta.seaZoneIds,
    ownerByProvinceId: provinceMeta.ownerByProvinceId,
    provinceDisplayNameById: provinceMeta.provinceDisplayNameById,
    visibilityByTile: visibilityByTile,
    resourceExtractionUnitsByTile: resourceExtractionUnitsByTile,
    resourceExtractionEffectiveUnitsByTile:
        resourceExtractionEffectiveUnitsByTile,
    resourceExtractionBlockedUnitsByTile: resourceExtractionBlockedUnitsByTile,
  );
  final markerData = _buildMarkerData(
    game: game,
    regionId: regionId,
    tileMap: tileMap,
    topology: topology,
    provinces: provinceMeta.provinces,
    seaZoneIds: provinceMeta.seaZoneIds,
    warpLinks: warpLinks,
    provincePresenceById: cellAndUnitData.provincePresenceById,
  );
  return _buildRegionMapViewDataFromParts(
    regionId: regionId,
    tileMap: tileMap,
    game: game,
    cellSize: cellSize,
    provinceMeta: provinceMeta,
    factionData: factionData,
    cellAndUnitData: cellAndUnitData,
    markerData: markerData,
  );
}

RegionMapViewData _buildRegionMapViewDataFromParts({
  required String regionId,
  required TileMapResult tileMap,
  required Game game,
  required int cellSize,
  required ({
    Set<String> seaZoneIds,
    List<Province> provinces,
    Map<String, String> ownerByProvinceId,
    Map<String, String> provinceDisplayNameById,
    Map<String, String?> provincePoliticalOwnerByPrefixedProvinceId,
  })
  provinceMeta,
  required ({
    Set<String> greatPowerFactionIds,
    Map<String, (int r, int g, int b)> factionColors,
  })
  factionData,
  required ({
    List<CellViewData> cells,
    List<CapitalMarkerView> capitals,
    List<UnitMarkerView> unitMarkers,
    List<CivilianTileMarkerView> civilianTileMarkers,
    Map<String, ProvinceUnitPresenceView> provincePresenceById,
  })
  cellAndUnitData,
  required ({
    List<PortMarkerView> ports,
    List<TownMarkerView> towns,
    List<WarpMarkerView> warpMarkers,
    List<FleetTileMarkerView> fleetTileMarkers,
  })
  markerData,
}) {
  return RegionMapViewData(
    regionId: regionId,
    width: tileMap.width,
    height: tileMap.height,
    cellSize: cellSize,
    cells: cellAndUnitData.cells,
    capitalMarkers: cellAndUnitData.capitals,
    portMarkers: markerData.ports,
    factionColors: factionData.factionColors,
    greatPowerFactionIds: factionData.greatPowerFactionIds,
    terrainColors: _buildTerrainColors(tileMap),
    unitMarkers: cellAndUnitData.unitMarkers,
    civilianTileMarkers: cellAndUnitData.civilianTileMarkers,
    fleetTileMarkers: markerData.fleetTileMarkers,
    warpMarkers: markerData.warpMarkers,
    townMarkers: markerData.towns,
    provinceUnitPresenceByProvinceId: cellAndUnitData.provincePresenceById,
    provincePoliticalOwnerByPrefixedProvinceId:
        provinceMeta.provincePoliticalOwnerByPrefixedProvinceId,
    seaZoneDisplayNameByPrefixedId: game.worldState.seaZoneDisplayNameById,
  );
}

({
  Set<String> seaZoneIds,
  List<Province> provinces,
  Map<String, String> ownerByProvinceId,
  Map<String, String> provinceDisplayNameById,
  Map<String, String?> provincePoliticalOwnerByPrefixedProvinceId,
})
_buildProvinceMetadata({
  required Game game,
  required bool isOldWorld,
  required MapTopology topology,
}) {
  final seaZoneIds = {
    for (final n in topology.nodes)
      if (n.type == TopologyNodeType.seaZone) n.id,
  };
  final provinces = isOldWorld
      ? game.worldState.oldWorld.provinces
      : game.worldState.newWorld.provinces;
  final ownerByProvinceId = <String, String>{};
  final provinceDisplayNameById = <String, String>{};
  final provincePoliticalOwnerByPrefixedProvinceId = <String, String?>{};
  for (final p in provinces) {
    provincePoliticalOwnerByPrefixedProvinceId[p.id] = p.ownerId;
    if (p.ownerId != null && p.ownerId!.isNotEmpty) {
      ownerByProvinceId[p.id] = p.ownerId!;
    }
    if (p.displayName != null && p.displayName!.isNotEmpty) {
      provinceDisplayNameById[p.id] = p.displayName!;
    }
  }
  return (
    seaZoneIds: seaZoneIds,
    provinces: provinces,
    ownerByProvinceId: ownerByProvinceId,
    provinceDisplayNameById: provinceDisplayNameById,
    provincePoliticalOwnerByPrefixedProvinceId:
        provincePoliticalOwnerByPrefixedProvinceId,
  );
}

({
  Set<String> greatPowerFactionIds,
  Map<String, (int r, int g, int b)> factionColors,
})
_buildFactionColorData({
  required Game game,
  required Map<String, (int r, int g, int b)>? greatPowerColorOverride,
}) {
  final greatPowerIds = [for (final player in game.players) player.id];
  final minorNationIds = [for (final nation in game.minorNations) nation.id];
  final tribeIds = [for (final tribe in game.tribes) tribe.id];
  return (
    greatPowerFactionIds: greatPowerIds.toSet(),
    factionColors: factionOwnershipColorMap(
      greatPowerIds: greatPowerIds,
      minorNationIds: minorNationIds,
      tribeIds: tribeIds,
      greatPowerColorOverride: greatPowerColorOverride,
    ),
  );
}

Map<TerrainType, Rgb> _buildTerrainColors(TileMapResult tileMap) {
  final terrainColors = <TerrainType, Rgb>{};
  final terrainGrid = tileMap.terrainGrid;
  if (terrainGrid == null) {
    return terrainColors;
  }
  for (final row in terrainGrid) {
    for (final terrain in row) {
      if (terrain != null && !terrainColors.containsKey(terrain)) {
        terrainColors[terrain] = terrainColorRgb[terrain]!;
      }
    }
  }
  return terrainColors;
}

({
  List<CellViewData> cells,
  List<CapitalMarkerView> capitals,
  List<UnitMarkerView> unitMarkers,
  List<CivilianTileMarkerView> civilianTileMarkers,
  Map<String, ProvinceUnitPresenceView> provincePresenceById,
})
_buildCellAndUnitData({
  required Game game,
  required String regionId,
  required TileMapResult tileMap,
  required bool isOldWorld,
  required List<Province> provinces,
  required Set<String> seaZoneIds,
  required Map<String, String> ownerByProvinceId,
  required Map<String, String> provinceDisplayNameById,
  required Map<String, TileVisibility>? visibilityByTile,
  required Map<String, int>? resourceExtractionUnitsByTile,
  required Map<String, int>? resourceExtractionEffectiveUnitsByTile,
  required Map<String, int>? resourceExtractionBlockedUnitsByTile,
}) {
  final cells = _buildCellViewDataList(
    regionId: regionId,
    tileMap: tileMap,
    seaZoneIds: seaZoneIds,
    tileState: game.worldState.tileState,
    ownerByProvinceId: ownerByProvinceId,
    provinceDisplayNameById: provinceDisplayNameById,
    visibilityByTile: visibilityByTile,
    resourceExtractionUnitsByTile: resourceExtractionUnitsByTile,
    resourceExtractionEffectiveUnitsByTile:
        resourceExtractionEffectiveUnitsByTile,
    resourceExtractionBlockedUnitsByTile: resourceExtractionBlockedUnitsByTile,
  );
  final provinceToTile = _buildProvinceToRepresentativeTile(
    tileMap: tileMap,
    regionId: regionId,
    seaZoneIds: seaZoneIds,
  );
  final unitOverlayData = _buildUnitAndCivilianMarkerData(
    game: game,
    regionId: regionId,
    isOldWorld: isOldWorld,
    provinces: provinces,
    cells: cells,
    provinceToTile: provinceToTile,
  );
  return (
    cells: cells,
    capitals: _buildCapitalMarkers(game: game, regionId: regionId),
    unitMarkers: unitOverlayData.unitMarkers,
    civilianTileMarkers: unitOverlayData.civilianTileMarkers,
    provincePresenceById: unitOverlayData.provincePresenceById,
  );
}

({
  List<PortMarkerView> ports,
  List<TownMarkerView> towns,
  List<WarpMarkerView> warpMarkers,
  List<FleetTileMarkerView> fleetTileMarkers,
})
_buildMarkerData({
  required Game game,
  required String regionId,
  required TileMapResult tileMap,
  required MapTopology topology,
  required List<Province> provinces,
  required Set<String> seaZoneIds,
  required List<WarpLink>? warpLinks,
  required Map<String, ProvinceUnitPresenceView> provincePresenceById,
}) {
  final ports = _buildPortMarkers(
    regionId: regionId,
    portsByProvinceSeaboard: game.worldState.portsByProvinceSeaboard,
  );
  final towns = _buildTownMarkers(
    game: game,
    regionId: regionId,
    provinces: provinces,
    ports: ports,
    coastalProvinceIds: _buildCoastalProvinceIds(
      topology: topology,
      seaZoneIds: seaZoneIds,
    ),
    tileMap: tileMap,
    seaZoneIds: seaZoneIds,
  );
  final seaZoneToTile = _buildSeaZoneToRepresentativeTile(
    tileMap: tileMap,
    seaZoneIds: seaZoneIds,
  );
  final warpMarkers = _buildWarpMarkers(
    regionId: regionId,
    seaZoneToTile: seaZoneToTile,
    warpLinks: warpLinks,
  );
  _applyInPortFleetShipCounts(
    fleets: game.worldState.fleets,
    regionId: regionId,
    provincePresenceById: provincePresenceById,
  );
  final fleetTileMarkers = _buildFleetTileMarkersForRegion(
    game: game,
    regionId: regionId,
    provinces: provinces,
    tileMap: tileMap,
    seaZoneIds: seaZoneIds,
  );
  return (
    ports: ports,
    towns: towns,
    warpMarkers: warpMarkers,
    fleetTileMarkers: fleetTileMarkers,
  );
}

List<CellViewData> _buildCellViewDataList({
  required String regionId,
  required TileMapResult tileMap,
  required Set<String> seaZoneIds,
  required TileMapState tileState,
  required Map<String, String> ownerByProvinceId,
  required Map<String, String> provinceDisplayNameById,
  required Map<String, TileVisibility>? visibilityByTile,
  required Map<String, int>? resourceExtractionUnitsByTile,
  required Map<String, int>? resourceExtractionEffectiveUnitsByTile,
  required Map<String, int>? resourceExtractionBlockedUnitsByTile,
}) {
  final cells = <CellViewData>[];
  for (var y = 0; y < tileMap.height; y++) {
    for (var x = 0; x < tileMap.width; x++) {
      final localId = tileMap.cell(x, y);
      final isSea = seaZoneIds.contains(localId);
      final terrain = tileMap.terrainAt(x, y);
      final resource = tileMap.resourceAt(x, y);
      final tileKey = '$regionId|$localId|$x|$y';
      final improvement = isSea ? null : tileState.improvementLevel(tileKey);
      final road = isSea ? null : tileState.roadLevel(tileKey);
      final visibility = visibilityByTile != null
          ? (visibilityByTile[tileKey] ?? TileVisibility.visible)
          : TileVisibility.visible;
      final extractionUnits = isSea
          ? null
          : resourceExtractionUnitsByTile?[tileKey];
      final extractionEffectiveUnits = isSea
          ? null
          : resourceExtractionEffectiveUnitsByTile?[tileKey];
      final extractionBlockedUnits = isSea
          ? null
          : resourceExtractionBlockedUnitsByTile?[tileKey];
      final fullProvinceId = isSea ? null : ProvinceId.full(regionId, localId);
      cells.add(
        CellViewData(
          x: x,
          y: y,
          regionCellId: localId,
          isSea: isSea,
          terrainTypeId: terrain?.name,
          terrainType: terrain,
          resourceId: resource?.name,
          ownerFactionId: fullProvinceId != null
              ? ownerByProvinceId[fullProvinceId]
              : null,
          provinceDisplayName: isSea
              ? null
              : (fullProvinceId != null
                    ? provinceDisplayNameById[fullProvinceId]
                    : null),
          improvementLevel: isSea ? null : improvement,
          roadLevel: isSea ? null : road,
          resourceExtractionUnits: extractionUnits,
          resourceExtractionEffectiveUnits: extractionEffectiveUnits,
          resourceExtractionBlockedUnits: extractionBlockedUnits,
          visibility: visibility,
        ),
      );
    }
  }
  return cells;
}

List<CapitalMarkerView> _buildCapitalMarkers({
  required Game game,
  required String regionId,
}) {
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
  return capitals;
}

Map<String, (int x, int y)> _buildProvinceToRepresentativeTile({
  required TileMapResult tileMap,
  required String regionId,
  required Set<String> seaZoneIds,
}) {
  final provinceToTile = <String, (int x, int y)>{};
  for (var y = 0; y < tileMap.height; y++) {
    for (var x = 0; x < tileMap.width; x++) {
      final localId = tileMap.cell(x, y);
      if (seaZoneIds.contains(localId)) {
        continue;
      }
      final fullProvinceId = ProvinceId.full(regionId, localId);
      provinceToTile.putIfAbsent(fullProvinceId, () => (x, y));
    }
  }
  return provinceToTile;
}

({
  List<UnitMarkerView> unitMarkers,
  List<CivilianTileMarkerView> civilianTileMarkers,
  Map<String, ProvinceUnitPresenceView> provincePresenceById,
})
_buildUnitAndCivilianMarkerData({
  required Game game,
  required String regionId,
  required bool isOldWorld,
  required List<Province> provinces,
  required List<CellViewData> cells,
  required Map<String, (int x, int y)> provinceToTile,
}) {
  final unitMarkers = <UnitMarkerView>[];
  final civilianUnitsByTileKey = <String, List<Unit>>{};
  final playerOwnedCivilianTileMarkers = <CivilianTileMarkerView>[];
  final humanPlayerIds = game.players
      .where((player) => player.isHuman)
      .map((player) => player.id)
      .toSet();
  final provincePresenceById = <String, ProvinceUnitPresenceView>{};
  for (final p in provinces) {
    provincePresenceById[p.id] = const ProvinceUnitPresenceView(
      civilianCount: 0,
      regimentCount: 0,
      shipCount: 0,
      intelVisible: false,
    );
  }

  for (final cell in cells) {
    if (cell.isSea || cell.visibility != TileVisibility.visible) {
      continue;
    }
    final fullProvinceId = ProvinceId.full(regionId, cell.regionCellId);
    final current = provincePresenceById[fullProvinceId];
    if (current == null) {
      continue;
    }
    provincePresenceById[fullProvinceId] = ProvinceUnitPresenceView(
      civilianCount: current.civilianCount,
      regimentCount: current.regimentCount,
      shipCount: current.shipCount,
      intelVisible: true,
    );
  }

  final regionUnits = isOldWorld
      ? game.worldState.oldWorld.units
      : game.worldState.newWorld.units;
  for (final u in regionUnits) {
    final isPlayerOwnedCivilian =
        humanPlayerIds.contains(u.ownerId) && _isCivilianUnitType(u.type);
    if (isPlayerOwnedCivilian) {
      _addCivilianUnitToTileKeyBucket(
        unit: u,
        regionId: regionId,
        civilianUnitsByTileKey: civilianUnitsByTileKey,
      );
    }

    final tile = provinceToTile[u.locationProvinceId];
    if (tile != null) {
      unitMarkers.add(
        UnitMarkerView(x: tile.$1, y: tile.$2, ownerFactionId: u.ownerId),
      );
    }

    final current = provincePresenceById[u.locationProvinceId];
    if (current == null) {
      continue;
    }
    final isRegiment = isMilitaryUnit(u.type);
    provincePresenceById[u.locationProvinceId] = ProvinceUnitPresenceView(
      civilianCount: current.civilianCount + (isRegiment ? 0 : 1),
      regimentCount: current.regimentCount + (isRegiment ? 1 : 0),
      shipCount: current.shipCount,
      intelVisible: current.intelVisible,
    );
  }

  for (final entry in civilianUnitsByTileKey.entries) {
    final tileKey = entry.key;
    final units = entry.value.toList()
      ..sort((a, b) {
        final priorityCompare = _civilianIconPriorityForType(
          a.type,
        ).compareTo(_civilianIconPriorityForType(b.type));
        if (priorityCompare != 0) {
          return priorityCompare;
        }
        return a.id.compareTo(b.id);
      });
    final parts = tileKey.split('|');
    if (parts.length < 4) {
      continue;
    }
    final x = int.tryParse(parts[2]);
    final y = int.tryParse(parts[3]);
    if (x == null || y == null) {
      continue;
    }
    final representativeUnit = units.first;
    final representativeIsAssigned =
        representativeUnit.assignedTileKey == tileKey &&
        representativeUnit.status == UnitStatus.working;
    playerOwnedCivilianTileMarkers.add(
      CivilianTileMarkerView(
        tileKey: tileKey,
        x: x,
        y: y,
        localProvinceId: parts[1],
        unitIds: units.map((unit) => unit.id).toList(),
        unitTypes: {for (final unit in units) unit.id: unit.type},
        representativeUnitType: representativeUnit.type,
        stackCount: units.length,
        representativeIsAssigned: representativeIsAssigned,
      ),
    );
  }
  playerOwnedCivilianTileMarkers.sort((a, b) {
    final yCompare = a.y.compareTo(b.y);
    if (yCompare != 0) {
      return yCompare;
    }
    final xCompare = a.x.compareTo(b.x);
    if (xCompare != 0) {
      return xCompare;
    }
    return a.tileKey.compareTo(b.tileKey);
  });

  return (
    unitMarkers: unitMarkers,
    civilianTileMarkers: playerOwnedCivilianTileMarkers,
    provincePresenceById: provincePresenceById,
  );
}

void _addCivilianUnitToTileKeyBucket({
  required Unit unit,
  required String regionId,
  required Map<String, List<Unit>> civilianUnitsByTileKey,
}) {
  final tileKey = unit.tileKey;
  if (tileKey == null || tileKey.isEmpty) {
    return;
  }
  final parts = tileKey.split('|');
  if (parts.length < 4 || parts[0] != regionId) {
    return;
  }
  civilianUnitsByTileKey.putIfAbsent(tileKey, () => []).add(unit);
}

List<PortMarkerView> _buildPortMarkers({
  required String regionId,
  required Map<String, String> portsByProvinceSeaboard,
}) {
  final ports = <PortMarkerView>[];
  portsByProvinceSeaboard.forEach((key, tileKey) {
    final parts = tileKey.split('|');
    if (parts.length < 4 || parts[0] != regionId) {
      return;
    }
    final fromKey = localProvinceIdFromPortsSeaboardKey(key, regionId);
    final provinceIdForMarker = fromKey ?? parts[1];
    final x = int.tryParse(parts[2]);
    final y = int.tryParse(parts[3]);
    if (x == null || y == null) {
      return;
    }
    ports.add(
      PortMarkerView(
        x: x,
        y: y,
        provinceId: provinceIdForMarker,
        seaZoneId: '',
        seaboardKey: key,
      ),
    );
  });
  return ports;
}

Set<String> _buildCoastalProvinceIds({
  required MapTopology topology,
  required Set<String> seaZoneIds,
}) {
  final coastalProvinceIds = <String>{};
  for (final edge in topology.edges) {
    final id1Sea = seaZoneIds.contains(edge.id1);
    final id2Sea = seaZoneIds.contains(edge.id2);
    if ((id1Sea && !id2Sea) || (!id1Sea && id2Sea)) {
      coastalProvinceIds.add(id1Sea ? edge.id2 : edge.id1);
    }
  }
  return coastalProvinceIds;
}

List<TownMarkerView> _buildTownMarkers({
  required Game game,
  required String regionId,
  required List<Province> provinces,
  required List<PortMarkerView> ports,
  required Set<String> coastalProvinceIds,
  required TileMapResult tileMap,
  required Set<String> seaZoneIds,
}) {
  final towns = <TownMarkerView>[];
  final portProvinceIds = ports.map((p) => p.provinceId).toSet();
  for (final p in provinces) {
    final townTileKey = p.townTileKey;
    if (townTileKey == null || townTileKey.isEmpty) {
      continue;
    }
    final parts = townTileKey.split('|');
    if (parts.length < 4 || parts[0] != regionId) {
      continue;
    }
    final x = int.tryParse(parts[2]);
    final y = int.tryParse(parts[3]);
    if (x == null || y == null) {
      continue;
    }
    final localProvinceId = ProvinceId.localIdFrom(p.id);
    final hasPort = portProvinceIds.contains(localProvinceId);
    final portTileKey = hasPort
        ? portLandTileKeyForProvinceInRegion(game, regionId, localProvinceId)
        : null;
    int? portIconX;
    int? portIconY;
    if (hasPort && portTileKey != null) {
      final placed = computePortDrawableSeaCellForMap(
        tileMap: tileMap,
        seaZoneIds: seaZoneIds,
        portTileKey: portTileKey,
        contextLabel:
            'region=$regionId province=$localProvinceId harbor sprite',
      );
      portIconX = placed.x;
      portIconY = placed.y;
    }
    final touchesSea = coastalProvinceIds.contains(localProvinceId);
    towns.add(
      TownMarkerView(
        x: x,
        y: y,
        provinceId: localProvinceId,
        isCoastal: touchesSea && !hasPort,
        isPort: hasPort,
        touchesSea: touchesSea,
        portIconX: portIconX,
        portIconY: portIconY,
      ),
    );
  }
  return towns;
}

Map<String, (int x, int y)> _buildSeaZoneToRepresentativeTile({
  required TileMapResult tileMap,
  required Set<String> seaZoneIds,
}) {
  final seaZoneToTile = <String, (int x, int y)>{};
  for (var y = 0; y < tileMap.height; y++) {
    for (var x = 0; x < tileMap.width; x++) {
      final localId = tileMap.cell(x, y);
      if (!seaZoneIds.contains(localId)) {
        continue;
      }
      seaZoneToTile.putIfAbsent(localId, () => (x, y));
    }
  }
  return seaZoneToTile;
}

List<WarpMarkerView> _buildWarpMarkers({
  required String regionId,
  required Map<String, (int x, int y)> seaZoneToTile,
  required List<WarpLink>? warpLinks,
}) {
  final warpMarkers = <WarpMarkerView>[];
  if (warpLinks == null) {
    return warpMarkers;
  }
  for (final link in warpLinks) {
    if (link.regionId == regionId) {
      final tile = seaZoneToTile[link.seaZoneId];
      if (tile == null) {
        continue;
      }
      warpMarkers.add(
        WarpMarkerView(
          x: tile.$1,
          y: tile.$2,
          seaZoneId: link.seaZoneId,
          otherRegionId: link.otherRegionId,
          otherSeaZoneId: link.otherSeaZoneId,
        ),
      );
      continue;
    }
    if (link.otherRegionId != regionId) {
      continue;
    }
    final tile = seaZoneToTile[link.otherSeaZoneId];
    if (tile == null) {
      continue;
    }
    warpMarkers.add(
      WarpMarkerView(
        x: tile.$1,
        y: tile.$2,
        seaZoneId: link.otherSeaZoneId,
        otherRegionId: link.regionId,
        otherSeaZoneId: link.seaZoneId,
      ),
    );
  }
  return warpMarkers;
}

void _applyInPortFleetShipCounts({
  required List<Fleet> fleets,
  required String regionId,
  required Map<String, ProvinceUnitPresenceView> provincePresenceById,
}) {
  for (final fleet in fleets) {
    if (fleet.regionId != regionId || !fleet.isInPort) {
      continue;
    }
    final provinceId = fleet.inPortAtProvinceId;
    if (provinceId == null) {
      continue;
    }
    final current = provincePresenceById[provinceId];
    if (current == null) {
      continue;
    }
    provincePresenceById[provinceId] = ProvinceUnitPresenceView(
      civilianCount: current.civilianCount,
      regimentCount: current.regimentCount,
      shipCount: current.shipCount + fleet.ships.length,
      intelVisible: current.intelVisible,
    );
  }
}
