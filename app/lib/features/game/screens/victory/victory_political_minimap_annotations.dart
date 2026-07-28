import 'package:colonizethis_map/colonizethis_map.dart';

/// Province label anchor for the Victory political minimap painter.
typedef VictoryMinimapProvinceLabel = ({
  String localProvinceId,
  String text,
  double cx,
  double cy,
  int cellCount,
});

/// Computes province display-name labels at tile-centroid positions.
///
/// Mirrors main-map political label placement
/// (`region_map_component_render_political.dart` `_computeProvinceLabels`)
/// without icon plates or visibility gating.
List<VictoryMinimapProvinceLabel> computeVictoryMinimapProvinceLabels(
  RegionMapViewData region,
) {
  final byLocalId = <String, List<CellViewData>>{};
  for (final cell in region.cells) {
    if (cell.isSea) continue;
    byLocalId.putIfAbsent(cell.regionCellId, () => []).add(cell);
  }

  final townMarkerByProvinceId = <String, TownMarkerView>{};
  for (final marker in region.townMarkers) {
    townMarkerByProvinceId.putIfAbsent(marker.provinceId, () => marker);
  }

  final labels = <VictoryMinimapProvinceLabel>[];
  for (final entry in byLocalId.entries) {
    final cells = entry.value;
    if (cells.isEmpty) continue;

    var tileSx = 0;
    var tileSy = 0;
    String? name;
    for (final cell in cells) {
      tileSx += cell.x;
      tileSy += cell.y;
      final dn = cell.provinceDisplayName;
      if (dn != null && dn.isNotEmpty) {
        name = dn;
      }
    }
    final n = cells.length;
    final centroidTileX = (tileSx / n).round();
    final centroidTileY = (tileSy / n).round();
    final townMarker = townMarkerByProvinceId[entry.key];
    final shouldAvoidTownTile =
        townMarker != null &&
        townMarker.x == centroidTileX &&
        townMarker.y == centroidTileY;

    var sx = 0.0;
    var sy = 0.0;
    for (final cell in cells) {
      sx += cell.x + 0.5;
      sy += cell.y + 0.5;
    }
    var pixelCx = sx / n;
    var pixelCy = sy / n;
    if (shouldAvoidTownTile) {
      // Nudge label slightly north-west when it would overlap the town tile.
      pixelCx -= 0.15;
      pixelCy -= 0.15;
    }

    labels.add((
      localProvinceId: entry.key,
      text: name ?? entry.key,
      cx: pixelCx,
      cy: pixelCy,
      cellCount: n,
    ));
  }
  return labels;
}

/// Local province ids whose tile footprint contains a faction capital marker.
Set<String> computeVictoryMinimapCapitalProvinceLocalIds(
  RegionMapViewData region,
) {
  final capitalProvinceIds = <String>{};
  for (final cap in region.capitalMarkers) {
    if (cap.x < 0 ||
        cap.x >= region.width ||
        cap.y < 0 ||
        cap.y >= region.height) {
      continue;
    }
    final capCell = region.cellAt(cap.x, cap.y);
    if (capCell.isSea) continue;
    capitalProvinceIds.add(capCell.regionCellId);
  }
  return capitalProvinceIds;
}
