/// Cell-grid and unit/civilian marker builders for
/// [init_game_map_view_builder.dart].
/// SPEC/program/map-visualization.md § Map view model for tools.
library;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'init_game_map_view_cell_grid.dart';
import 'init_game_map_view_cell_unit_markers.dart';
import 'init_game_map_view_data.dart';

/// Stateless builders for the per-cell view data and the unit/civilian marker
/// overlays of a single region.
///
/// Extracted from the former `init_game_map_view_builder_cells_markers_part`
/// `part` fragment so each concern is an independently importable, testable
/// unit (see #3588).
class InitGameMapViewCells {
  const InitGameMapViewCells._();

  static List<CellViewData> buildCellViewDataList({
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
    Set<String>? capitalLinkDisconnectedTileKeys,
    String? viewingFactionId,
    Map<String, bool>? viewingTechUnlocked,
  }) =>
      InitGameMapViewCellGrid.buildCellViewDataList(
        regionId: regionId,
        tileMap: tileMap,
        seaZoneIds: seaZoneIds,
        tileState: tileState,
        ownerByProvinceId: ownerByProvinceId,
        provinceDisplayNameById: provinceDisplayNameById,
        visibilityByTile: visibilityByTile,
        resourceExtractionUnitsByTile: resourceExtractionUnitsByTile,
        resourceExtractionEffectiveUnitsByTile:
            resourceExtractionEffectiveUnitsByTile,
        resourceExtractionBlockedUnitsByTile:
            resourceExtractionBlockedUnitsByTile,
        capitalLinkDisconnectedTileKeys: capitalLinkDisconnectedTileKeys,
        viewingFactionId: viewingFactionId,
        viewingTechUnlocked: viewingTechUnlocked,
      );

  static Map<String, (int x, int y)> buildProvinceToRepresentativeTile({
    required TileMapResult tileMap,
    required String regionId,
    required Set<String> seaZoneIds,
  }) =>
      InitGameMapViewCellGrid.buildProvinceToRepresentativeTile(
        tileMap: tileMap,
        regionId: regionId,
        seaZoneIds: seaZoneIds,
      );

  static ({
    List<UnitMarkerView> unitMarkers,
    List<CivilianTileMarkerView> civilianTileMarkers,
    Map<String, ProvinceUnitPresenceView> provincePresenceById,
  })
  buildUnitAndCivilianMarkerData({
    required Game game,
    required String regionId,
    required List<Province> provinces,
    required List<CellViewData> cells,
    required Map<String, (int x, int y)> provinceToTile,
    Set<String>? civilianMarkerOwnerIds,
  }) =>
      InitGameMapViewCellUnitMarkers.buildUnitAndCivilianMarkerData(
        game: game,
        regionId: regionId,
        provinces: provinces,
        cells: cells,
        provinceToTile: provinceToTile,
        civilianMarkerOwnerIds: civilianMarkerOwnerIds,
      );
}
