part of 'region_map_province_overlay_geometry.dart';

ProvinceTopologyEdgeKind _topologyKind(CellViewData a, CellViewData b) {
  if (a.isSea && b.isSea) return ProvinceTopologyEdgeKind.seaSea;
  if (!a.isSea && !b.isSea) return ProvinceTopologyEdgeKind.landLand;
  return ProvinceTopologyEdgeKind.landSea;
}

void _addVerticalTopologySegmentIfNeeded({
  required RegionMapViewData region,
  required int x,
  required int y,
  required double cellSizePx,
  required double coastInsetPx,
  required bool gateByUnrevealedTiles,
  required List<ProvinceTopologySegment> out,
}) {
  final cell = region.cellAt(x, y);
  if (x + 1 >= region.width) return;
  final right = region.cellAt(x + 1, y);
  if (cell.regionCellId == right.regionCellId) return;
  if (!regionMapDrawBoundaryBetweenAdjacentCells(
    gateByUnrevealedTiles: gateByUnrevealedTiles,
    visibilityA: cell.visibility,
    visibilityB: right.visibility,
  )) {
    return;
  }
  final xLine = verticalProvinceTopologyEdgeX(
    left: cell,
    right: right,
    cellSizePx: cellSizePx,
    leftTileX: x,
    coastInsetPx: coastInsetPx,
  );
  out.add(
    ProvinceTopologySegment(
      start: Offset(xLine, y * cellSizePx),
      end: Offset(xLine, (y + 1) * cellSizePx),
      kind: _topologyKind(cell, right),
    ),
  );
}

void _addHorizontalTopologySegmentIfNeeded({
  required RegionMapViewData region,
  required int x,
  required int y,
  required double cellSizePx,
  required double coastInsetPx,
  required bool gateByUnrevealedTiles,
  required List<ProvinceTopologySegment> out,
}) {
  final cell = region.cellAt(x, y);
  if (y + 1 >= region.height) return;
  final bottom = region.cellAt(x, y + 1);
  if (cell.regionCellId == bottom.regionCellId) return;
  if (!regionMapDrawBoundaryBetweenAdjacentCells(
    gateByUnrevealedTiles: gateByUnrevealedTiles,
    visibilityA: cell.visibility,
    visibilityB: bottom.visibility,
  )) {
    return;
  }
  final yLine = horizontalProvinceTopologyEdgeY(
    top: cell,
    bottom: bottom,
    cellSizePx: cellSizePx,
    topTileY: y,
    coastInsetPx: coastInsetPx,
  );
  out.add(
    ProvinceTopologySegment(
      start: Offset(x * cellSizePx, yLine),
      end: Offset((x + 1) * cellSizePx, yLine),
      kind: _topologyKind(cell, bottom),
    ),
  );
}

/// All province/sea topology segments for tests and optional tooling.
/// Honors the same visibility gate as the map painter.
List<ProvinceTopologySegment> computeProvinceTopologySegments({
  required RegionMapViewData region,
  required double cellSizePx,
  required bool gateByUnrevealedTiles,
}) {
  final inset = provinceOverlayLandSeaInsetPx(
    cellSizePx: cellSizePx,
    topologyStrokeWidth: kProvinceOverlayTopologyStrokeWidth,
  );
  final out = <ProvinceTopologySegment>[];

  for (var y = 0; y < region.height; y++) {
    for (var x = 0; x < region.width; x++) {
      _addVerticalTopologySegmentIfNeeded(
        region: region,
        x: x,
        y: y,
        cellSizePx: cellSizePx,
        coastInsetPx: inset,
        gateByUnrevealedTiles: gateByUnrevealedTiles,
        out: out,
      );
      _addHorizontalTopologySegmentIfNeeded(
        region: region,
        x: x,
        y: y,
        cellSizePx: cellSizePx,
        coastInsetPx: inset,
        gateByUnrevealedTiles: gateByUnrevealedTiles,
        out: out,
      );
    }
  }
  return out;
}
