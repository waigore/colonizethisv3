/// Cell and unit overlay orchestration for map view assembly.
/// SPEC/program/map-visualization.md § Map view model for tools.
library;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'init_game_map_view_cells.dart';
import 'init_game_map_view_data.dart';
import 'init_game_map_view_markers.dart';

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
