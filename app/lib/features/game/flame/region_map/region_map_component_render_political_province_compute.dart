import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:flutter/material.dart';

import 'region_map_component.dart';
import 'region_map_component_render_political_sea_labels.dart';
import 'region_map_component_shared_palette.dart';
import 'region_map_component_support.dart';

extension CtRegionMapRenderPoliticalLabelsProvinceCompute
    on CtRegionMapComponent {
  void ensureProvinceLabelCache() {
    if (identical(session.provinceLabelsRegionRef, region) &&
        session.provinceLabelsCellSize == cellSize &&
        session.provinceLabelsVisibilityMode == visibilityMode &&
        session.provinceLabelsCached != null) {
      return;
    }
    session.provinceLabelsRegionRef = region;
    session.provinceLabelsCellSize = cellSize;
    session.provinceLabelsVisibilityMode = visibilityMode;
    session.provinceLabelsCached = computeProvinceLabels();
  }

  Color _provinceNamePlateColor({
    required String prefixedProvinceId,
    required List<CellViewData> qualifyingLandCells,
  }) {
    final rgb = resolveProvinceLabelPlateTintRgb(
      prefixedProvinceId: prefixedProvinceId,
      qualifyingLandCells: qualifyingLandCells,
      region: region,
      honorUnrevealedTiles:
          visibilityMode == CtMapVisibilityMode.playerConstrained,
    );
    if (rgb == null) {
      return RegionMapPalette.provinceLabelPlateColor;
    }
    return Color.fromRGBO(rgb.$1, rgb.$2, rgb.$3, kProvinceLabelPlateTintAlpha);
  }

  List<
    ({
      double cx,
      double cy,
      String text,
      String provinceId,
      Color plateColor,
      bool isCapital,
      int? avoidTileX,
      int? avoidTileY,
    })
  >
  computeProvinceLabels() {
    final byLocalId = <String, List<CellViewData>>{};
    for (final cell in region.cells) {
      if (cell.isSea) continue;
      if (visibilityMode == CtMapVisibilityMode.playerConstrained &&
          regionMapComponentVisibilityForTerrain(this, cell) ==
              TileVisibility.unrevealed) {
        continue;
      }
      byLocalId.putIfAbsent(cell.regionCellId, () => []).add(cell);
    }
    final out =
        <
          ({
            double cx,
            double cy,
            String text,
            String provinceId,
            Color plateColor,
            bool isCapital,
            int? avoidTileX,
            int? avoidTileY,
          })
        >[];
    final townMarkerByProvinceId = <String, TownMarkerView>{};
    for (final marker in region.townMarkers) {
      townMarkerByProvinceId.putIfAbsent(marker.provinceId, () => marker);
    }
    final capitalProvinceIds = <String>{};
    for (final cap in region.capitalMarkers) {
      if (cap.x < 0 ||
          cap.x >= region.width ||
          cap.y < 0 ||
          cap.y >= region.height) {
        continue;
      }
      final capCell = region.cellAt(cap.x, cap.y);
      if (capCell.isSea) {
        continue;
      }
      capitalProvinceIds.add('${region.regionId}|${capCell.regionCellId}');
    }
    for (final e in byLocalId.entries) {
      final cells = e.value;
      if (cells.isEmpty) continue;
      var sx = 0.0;
      var sy = 0.0;
      for (final c in cells) {
        sx += (c.x + 0.5) * cellSize;
        sy += (c.y + 0.5) * cellSize;
      }
      final n = cells.length;
      final cx = sx / n;
      final cy = sy / n;
      var tileSx = 0;
      var tileSy = 0;
      for (final c in cells) {
        tileSx += c.x;
        tileSy += c.y;
      }
      final centroidTileX = (tileSx / n).round();
      final centroidTileY = (tileSy / n).round();
      String? name;
      for (final c in cells) {
        final dn = c.provinceDisplayName;
        if (dn != null && dn.isNotEmpty) {
          name = dn;
          break;
        }
      }
      final text = name ?? e.key;
      final prefixedId = '${region.regionId}|${e.key}';
      final townMarker = townMarkerByProvinceId[e.key];
      final shouldAvoidTownTile =
          townMarker != null &&
          townMarker.x == centroidTileX &&
          townMarker.y == centroidTileY;
      final avoidTown = shouldAvoidTownTile ? townMarker : null;
      out.add((
        cx: cx,
        cy: cy,
        text: text,
        provinceId: prefixedId,
        plateColor: _provinceNamePlateColor(
          prefixedProvinceId: prefixedId,
          qualifyingLandCells: cells,
        ),
        isCapital: capitalProvinceIds.contains(prefixedId),
        avoidTileX: avoidTown?.x,
        avoidTileY: avoidTown?.y,
      ));
    }
    return out;
  }
}
