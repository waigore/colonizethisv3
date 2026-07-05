
part of 'region_map_component.dart';

extension _CtRegionMapRenderCoreBaseTilesLand on CtRegionMapComponent {
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
}
