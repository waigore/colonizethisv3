
part of 'region_map_component.dart';

extension _CtRegionMapRenderCore on CtRegionMapComponent {
  void _paintTiles(Canvas canvas) {
    if (!terrainTilesetCache.isLoaded) {
      return;
    }
    _paintTilesWithTilesets(canvas);
  }

  void _paintTilesWithTilesets(Canvas canvas) {
    for (final cell in region.cells) {
      if (cell.isSea) {
        _paintSeaCell(canvas, cell);
      }
    }

    for (final cell in region.cells) {
      if (!cell.isSea) {
        _paintLandBaseCell(canvas, cell);
      }
    }

    _paintTransportOverlayTiles(canvas);

    _paintL1PlainsInteriorResourceVariantOverlays(canvas);

    for (final cell in region.cells) {
      if (!cell.isSea &&
          cell.terrainType != null &&
          _isFeatureTerrain(cell.terrainType!)) {
        _paintFeatureCell(canvas, cell);
      }
    }
  }

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
          Color.fromRGBO(0, 0, 0, _fogOverlayOpacity),
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

  void _paintSeaCell(Canvas canvas, CellViewData cell) {
    final left = cell.x * cellSize;
    final top = cell.y * cellSize;

    if (visibilityMode == CtMapVisibilityMode.playerConstrained &&
        _visibilityForTerrain(cell) == TileVisibility.unrevealed) {
      final paint = Paint()..color = Colors.black;
      canvas.drawRect(Rect.fromLTWH(left, top, cellSize, cellSize), paint);
      return;
    }

    final landCorner = _getCoastlineCornerValues(cell.x, cell.y);
    final dominantLandType = _getDominantAdjacentLandBase(
      cell.x,
      cell.y,
      _getCellAt,
    );
    final tileset = dominantLandType == TerrainType.desert
        ? terrainTilesetCache.getSeaDesertTileset()
        : terrainTilesetCache.getSeaPlainsTileset();

    if (tileset == null) {
      throw StateError(
        'Sea tileset is null for dominantLandType=$dominantLandType - '
        'terrain tileset failed to load',
      );
    }

    if (landCorner.same) {
      final seaBaseTileId = tileset.lowerBaseTileId;
      final tile = seaBaseTileId != null
          ? tileset.findTileById(seaBaseTileId)
          : tileset.findTile(nw: false, ne: false, sw: false, se: false);
      if (tile != null) {
        final srcRect = tile.boundingBox;
        final dstRect = Rect.fromLTWH(left, top, cellSize, cellSize);
        canvas.drawImageRect(tileset.image, srcRect, dstRect, Paint());
        if (visibilityMode == CtMapVisibilityMode.playerConstrained &&
            _visibilityForTerrain(cell) == TileVisibility.fogged) {
          canvas.drawRect(
            dstRect,
            Paint()..color = Color.fromRGBO(0, 0, 0, _fogOverlayOpacity),
          );
        }
      }
      return;
    }

    _drawTile(
      canvas,
      tileset,
      left,
      top,
      nw: landCorner.nw,
      ne: landCorner.ne,
      sw: landCorner.sw,
      se: landCorner.se,
      cell: cell,
    );
  }

  void _paintLandBaseCell(Canvas canvas, CellViewData cell) {
    final left = cell.x * cellSize;
    final top = cell.y * cellSize;

    if (visibilityMode == CtMapVisibilityMode.playerConstrained &&
        _visibilityForTerrain(cell) == TileVisibility.unrevealed) {
      final paint = Paint()..color = Colors.black;
      canvas.drawRect(Rect.fromLTWH(left, top, cellSize, cellSize), paint);
      return;
    }

    final terrain = cell.terrainType;
    if (terrain == null) {
      throw StateError('Cell has no terrain type: $cell');
    }
    _paintLandBaseTile(canvas, cell);
  }

  /// Wang interior upper-base tile for land: `sea_plains` for plains (and
  /// feature terrains on plains) or `sea_desert` for desert. Used for L1 cells
  /// and for the opaque grass under transparent `tile_plains_*` overlays.
  void _drawLandInteriorUpperBaseForTerrain(
    Canvas canvas, {
    required TerrainType landTerrain,
    required Rect dstRect,
    required Paint paint,
  }) {
    final interiorTileset = landTerrain == TerrainType.desert
        ? terrainTilesetCache.getSeaDesertTileset()
        : terrainTilesetCache.getSeaPlainsTileset();
    if (interiorTileset == null) {
      throw StateError(
        'Interior tileset is null for terrain=$landTerrain - '
        'terrain tileset failed to load',
      );
    }
    final tile = interiorTileset.upperBaseTileId != null
        ? interiorTileset.findTileById(interiorTileset.upperBaseTileId!)
        : null;
    if (tile == null) {
      throw StateError(
        'Base tile not found for terrain=$landTerrain - '
        'upperBaseTileId=${interiorTileset.upperBaseTileId}',
      );
    }
    canvas.drawImageRect(
      interiorTileset.image,
      tile.boundingBox,
      dstRect,
      paint,
    );
  }

