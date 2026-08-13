/// Region assembly helpers for [buildInitGameMapViewData].
/// SPEC/program/map-visualization.md § Map view model for tools.
library;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../province_ownership_view.dart';
import '../region_data_access.dart';
import '../tile_map_colors.dart';
import '../tile_map_topology_helpers.dart';
import 'init_game_map_view_cells.dart';
import 'init_game_map_view_data.dart';
import 'init_game_map_view_markers.dart';

RegionMapViewData buildRegionViewData({
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
  Set<String>? capitalLinkDisconnectedTileKeys,
  Set<String>? civilianMarkerOwnerIds,
}) {
  final provinceMeta = buildProvinceMetadata(
    game: game,
    regionId: regionId,
    topology: topology,
  );
  final factionData = initGameFactionColorData(
    game,
    greatPowerColorOverride: greatPowerColorOverride,
  );
  final cellAndUnitData = buildCellAndUnitData(
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
    capitalLinkDisconnectedTileKeys: capitalLinkDisconnectedTileKeys,
    civilianMarkerOwnerIds: civilianMarkerOwnerIds,
  );
  final markerData = buildMarkerData(
    game: game,
    regionId: regionId,
    tileMap: tileMap,
    topology: topology,
    provinces: provinceMeta.provinces,
    seaZoneIds: provinceMeta.seaZoneIds,
    warpLinks: warpLinks,
    provincePresenceById: cellAndUnitData.provincePresenceById,
  );
  return buildRegionMapViewDataFromParts(
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

RegionMapViewData buildRegionMapViewDataFromParts({
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
    terrainColors: buildTerrainColors(tileMap),
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
buildProvinceMetadata({
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

Map<TerrainType, Rgb> buildTerrainColors(TileMapResult tileMap) {
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
buildCellAndUnitData({
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
  Set<String>? capitalLinkDisconnectedTileKeys,
  Set<String>? civilianMarkerOwnerIds,
}) {
  final cells = InitGameMapViewCells.buildCellViewDataList(
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
    capitalLinkDisconnectedTileKeys: capitalLinkDisconnectedTileKeys,
  );
  final provinceToTile = InitGameMapViewCells.buildProvinceToRepresentativeTile(
    tileMap: tileMap,
    regionId: regionId,
    seaZoneIds: seaZoneIds,
  );
  final unitOverlayData = InitGameMapViewCells.buildUnitAndCivilianMarkerData(
    game: game,
    regionId: regionId,
    provinces: provinces,
    cells: cells,
    provinceToTile: provinceToTile,
    civilianMarkerOwnerIds: civilianMarkerOwnerIds,
  );
  return (
    cells: cells,
    capitals: InitGameMapViewMarkers.buildCapitalMarkers(
      game: game,
      regionId: regionId,
    ),
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
buildMarkerData({
  required Game game,
  required String regionId,
  required TileMapResult tileMap,
  required MapTopology topology,
  required List<Province> provinces,
  required Set<String> seaZoneIds,
  required List<WarpLink>? warpLinks,
  required Map<String, ProvinceUnitPresenceView> provincePresenceById,
}) {
  final ports = InitGameMapViewMarkers.buildPortMarkers(
    regionId: regionId,
    portsByProvinceSeaboard: game.worldState.portsByProvinceSeaboard,
  );
  final towns = InitGameMapViewMarkers.buildTownMarkers(
    game: game,
    regionId: regionId,
    provinces: provinces,
    ports: ports,
    coastalProvinceIds: InitGameMapViewMarkers.buildCoastalProvinceIds(
      topology: topology,
      seaZoneIds: seaZoneIds,
    ),
    tileMap: tileMap,
    seaZoneIds: seaZoneIds,
  );
  final seaZoneToTile = InitGameMapViewMarkers.buildSeaZoneToRepresentativeTile(
    tileMap: tileMap,
    seaZoneIds: seaZoneIds,
  );
  final warpMarkers = InitGameMapViewMarkers.buildWarpMarkers(
    regionId: regionId,
    seaZoneToTile: seaZoneToTile,
    warpLinks: warpLinks,
  );
  InitGameMapViewMarkers.applyInPortFleetShipCounts(
    fleets: game.worldState.fleets,
    regionId: regionId,
    provincePresenceById: provincePresenceById,
  );
  final fleetTileMarkers =
      InitGameMapViewMarkers.buildFleetTileMarkersForRegion(
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
