// Region map helpers for ProvinceSeaZoneDetailOverlay core pins (Refs #4305).

import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_app_fixtures/demo/province_overlay_demo_data.dart'
    show demoGameForOverlay, sampleSeaZoneIdForOverlay;

CellViewData copyProvinceOverlayCell(
  CellViewData c, {
  TileVisibility? visibility,
}) {
  return CellViewData(
    x: c.x,
    y: c.y,
    regionCellId: c.regionCellId,
    isSea: c.isSea,
    terrainTypeId: c.terrainTypeId,
    terrainType: c.terrainType,
    resourceId: c.resourceId,
    ownerFactionId: c.ownerFactionId,
    provinceDisplayName: c.provinceDisplayName,
    improvementLevel: c.improvementLevel,
    roadLevel: c.roadLevel,
    visibility: visibility ?? c.visibility,
  );
}

RegionMapViewData regionWithCells(
  RegionMapViewData base,
  List<CellViewData> cells,
) {
  return RegionMapViewData(
    regionId: base.regionId,
    width: base.width,
    height: base.height,
    cellSize: base.cellSize,
    cells: cells,
    capitalMarkers: base.capitalMarkers,
    portMarkers: base.portMarkers,
    factionColors: base.factionColors,
    greatPowerFactionIds: base.greatPowerFactionIds,
    terrainColors: base.terrainColors,
    unitMarkers: base.unitMarkers,
  );
}

RegionMapViewData regionWithVisibility(
  RegionMapViewData base,
  TileVisibility Function(CellViewData c) visibilityFor,
) {
  return regionWithCells(
    base,
    base.cells
        .map((c) => copyProvinceOverlayCell(c, visibility: visibilityFor(c)))
        .toList(),
  );
}

Game namedSeaZoneOverlayGame({String name = 'Named Test Sea'}) {
  final game = demoGameForOverlay;
  return game.copyWith(
    worldState: game.worldState.copyWith(
      seaZoneDisplayNameById: {sampleSeaZoneIdForOverlay: name},
    ),
  );
}
