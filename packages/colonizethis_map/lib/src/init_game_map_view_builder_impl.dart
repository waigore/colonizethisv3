part of 'init_game_map_view_builder.dart';

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

