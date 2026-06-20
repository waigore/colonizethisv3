part of 'init_game_map_view_builder.dart';

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

  /// Optional explicit owner set for civilian tile markers. When null, the
  /// builder falls back to `Player.isHuman` players (legacy single-player
  /// behavior). When provided, only civilians owned by ids in this set get
  /// markers; pass all faction ids in global observe and the observed GP id in
  /// player observe per SPEC/ui/observe-mode.md.
  Set<String>? civilianMarkerOwnerIds,
}) {
  _log.i('buildInitGameMapViewData start gameId=${game.id}');
  final viewByRegion = <String, RegionMapViewData>{};
  for (final regionId in const [kRegionOldWorld, kRegionNewWorld]) {
    viewByRegion[regionId] = _buildRegionViewData(
      regionId: regionId,
      tileMap: tileMapByRegion[regionId]!,
      topology: topologyByRegion[regionId]!,
      game: game,
      cellSize: cellSize,
      greatPowerColorOverride: greatPowerColorOverride,
      visibilityByTile: visibilityByTile,
      warpLinks: warpLinks,
      resourceExtractionUnitsByTile: resourceExtractionUnitsByTile,
      resourceExtractionEffectiveUnitsByTile:
          resourceExtractionEffectiveUnitsByTile,
      resourceExtractionBlockedUnitsByTile:
          resourceExtractionBlockedUnitsByTile,
      civilianMarkerOwnerIds: civilianMarkerOwnerIds,
    );
  }

  _log.i('buildInitGameMapViewData end');
  final combinedTopology = combineRegionTopologies(
    topologyByRegion: topologyByRegion,
    warpLinks: warpLinks ?? const [],
  );
  return InitGameMapViewData(
    oldWorld: viewByRegion[kRegionOldWorld]!,
    newWorld: viewByRegion[kRegionNewWorld]!,
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
  Map<String, (int r, int g, int b)>? greatPowerColorOverride,
  Map<String, TileVisibility>? visibilityByTile,
  List<WarpLink>? warpLinks,
  Map<String, int>? resourceExtractionUnitsByTile,
  Map<String, int>? resourceExtractionEffectiveUnitsByTile,
  Map<String, int>? resourceExtractionBlockedUnitsByTile,
  Set<String>? civilianMarkerOwnerIds,
}) {
  final provinceMeta = _buildProvinceMetadata(
    game: game,
    regionId: regionId,
    topology: topology,
  );
  final factionData = initGameFactionColorData(
    game,
    greatPowerColorOverride: greatPowerColorOverride,
  );
  final cellAndUnitData = _buildCellAndUnitData(
    game: game,
    regionId: regionId,
    tileMap: tileMap,
    provinces: provinceMeta.provinces,
    seaZoneIds: provinceMeta.seaZoneIds,
    ownerByProvinceId: provinceMeta.ownerByProvinceId,
    provinceDisplayNameById: provinceMeta.provinceDisplayNameById,
    visibilityByTile: visibilityByTile,
    resourceExtractionUnitsByTile: resourceExtractionUnitsByTile,
    resourceExtractionEffectiveUnitsByTile:
        resourceExtractionEffectiveUnitsByTile,
    resourceExtractionBlockedUnitsByTile: resourceExtractionBlockedUnitsByTile,
    civilianMarkerOwnerIds: civilianMarkerOwnerIds,
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
  required String regionId,
  required MapTopology topology,
}) {
  final seaZoneIds = seaZoneIdsFromTopology(topology);
  final provinces = regionDataForMapRegionId(
    game.worldState,
    regionId,
  ).provinces;
  final ownerByProvinceId = provinceOwnerByIdFromProvinces(provinces);
  final provinceDisplayNameById = <String, String>{};
  final provincePoliticalOwnerByPrefixedProvinceId = <String, String?>{};
  for (final p in provinces) {
    provincePoliticalOwnerByPrefixedProvinceId[p.id] = p.ownerId;
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
  required List<Province> provinces,
  required Set<String> seaZoneIds,
  required Map<String, String> ownerByProvinceId,
  required Map<String, String> provinceDisplayNameById,
  required Map<String, TileVisibility>? visibilityByTile,
  required Map<String, int>? resourceExtractionUnitsByTile,
  required Map<String, int>? resourceExtractionEffectiveUnitsByTile,
  required Map<String, int>? resourceExtractionBlockedUnitsByTile,
  Set<String>? civilianMarkerOwnerIds,
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
    provinces: provinces,
    cells: cells,
    provinceToTile: provinceToTile,
    civilianMarkerOwnerIds: civilianMarkerOwnerIds,
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
