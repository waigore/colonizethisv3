import 'dart:ui';

import 'package:colonizethis_map/colonizethis_map.dart';

import 'region_map_boundary_visibility.dart';

/// Province/sea topology overlay stroke width (world px). Legacy was 1.0; 2× per SPEC/ui/map-widget.md.
const double kProvinceOverlayTopologyStrokeWidth = 2.0;

/// Political border stroke when province overlay is on. Legacy was 2.0; 2× per SPEC/ui/map-widget.md.
const double kProvinceOverlayPoliticalStrokeWidth = 4.0;

/// Hover glow for province/sea zone. Legacy was 3.0; 2×.
const double kProvinceOverlayHoverGlowStrokeWidth = 6.0;

/// Hover selector (tile cursor). Legacy was 2.0; 2×.
const double kMapHoverSelectorStrokeWidth = 4.0;

/// Primary selection tile outline. Legacy was 3.0; 2×.
const double kMapSelectedTileStrokeWidth = 6.0;

/// Secondary highlight outline. Legacy was 2.5; 2×.
const double kMapSecondaryHighlightStrokeWidth = 5.0;

/// Work-target valid-tile flashing outline. Legacy was 2.5; 2×.
const double kMapValidTileTargetStrokeWidth = 5.0;

/// Warp zone outer glow. Legacy was 3.0; 2×.
const double kWarpZoneGlowOuterStrokeWidth = 6.0;

/// Warp zone inner stroke. Legacy was 1.5; 2×.
const double kWarpZoneGlowInnerStrokeWidth = 3.0;

/// Capital marker ring. Legacy was 1.0; 2×.
const double kCapitalMarkerRingStrokeWidth = 2.0;

/// Kind of topology edge for coloring (matches [RegionMapViewData] painter).
enum ProvinceTopologyEdgeKind { landLand, seaSea, landSea }

/// One drawable segment for province/sea topology overlay (world coordinates).
class ProvinceTopologySegment {
  const ProvinceTopologySegment({
    required this.start,
    required this.end,
    required this.kind,
  });

  final Offset start;
  final Offset end;
  final ProvinceTopologyEdgeKind kind;
}

/// Inset from the nominal grid line toward the **land** cell for land–sea edges.
/// SPEC/ui/map-widget.md § Province overlay (coastal stroke).
double provinceOverlayLandSeaInsetPx({
  required double cellSizePx,
  required double topologyStrokeWidth,
}) {
  final maxInset = cellSizePx * 0.45;
  final base = topologyStrokeWidth * 0.5;
  return base.clamp(1.0, maxInset);
}

/// X coordinate of a vertical edge between [left] (x,) and [right] (x+1,).
double verticalProvinceTopologyEdgeX({
  required CellViewData left,
  required CellViewData right,
  required double cellSizePx,
  required int leftTileX,
  required double coastInsetPx,
}) {
  final baseX = (leftTileX + 1) * cellSizePx;
  if (left.isSea == right.isSea) return baseX;
  if (!left.isSea && right.isSea) return baseX - coastInsetPx;
  return baseX + coastInsetPx;
}

/// Y coordinate of a horizontal edge between [top] (x,y) and [bottom] (x,y+1).
double horizontalProvinceTopologyEdgeY({
  required CellViewData top,
  required CellViewData bottom,
  required double cellSizePx,
  required int topTileY,
  required double coastInsetPx,
}) {
  final baseY = (topTileY + 1) * cellSizePx;
  if (top.isSea == bottom.isSea) return baseY;
  if (!top.isSea && bottom.isSea) return baseY - coastInsetPx;
  return baseY + coastInsetPx;
}

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
