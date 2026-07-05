
part of 'region_map_component.dart';

extension _CtRegionMapRenderMarkersSettlementsTowns on CtRegionMapComponent {
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
}
