
part of 'region_map_component.dart';

extension _CtRegionMapRenderCoreOverlays on CtRegionMapComponent {
  String? _resourceIdForMapIcon(CellViewData cell) {
    final raw = cell.resourceId;
    if (raw == null) return null;
    if (visibilityMode != CtMapVisibilityMode.playerConstrained) {
      return raw;
    }
    final view = playerViewForResources;
    if (view == null) {
      throw StateError(
        'CtRegionMapComponent: playerConstrained requires playerViewForResources',
      );
    }
    final tileKey =
        '${region.regionId}|${cell.regionCellId}|${cell.x}|${cell.y}';
    return resourceIdVisibleInPlayerView(view, tileKey, raw);
  }

  void _paintOverlay(Canvas canvas) {
    final showResources =
        baseLayerDisplayMode != BaseLayerDisplayMode.terrainOnly;
    final showExtractionIndicators = shouldShowExtractionUnitIndicators(
      baseLayerDisplayMode: baseLayerDisplayMode,
    );
    final showImprovementLabels =
        baseLayerDisplayMode ==
            BaseLayerDisplayMode.terrainAndResourcesImprovementLabels ||
        baseLayerDisplayMode ==
            BaseLayerDisplayMode.terrainAndResourcesImprovementsRoads;
    for (final cell in region.cells) {
      if (cell.isSea) continue;
      if (visibilityMode == CtMapVisibilityMode.playerConstrained &&
          _visibilityForTerrain(cell) == TileVisibility.unrevealed) {
        continue;
      }

      final resourceForIcon = _resourceIdForMapIcon(cell);
      if (showResources && resourceForIcon != null) {
        final icon = resourceIconCache.getIcon(resourceForIcon);
        if (icon != null) {
          final assetSize = ResourceIconCache.iconSize;
          final displaySize = resourceIconDisplaySizePx(cellSize);
          final tileLeft = cell.x * cellSize;
          final tileTop = cell.y * cellSize;

          final iconX = tileLeft;
          final iconY = tileTop + cellSize - displaySize;

          final dstRect = Rect.fromLTWH(iconX, iconY, displaySize, displaySize);
          final srcRect = Rect.fromLTWH(0, 0, assetSize, assetSize);
          final paint = _resourceOverlayPaintForCell(cell);
          canvas.drawImageRect(icon, srcRect, dstRect, paint);
          final effectiveUnits =
              cell.resourceExtractionEffectiveUnits ??
              cell.resourceExtractionUnits ??
              0;
          final blockedUnits = cell.resourceExtractionBlockedUnits ?? 0;
          final totalUnits = effectiveUnits + blockedUnits;
          if (showExtractionIndicators && totalUnits > 0) {
            final indicatorRects = extractionIndicatorRectsForIconRect(
              iconRect: dstRect,
              units: totalUnits,
            );
            paintResourceExtractionDiscIndicators(
              canvas: canvas,
              indicatorRects: indicatorRects,
              effectiveCount: effectiveUnits,
              fogCompatibleOverlayPaint: _resourceOverlayPaintForCell(cell),
            );
          }
        }
      }
    }

    if (showImprovementLabels) {
      for (final cell in region.cells) {
        if (cell.isSea) continue;
        if (visibilityMode == CtMapVisibilityMode.playerConstrained &&
            _visibilityForTerrain(cell) == TileVisibility.unrevealed) {
          continue;
        }
        final imp = cell.improvementLevel ?? 0;
        if (imp <= 0) continue;
        _paintTileCornerLabel(canvas, cell, 'I$imp', alignEnd: false);
      }
    }
  }

  void _paintTileCornerLabel(
    Canvas canvas,
    CellViewData cell,
    String text, {
    required bool alignEnd,
  }) {
    final tileLeft = cell.x * cellSize;
    final tileTop = cell.y * cellSize;
    final pad = math.max(1.0, cellSize * 0.06);
    final fontSize = math.max(8.0, cellSize * 0.25);
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: text,
      style: TextStyle(
        color: Colors.black,
        fontSize: fontSize,
        fontWeight: FontWeight.w600,
      ),
    );
    textPainter.layout(maxWidth: cellSize - 2 * pad);
    final y = tileTop + pad;
    final x = alignEnd
        ? tileLeft + cellSize - pad - textPainter.width
        : tileLeft + pad;
    textPainter.paint(canvas, Offset(x, y));
  }
}