  Paint _landBaseImagePaint({
    required TerrainType terrain,
    required TileVisibility tileVisibility,
  }) {
    final paint = Paint();
    if (shouldApplyFogToLandBase(
      visibilityMode: visibilityMode,
      tileVisibility: tileVisibility,
      terrain: terrain,
    )) {
      paint.colorFilter = ColorFilter.mode(
        Color.fromRGBO(0, 0, 0, _fogOverlayOpacity),
        BlendMode.darken,
      );
    }
    return paint;
  }

  void _paintLandBaseTile(Canvas canvas, CellViewData cell) {
    final left = cell.x * cellSize;
    final top = cell.y * cellSize;
    final terrainNullable = cell.terrainType;
    if (terrainNullable == null) {
      throw StateError('Cell has no terrain type: $cell');
    }
    final terrain = terrainNullable;

    final isPlains =
        terrain == TerrainType.plains || _isFeatureTerrain(terrain);
    final isDesert = terrain == TerrainType.desert;

    final nearDesertCorner = _getCornerValues(
      cell.x,
      cell.y,
      (c) => !c.isSea && c.terrainType == TerrainType.desert,
    );
    final nearPlainsCorner = _getCornerValues(
      cell.x,
      cell.y,
      (c) =>
          !c.isSea &&
          (c.terrainType == TerrainType.plains ||
              (c.terrainType != null && _isFeatureTerrain(c.terrainType!))),
    );

    if (isPlains && !nearDesertCorner.same && nearDesertCorner.value) {
      final tileset = terrainTilesetCache.getPlainsDesertTileset();
      if (tileset == null) {
        throw StateError(
          'Plains desert tileset is null - terrain tileset failed to load',
        );
      }
      _drawTile(
        canvas,
        tileset,
        left,
        top,
        nw: nearDesertCorner.nw,
        ne: nearDesertCorner.ne,
        sw: nearDesertCorner.sw,
        se: nearDesertCorner.se,
        cell: cell,
      );
      return;
    }

    if (isDesert && !nearPlainsCorner.same && nearPlainsCorner.value) {
      final tileset = terrainTilesetCache.getPlainsDesertTileset();
      if (tileset == null) {
        throw StateError(
          'Plains desert tileset is null - terrain tileset failed to load',
        );
      }
      _drawTile(
        canvas,
        tileset,
        left,
        top,
        nw: !nearPlainsCorner.nw,
        ne: !nearPlainsCorner.ne,
        sw: !nearPlainsCorner.sw,
        se: !nearPlainsCorner.se,
        cell: cell,
      );
      return;
    }

    if (terrain == TerrainType.plains) {
      final plainsVariantKey = landInteriorPlainsVariantTileKey(cell);
      if (plainsVariantKey != null &&
          !_isPlainTerrainAtDesertTransitionWangCell(cell)) {
        final dstRect = Rect.fromLTWH(left, top, cellSize, cellSize);
        _drawLandInteriorUpperBaseForTerrain(
          canvas,
          landTerrain: TerrainType.plains,
          dstRect: dstRect,
          paint: Paint(),
        );
        return;
      }
    }

    final dstRect = Rect.fromLTWH(left, top, cellSize, cellSize);
    final paint = _landBaseImagePaint(
      terrain: terrain,
      tileVisibility: _visibilityForTerrain(cell),
    );
    _drawLandInteriorUpperBaseForTerrain(
      canvas,
      landTerrain: terrain,
      dstRect: dstRect,
      paint: paint,
    );
  }

