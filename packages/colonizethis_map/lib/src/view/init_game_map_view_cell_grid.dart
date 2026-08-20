/// Per-cell grid view data builders for [init_game_map_view_builder.dart].
/// SPEC/program/map-visualization.md § Map view model for tools.
library;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../tile_map_grid.dart';
import 'init_game_map_view_data.dart';
import 'init_game_map_view_improvement_cap.dart';

class InitGameMapViewCellGrid {
  const InitGameMapViewCellGrid._();

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
  }) {
    final cells = <CellViewData>[];
    TileMapGrid.forEachIndex(tileMap.height, tileMap.width, (y, x) {
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
      final capitalLinkDisconnected =
          !isSea &&
          (capitalLinkDisconnectedTileKeys?.contains(tileKey) ?? false);
      final fullProvinceId = isSea ? null : ProvinceId.full(regionId, localId);
      final ownerFactionId = fullProvinceId != null
          ? ownerByProvinceId[fullProvinceId]
          : null;
      cells.add(
        CellViewData(
          x: x,
          y: y,
          regionCellId: localId,
          isSea: isSea,
          terrainTypeId: terrain?.name,
          terrainType: terrain,
          resourceId: resource?.name,
          ownerFactionId: ownerFactionId,
          provinceDisplayName: isSea
              ? null
              : (fullProvinceId != null
                    ? provinceDisplayNameById[fullProvinceId]
                    : null),
          improvementLevel: isSea ? null : improvement,
          improvementTechCap: improvementTechCapForCell(
            isSea: isSea,
            ownerFactionId: ownerFactionId,
            viewingFactionId: viewingFactionId,
            techUnlocked: viewingTechUnlocked,
            resourceId: resource?.name,
            terrainType: terrain,
          ),
          roadLevel: isSea ? null : road,
          resourceExtractionUnits: extractionUnits,
          resourceExtractionEffectiveUnits: extractionEffectiveUnits,
          resourceExtractionBlockedUnits: extractionBlockedUnits,
          capitalLinkDisconnected: capitalLinkDisconnected,
          visibility: visibility,
        ),
      );
    });
    return cells;
  }

  static Map<String, (int x, int y)> buildProvinceToRepresentativeTile({
    required TileMapResult tileMap,
    required String regionId,
    required Set<String> seaZoneIds,
  }) {
    final provinceToTile = <String, (int x, int y)>{};
    TileMapGrid.forEachIndex(tileMap.height, tileMap.width, (y, x) {
      final localId = tileMap.cell(x, y);
      if (seaZoneIds.contains(localId)) {
        return;
      }
      final fullProvinceId = ProvinceId.full(regionId, localId);
      provinceToTile.putIfAbsent(fullProvinceId, () => (x, y));
    });
    return provinceToTile;
  }
}
