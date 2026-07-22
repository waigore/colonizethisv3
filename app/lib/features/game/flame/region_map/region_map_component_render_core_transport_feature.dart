
part of 'region_map_component.dart';

extension _CtRegionMapRenderCoreTransportFeature on CtRegionMapComponent {
  /// Interior L1 plains resource decals (`tile_plains_*`) must stack above
  /// transport (SPEC/ui/map-widget.md § Base overlay paint order). Skips
  /// plains↔desert Wang cells — same gating as [_paintLandBaseTile].
  void _paintL1PlainsInteriorResourceVariantOverlays(Canvas canvas) {
    for (final cell in region.cells) {
      if (cell.isSea) continue;
      if (visibilityMode == CtMapVisibilityMode.playerConstrained &&
          _visibilityForTerrain(cell) == TileVisibility.unrevealed) {
        continue;
      }
      if (cell.terrainType != TerrainType.plains) continue;
      if (_isPlainTerrainAtDesertTransitionWangCell(cell)) continue;

      final plainsVariantKey = landInteriorPlainsVariantTileKey(cell);
      if (plainsVariantKey == null) continue;

      final standaloneTile = terrainTilesetCache.getStandaloneTileByKey(
        plainsVariantKey,
      );
      if (standaloneTile == null) {
        throw StateError(
          'Missing required plains terrain variant tile: $plainsVariantKey',
        );
      }
      final left = cell.x * cellSize;
      final top = cell.y * cellSize;
      final dstRect = Rect.fromLTWH(left, top, cellSize, cellSize);
      final overlayPaint = Paint();
      if (shouldApplyFogToInteriorPlainsVariantOverlay(
        visibilityMode: visibilityMode,
        tileVisibility: _visibilityForTerrain(cell),
      )) {
        overlayPaint.colorFilter = ColorFilter.mode(
          Color.fromRGBO(0, 0, 0, RegionMapPalette.fogOverlayOpacity),
          BlendMode.darken,
        );
      }
      final srcRect = Rect.fromLTWH(
        0,
        0,
        standaloneTile.image.width.toDouble(),
        standaloneTile.image.height.toDouble(),
      );
      canvas.drawImageRect(
        standaloneTile.image,
        srcRect,
        dstRect,
        overlayPaint,
      );
    }
  }

  bool _isPlainTerrainAtDesertTransitionWangCell(CellViewData cell) {
    final nearDesertCorner = _getCornerValues(
      cell.x,
      cell.y,
      (c) => !c.isSea && c.terrainType == TerrainType.desert,
    );
    return !nearDesertCorner.same && nearDesertCorner.value;
  }

  void _paintTransportOverlayTiles(Canvas canvas) {
    if (!shouldRenderTransportOverlay(
      baseLayerDisplayMode: baseLayerDisplayMode,
    )) {
      return;
    }
    if (!transportOverlayTilesetCache.isLoaded) {
      return;
    }
    for (final cell in region.cells) {
      final tileVisibility = _visibilityForTerrain(cell);
      if (!shouldPaintTransportOverlayForCell(
        cell: cell,
        visibilityMode: visibilityMode,
        tileVisibility: tileVisibility,
      )) {
        continue;
      }
      final roadLevel = cell.roadLevel ?? 0;
      final family = isRailTransportLevel(roadLevel)
          ? TransportTileFamily.rail
          : TransportTileFamily.road;
      final tileset = transportOverlayTilesetCache.getTileset(family);
      if (tileset == null) {
        continue;
      }
      final mask = computeTransportConnectivityMask(
        x: cell.x,
        y: cell.y,
        getCellAt: _getCellAt,
      );
      final srcRect = tileset.tileRectForMask(mask);
      if (srcRect == null) {
        _log.w('Transport tile missing for family=$family mask=$mask');
        continue;
      }
      final tileLeft = cell.x * cellSize;
      final tileTop = cell.y * cellSize;
      final dstRect = Rect.fromLTWH(tileLeft, tileTop, cellSize, cellSize);
      canvas.drawImageRect(
        tileset.image,
        srcRect,
        dstRect,
        _resourceOverlayPaintForCell(cell),
      );
    }
  }

  void _paintFeatureCell(Canvas canvas, CellViewData cell) {
    final left = cell.x * cellSize;
    final top = cell.y * cellSize;

    if (visibilityMode == CtMapVisibilityMode.playerConstrained &&
        _visibilityForTerrain(cell) == TileVisibility.unrevealed) {
      return;
    }

    final terrain = cell.terrainType;
    if (terrain == null || !regionMapComponentIsFeatureTerrain(terrain)) return;

    final overlayTileKey = featureOverlayTileKey(
      terrain: terrain,
      resourceId: cell.resourceId,
      improvementLevel: cell.improvementLevel,
    );
    final standaloneTile =
        terrainTilesetCache.getStandaloneTileByKey(overlayTileKey) ??
        terrainTilesetCache.getStandaloneTile(terrain);
    if (standaloneTile == null) {
      _log.w(
        'Feature overlay tile missing for key=$overlayTileKey terrain=$terrain; '
        'skipping feature overlay for cell (${cell.x}, ${cell.y})',
      );
      return;
    }

    final paint = Paint();
    if (shouldApplyFogToFeatureOverlay(
      visibilityMode: visibilityMode,
      tileVisibility: _visibilityForTerrain(cell),
      terrain: terrain,
    )) {
      paint.colorFilter = ColorFilter.mode(
        Color.fromRGBO(0, 0, 0, RegionMapPalette.fogOverlayOpacity),
        BlendMode.darken,
      );
    }

    final srcRect = Rect.fromLTWH(
      0,
      0,
      standaloneTile.image.width.toDouble(),
      standaloneTile.image.height.toDouble(),
    );
    final dstRect = Rect.fromLTWH(left, top, cellSize, cellSize);
    canvas.drawImageRect(standaloneTile.image, srcRect, dstRect, paint);
  }

  Paint _resourceOverlayPaintForCell(CellViewData cell) {
    final paint = Paint();
    if (visibilityMode == CtMapVisibilityMode.playerConstrained &&
        _visibilityForTerrain(cell) == TileVisibility.fogged) {
      paint.colorFilter = ColorFilter.mode(
        RegionMapPalette.mapHoverSelectorIdle.withValues(
          alpha: RegionMapPalette.foggedResourceIconModulateAlpha,
        ),
        BlendMode.modulate,
      );
    }
    return paint;
  }
}
