
part of 'region_map_component.dart';

extension _CtRegionMapRenderPoliticalBordersProvince on CtRegionMapComponent {
  void _paintHoveredProvinceGlow(Canvas canvas) {
    final t = session.hoverAnimationT;
    final opacity =
        RegionMapPalette.hoveredProvinceGlowOpacityMid +
        RegionMapPalette.hoveredProvinceGlowOpacityAmplitude *
            math.sin(t * RegionMapPalette.hoveredProvinceGlowAngularFrequency);
    final coastInset = provinceOverlayLandSeaInsetPx(
      cellSizePx: cellSize,
      topologyStrokeWidth: kProvinceOverlayTopologyStrokeWidth,
    );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = kProvinceOverlayHoverGlowStrokeWidth
      ..color = RegionMapPalette.mapHoverSelectorIdle.withValues(alpha: opacity);
    final provinceId = session.hoveredProvinceId!;
    for (var y = 0; y < region.height; y++) {
      for (var x = 0; x < region.width; x++) {
        final cell = region.cellAt(x, y);
        if (cell.regionCellId != provinceId) continue;
        if (x + 1 < region.width) {
          final right = region.cellAt(x + 1, y);
          if (right.regionCellId != provinceId) {
            if (regionMapDrawBoundaryBetweenAdjacentCells(
              gateByUnrevealedTiles: gateMapBoundariesByVisibility,
              visibilityA: _visibilityForTerrain(cell),
              visibilityB: _visibilityForTerrain(right),
            )) {
              final xEdge = verticalProvinceTopologyEdgeX(
                left: cell,
                right: right,
                cellSizePx: cellSize,
                leftTileX: x,
                coastInsetPx: coastInset,
              );
              canvas.drawLine(
                Offset(xEdge, y * cellSize),
                Offset(xEdge, (y + 1) * cellSize),
                paint,
              );
            }
          }
        }
        if (y + 1 < region.height) {
          final bottom = region.cellAt(x, y + 1);
          if (bottom.regionCellId != provinceId) {
            if (regionMapDrawBoundaryBetweenAdjacentCells(
              gateByUnrevealedTiles: gateMapBoundariesByVisibility,
              visibilityA: _visibilityForTerrain(cell),
              visibilityB: _visibilityForTerrain(bottom),
            )) {
              final yEdge = horizontalProvinceTopologyEdgeY(
                top: cell,
                bottom: bottom,
                cellSizePx: cellSize,
                topTileY: y,
                coastInsetPx: coastInset,
              );
              canvas.drawLine(
                Offset(x * cellSize, yEdge),
                Offset((x + 1) * cellSize, yEdge),
                paint,
              );
            }
          }
        }
      }
    }
  }

  void _paintGreatPowerLandOwnershipTint(Canvas canvas) {
    paintGreatPowerOwnershipTintLayer(
      canvas: canvas,
      region: region,
      cellSize: cellSize,
      honorUnrevealedTiles:
          visibilityMode == CtMapVisibilityMode.playerConstrained,
    );
  }

  void _paintProvinceBorders(Canvas canvas) {
    final coastInset = provinceOverlayLandSeaInsetPx(
      cellSizePx: cellSize,
      topologyStrokeWidth: kProvinceOverlayTopologyStrokeWidth,
    );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = kProvinceOverlayTopologyStrokeWidth
      ..color = RegionMapPalette.provinceBorderLandColor;
    for (var y = 0; y < region.height; y++) {
      for (var x = 0; x < region.width; x++) {
        final cell = region.cellAt(x, y);
        if (x + 1 < region.width) {
          final right = region.cellAt(x + 1, y);
          if (cell.regionCellId != right.regionCellId) {
            if (regionMapDrawBoundaryBetweenAdjacentCells(
              gateByUnrevealedTiles: gateMapBoundariesByVisibility,
              visibilityA: _visibilityForTerrain(cell),
              visibilityB: _visibilityForTerrain(right),
            )) {
              paint.color = _provinceBorderColor(cell, right);
              final xEdge = verticalProvinceTopologyEdgeX(
                left: cell,
                right: right,
                cellSizePx: cellSize,
                leftTileX: x,
                coastInsetPx: coastInset,
              );
              canvas.drawLine(
                Offset(xEdge, y * cellSize),
                Offset(xEdge, (y + 1) * cellSize),
                paint,
              );
            }
          }
        }
        if (y + 1 < region.height) {
          final bottom = region.cellAt(x, y + 1);
          if (cell.regionCellId != bottom.regionCellId) {
            if (regionMapDrawBoundaryBetweenAdjacentCells(
              gateByUnrevealedTiles: gateMapBoundariesByVisibility,
              visibilityA: _visibilityForTerrain(cell),
              visibilityB: _visibilityForTerrain(bottom),
            )) {
              paint.color = _provinceBorderColor(cell, bottom);
              final yEdge = horizontalProvinceTopologyEdgeY(
                top: cell,
                bottom: bottom,
                cellSizePx: cellSize,
                topTileY: y,
                coastInsetPx: coastInset,
              );
              canvas.drawLine(
                Offset(x * cellSize, yEdge),
                Offset((x + 1) * cellSize, yEdge),
                paint,
              );
            }
          }
        }
      }
    }
  }

  Color _provinceBorderColor(CellViewData a, CellViewData b) {
    final aIsSea = a.isSea;
    final bIsSea = b.isSea;
    if (aIsSea && bIsSea) return RegionMapPalette.provinceBorderSeaZoneColor;
    if (!aIsSea && !bIsSea) return RegionMapPalette.provinceBorderLandColor;
    return RegionMapPalette.provinceBorderSeaLandColor;
  }
}
