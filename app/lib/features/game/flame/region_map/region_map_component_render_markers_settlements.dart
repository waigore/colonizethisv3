
part of 'region_map_component.dart';

extension _CtRegionMapRenderMarkersSettlements on CtRegionMapComponent {
  void _paintCapitals(Canvas canvas) {
    final fill = Paint()..style = PaintingStyle.fill;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = kCapitalMarkerRingStrokeWidth
      ..color = Colors.black;
    for (final cap in region.capitalMarkers) {
      final cell = region.cellAt(cap.x, cap.y);
      if (regionMapSkipPointMarkerOnCell(
        playerConstrainedVisibility:
            visibilityMode == CtMapVisibilityMode.playerConstrained,
        cellVisibility: _visibilityForTerrain(cell),
      )) {
        continue;
      }
      final cx = cap.x * cellSize + cellSize / 2;
      final cy = cap.y * cellSize + cellSize / 2;
      fill.color = _kMapSelectionGold;
      canvas.drawCircle(Offset(cx, cy), 6, fill);
      canvas.drawCircle(Offset(cx, cy), 6, stroke);
    }
  }

  void _paintTowns(Canvas canvas) {
    if (!townIconCache.isLoaded) return;

    for (final town in region.townMarkers) {
      final cell = region.cellAt(town.x, town.y);
      if (regionMapSkipPointMarkerOnCell(
        playerConstrainedVisibility:
            visibilityMode == CtMapVisibilityMode.playerConstrained,
        cellVisibility: _visibilityForTerrain(cell),
      )) {
        continue;
      }
      _paintTownIconAt(
        canvas,
        cell: cell,
        cx: town.x,
        cy: town.y,
        icon: TownIconCache.townIconIdForMarker(
          townIconStyle: town.townIconStyle,
          townDevelopmentLevel: town.townDevelopmentLevel,
        ),
      );
    }

    for (final town in region.townMarkers) {
      if (!town.isPort) continue;
      final px = town.portIconX;
      final py = town.portIconY;
      if (px == null || py == null) continue;
      final portCell = region.cellAt(px, py);
      if (regionMapSkipPointMarkerOnCell(
        playerConstrainedVisibility:
            visibilityMode == CtMapVisibilityMode.playerConstrained,
        cellVisibility: _visibilityForTerrain(portCell),
      )) {
        continue;
      }
      _paintTownIconAt(
        canvas,
        cell: portCell,
        cx: px,
        cy: py,
        icon: TownIconCache.portIconId,
      );
    }
  }

  void _paintTownIconAt(
    Canvas canvas, {
    required CellViewData cell,
    required int cx,
    required int cy,
    required String icon,
  }) {
    final uiImage = townIconCache.getIcon(icon);
    if (uiImage == null) return;

    final centerX = cx * cellSize + cellSize / 2;
    final centerY = cy * cellSize + cellSize / 2;
    final iconSize = icon == TownIconCache.portIconId
        ? TownIconCache.portIconSize
        : TownIconCache.townIconSize;
    final halfIcon = iconSize / 2;

    final srcRect = Rect.fromLTWH(
      0,
      0,
      uiImage.width.toDouble(),
      uiImage.height.toDouble(),
    );
    final dstRect = Rect.fromLTWH(
      centerX - halfIcon,
      centerY - halfIcon,
      iconSize,
      iconSize,
    );

    var paint = Paint();
    if (visibilityMode == CtMapVisibilityMode.playerConstrained &&
        _visibilityForTerrain(cell) == TileVisibility.fogged) {
      paint.color = Color.fromRGBO(0, 0, 0, _fogOverlayOpacity);
    }
    canvas.drawImageRect(uiImage, srcRect, dstRect, paint);
  }

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
      gateByUnrevealedTiles: _gateMapBoundariesByVisibility,
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