  void _paintFeatureCell(Canvas canvas, CellViewData cell) {
    final left = cell.x * cellSize;
    final top = cell.y * cellSize;

    if (visibilityMode == CtMapVisibilityMode.playerConstrained &&
        _visibilityForTerrain(cell) == TileVisibility.unrevealed) {
      return;
    }

    final terrain = cell.terrainType;
    if (terrain == null || !_isFeatureTerrain(terrain)) return;

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
        Color.fromRGBO(0, 0, 0, _fogOverlayOpacity),
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

  _CornerValues _getCornerValues(
    int x,
    int y,
    bool Function(CellViewData) predicate,
  ) {
    final nwCell = _getCellAt(x - 1, y - 1);
    final nCell = _getCellAt(x, y - 1);
    final neCell = _getCellAt(x + 1, y - 1);
    final wCell = _getCellAt(x - 1, y);
    final cCell = _getCellAt(x, y);
    final eCell = _getCellAt(x + 1, y);
    final swCell = _getCellAt(x - 1, y + 1);
    final sCell = _getCellAt(x, y + 1);
    final seCell = _getCellAt(x + 1, y + 1);

    bool test(CellViewData? c) => c != null && predicate(c);

    final centerMatches = cCell != null && predicate(cCell);
    final hasNW = centerMatches && (test(nwCell) || test(nCell) || test(wCell));
    final hasNE = centerMatches && (test(neCell) || test(nCell) || test(eCell));
    final hasSW = centerMatches && (test(swCell) || test(sCell) || test(wCell));
    final hasSE = centerMatches && (test(seCell) || test(sCell) || test(eCell));

    final allSame = (hasNW == hasNE && hasNE == hasSW && hasSW == hasSE);
    final same = allSame && (!hasNW || centerMatches);
    final value = hasNW;

    return _CornerValues(
      nw: hasNW,
      ne: hasNE,
      sw: hasSW,
      se: hasSE,
      same: same,
      value: value,
    );
  }

  _CornerValues _getCoastlineCornerValues(int x, int y) {
    final nwCell = _getCellAt(x - 1, y - 1);
    final nCell = _getCellAt(x, y - 1);
    final neCell = _getCellAt(x + 1, y - 1);
    final wCell = _getCellAt(x - 1, y);
    final eCell = _getCellAt(x + 1, y);
    final swCell = _getCellAt(x - 1, y + 1);
    final sCell = _getCellAt(x, y + 1);
    final seCell = _getCellAt(x + 1, y + 1);

    bool isLand(CellViewData? c) => c != null && !c.isSea;

    final hasNW = isLand(nwCell) || isLand(nCell) || isLand(wCell);
    final hasNE = isLand(neCell) || isLand(nCell) || isLand(eCell);
    final hasSW = isLand(swCell) || isLand(sCell) || isLand(wCell);
    final hasSE = isLand(seCell) || isLand(sCell) || isLand(eCell);

    final allSame = (hasNW == hasNE && hasNE == hasSW && hasSW == hasSE);
    final same = allSame && !hasNW;

    return _CornerValues(
      nw: hasNW,
      ne: hasNE,
      sw: hasSW,
      se: hasSE,
      same: same,
      value: hasNW,
    );
  }

  bool _drawTile(
    Canvas canvas,
    WangTileset tileset,
    double left,
    double top, {
    required bool nw,
    required bool ne,
    required bool sw,
    required bool se,
    required CellViewData cell,
  }) {
    final tile = tileset.findTile(nw: nw, ne: ne, sw: sw, se: se);
    if (tile == null) {
      _log.w(
        'No tile found in ${tileset.name} for corners: NW=$nw, NE=$ne, SW=$sw, SE=$se',
      );
      return false;
    }

    final srcRect = tile.boundingBox;
    final dstRect = Rect.fromLTWH(left, top, cellSize, cellSize);
    canvas.drawImageRect(tileset.image, srcRect, dstRect, Paint());

    if (visibilityMode == CtMapVisibilityMode.playerConstrained &&
        _visibilityForTerrain(cell) == TileVisibility.fogged) {
      canvas.drawRect(
        dstRect,
        Paint()..color = Color.fromRGBO(0, 0, 0, _fogOverlayOpacity),
      );
    }
    return true;
  }

  CellViewData? _getCellAt(int x, int y) {
    if (x < 0 || x >= region.width || y < 0 || y >= region.height) return null;
    return region.cellAt(x, y);
  }

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

  Paint _resourceOverlayPaintForCell(CellViewData cell) {
    final paint = Paint();
    if (visibilityMode == CtMapVisibilityMode.playerConstrained &&
        _visibilityForTerrain(cell) == TileVisibility.fogged) {
      paint.colorFilter = ColorFilter.mode(
        _kMapHoverSelectorIdle.withValues(
          alpha: _kFoggedResourceIconModulateAlpha,
        ),
        BlendMode.modulate,
      );
    }
    return paint;
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
