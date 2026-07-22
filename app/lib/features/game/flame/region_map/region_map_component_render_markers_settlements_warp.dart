
part of 'region_map_component.dart';

extension _CtRegionMapRenderMarkersSettlementsWarp on CtRegionMapComponent {
  Set<(int x, int y)> _warpTileCoordsForZones(Set<String> warpSeaZoneIds) {
    final warpTiles = <(int x, int y)>{};
    for (var y = 0; y < region.height; y++) {
      for (var x = 0; x < region.width; x++) {
        final cell = region.cellAt(x, y);
        if (warpSeaZoneIds.contains(cell.regionCellId)) {
          warpTiles.add((x, y));
        }
      }
    }
    return warpTiles;
  }

  void _paintWarpZones(Canvas canvas) {
    final warpSeaZoneIds = region.warpMarkers.map((m) => m.seaZoneId).toSet();
    if (warpSeaZoneIds.isEmpty) return;

    final warpTiles = _warpTileCoordsForZones(warpSeaZoneIds);

    final glowOuter = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = kWarpZoneGlowOuterStrokeWidth
      ..color = _kMapSelectionGold.withValues(alpha: _kWarpZoneOuterGlowAlpha);
    final glowInner = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = kWarpZoneGlowInnerStrokeWidth
      ..color = _kWarpZoneInnerHighlight;

    for (final (x, y) in warpTiles) {
      final cell = region.cellAt(x, y);
      // Defense in depth: [warpTiles] is built from warp sea-zone ids, but keep
      // this guard so a stale set or future caller change cannot paint edges
      // from non-warp cells.
      if (!warpSeaZoneIds.contains(cell.regionCellId)) {
        continue;
      }

      _paintWarpZoneEdge(
        canvas,
        x: x,
        y: y,
        cell: cell,
        warpSeaZoneIds: warpSeaZoneIds,
        dx: 1,
        dy: 0,
        glowOuter: glowOuter,
        glowInner: glowInner,
      );
      _paintWarpZoneEdge(
        canvas,
        x: x,
        y: y,
        cell: cell,
        warpSeaZoneIds: warpSeaZoneIds,
        dx: 0,
        dy: 1,
        glowOuter: glowOuter,
        glowInner: glowInner,
      );
      _paintWarpZoneEdge(
        canvas,
        x: x,
        y: y,
        cell: cell,
        warpSeaZoneIds: warpSeaZoneIds,
        dx: -1,
        dy: 0,
        glowOuter: glowOuter,
        glowInner: glowInner,
      );
      _paintWarpZoneEdge(
        canvas,
        x: x,
        y: y,
        cell: cell,
        warpSeaZoneIds: warpSeaZoneIds,
        dx: 0,
        dy: -1,
        glowOuter: glowOuter,
        glowInner: glowInner,
      );
    }
  }

  void _paintWarpZoneEdge(
    Canvas canvas, {
    required int x,
    required int y,
    required CellViewData cell,
    required Set<String> warpSeaZoneIds,
    required int dx,
    required int dy,
    required Paint glowOuter,
    required Paint glowInner,
  }) {
    final nx = x + dx;
    final ny = y + dy;
    if (nx < 0 || nx >= region.width || ny < 0 || ny >= region.height) {
      return;
    }

    final neighbor = region.cellAt(nx, ny);
    if (warpSeaZoneIds.contains(neighbor.regionCellId)) {
      return;
    }

    if (!regionMapDrawBoundaryBetweenAdjacentCells(
      gateByUnrevealedTiles: gateMapBoundariesByVisibility,
      visibilityA: _visibilityForTerrain(cell),
      visibilityB: _visibilityForTerrain(neighbor),
    )) {
      return;
    }

    final segment = warpZoneGlowLineForDirection(
      cellSize: cellSize,
      x: x,
      y: y,
      dx: dx,
      dy: dy,
    );
    canvas.drawLine(segment.$1, segment.$2, glowOuter);
    canvas.drawLine(segment.$1, segment.$2, glowInner);
  }
}
