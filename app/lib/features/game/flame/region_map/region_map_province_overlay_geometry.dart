import 'dart:ui';

import 'package:colonizethis_map/colonizethis_map.dart';

import 'region_map_boundary_visibility.dart';

part 'region_map_province_overlay_geometry_segments.dart';

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
