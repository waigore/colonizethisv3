
part of 'region_map_component.dart';

extension _CtRegionMapRenderCoreBaseTilesHelpers on CtRegionMapComponent {
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
}
