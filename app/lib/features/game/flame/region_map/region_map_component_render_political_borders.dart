
part of 'region_map_component.dart';

extension _CtRegionMapRenderPoliticalBorders on CtRegionMapComponent {
  void _paintHoveredProvinceGlow(Canvas canvas) {
    final t = _hoverAnimationT;
    final opacity =
        _kHoveredProvinceGlowOpacityMid +
        _kHoveredProvinceGlowOpacityAmplitude *
            math.sin(t * _kHoveredProvinceGlowAngularFrequency);
    final coastInset = provinceOverlayLandSeaInsetPx(
      cellSizePx: cellSize,
      topologyStrokeWidth: kProvinceOverlayTopologyStrokeWidth,
    );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = kProvinceOverlayHoverGlowStrokeWidth
      ..color = _kMapHoverSelectorIdle.withValues(alpha: opacity);
    final provinceId = _hoveredProvinceId!;
    for (var y = 0; y < region.height; y++) {
      for (var x = 0; x < region.width; x++) {
        final cell = region.cellAt(x, y);
        if (cell.regionCellId != provinceId) continue;
        if (x + 1 < region.width) {
          final right = region.cellAt(x + 1, y);
          if (right.regionCellId != provinceId) {
            if (regionMapDrawBoundaryBetweenAdjacentCells(
              gateByUnrevealedTiles: _gateMapBoundariesByVisibility,
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
              gateByUnrevealedTiles: _gateMapBoundariesByVisibility,
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
      ..color = _provinceBorderLandColor;
    for (var y = 0; y < region.height; y++) {
      for (var x = 0; x < region.width; x++) {
        final cell = region.cellAt(x, y);
        if (x + 1 < region.width) {
          final right = region.cellAt(x + 1, y);
          if (cell.regionCellId != right.regionCellId) {
            if (regionMapDrawBoundaryBetweenAdjacentCells(
              gateByUnrevealedTiles: _gateMapBoundariesByVisibility,
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
              gateByUnrevealedTiles: _gateMapBoundariesByVisibility,
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
    if (aIsSea && bIsSea) return _provinceBorderSeaZoneColor;
    if (!aIsSea && !bIsSea) return _provinceBorderLandColor;
    return _provinceBorderSeaLandColor;
  }

  void _paintFactionBorders(Canvas canvas) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = kProvinceOverlayPoliticalStrokeWidth
      ..color = _kFactionPoliticalBorderColor;
    for (var y = 0; y < region.height; y++) {
      for (var x = 0; x < region.width; x++) {
        final cell = region.cellAt(x, y);
        if (cell.isSea) continue;
        final owner = cell.ownerFactionId ?? '';
        if (x + 1 < region.width) {
          final right = region.cellAt(x + 1, y);
          if (!right.isSea && (right.ownerFactionId ?? '') != owner) {
            if (regionMapDrawBoundaryBetweenAdjacentCells(
              gateByUnrevealedTiles: _gateMapBoundariesByVisibility,
              visibilityA: _visibilityForTerrain(cell),
              visibilityB: _visibilityForTerrain(right),
            )) {
              final xEdge = (x + 1) * cellSize;
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
          if (!bottom.isSea && (bottom.ownerFactionId ?? '') != owner) {
            if (regionMapDrawBoundaryBetweenAdjacentCells(
              gateByUnrevealedTiles: _gateMapBoundariesByVisibility,
              visibilityA: _visibilityForTerrain(cell),
              visibilityB: _visibilityForTerrain(bottom),
            )) {
              final yEdge = (y + 1) * cellSize;
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
}
