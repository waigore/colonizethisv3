
part of 'region_map_component.dart';

extension _CtRegionMapRenderPoliticalBordersFaction on CtRegionMapComponent {
  void _paintFactionBorders(Canvas canvas) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = kProvinceOverlayPoliticalStrokeWidth
      ..color = RegionMapPalette.factionPoliticalBorderColor;
    for (var y = 0; y < region.height; y++) {
      for (var x = 0; x < region.width; x++) {
        final cell = region.cellAt(x, y);
        if (cell.isSea) continue;
        final owner = cell.ownerFactionId ?? '';
        if (x + 1 < region.width) {
          final right = region.cellAt(x + 1, y);
          if (!right.isSea && (right.ownerFactionId ?? '') != owner) {
            if (regionMapDrawBoundaryBetweenAdjacentCells(
              gateByUnrevealedTiles: gateMapBoundariesByVisibility,
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
              gateByUnrevealedTiles: gateMapBoundariesByVisibility,
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
