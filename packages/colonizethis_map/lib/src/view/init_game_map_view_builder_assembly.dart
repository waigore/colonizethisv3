/// Region compose helpers for [buildInitGameMapViewData].
/// SPEC/program/map-visualization.md § Map view model for tools.
library;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../tile_map_colors.dart';
import 'init_game_map_view_builder_cell_units.dart';
import 'init_game_map_view_builder_marker_orchestration.dart';
import 'init_game_map_view_builder_province_meta.dart';
import 'init_game_map_view_data.dart';

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
