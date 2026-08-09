import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:flutter/material.dart';

import '../tilesets/tilesets.dart';
import 'region_map_component.dart';
import 'region_map_component_render_core.dart';
import 'region_map_component_render_core_overlays.dart';

extension CtRegionMapRenderCoreTiles on CtRegionMapComponent {
  void paintTiles(Canvas canvas) {
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

    paintTransportOverlayTiles(canvas);

    paintL1PlainsInteriorResourceVariantOverlays(canvas);

    for (final cell in region.cells) {
      if (!cell.isSea &&
          cell.terrainType != null &&
          regionMapComponentIsFeatureTerrain(cell.terrainType!)) {
        paintFeatureCell(canvas, cell);
      }
    }
  }
}

extension CtRegionMapRenderCoreBaseTilesSea on CtRegionMapComponent {
  void _paintSeaCell(Canvas canvas, CellViewData cell) {
    final left = cell.x * cellSize;
    final top = cell.y * cellSize;

    if (visibilityMode == CtMapVisibilityMode.playerConstrained &&
        regionMapComponentVisibilityForTerrain(this, cell) == TileVisibility.unrevealed) {
      final paint = Paint()..color = Colors.black;
      canvas.drawRect(Rect.fromLTWH(left, top, cellSize, cellSize), paint);
      return;
    }

    final landCorner = getCoastlineCornerValues(cell.x, cell.y);
    final dominantLandType = regionMapComponentDominantAdjacentLandBase(
      cell.x,
      cell.y,
      getCellAt,
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
            regionMapComponentVisibilityForTerrain(this, cell) == TileVisibility.fogged) {
          canvas.drawRect(
            dstRect,
            Paint()..color = Color.fromRGBO(0, 0, 0, RegionMapPalette.fogOverlayOpacity),
          );
        }
      }
      return;
    }

    drawTile(
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
}

extension CtRegionMapRenderCoreBaseTilesLand on CtRegionMapComponent {
  void _paintLandBaseCell(Canvas canvas, CellViewData cell) {
    final left = cell.x * cellSize;
    final top = cell.y * cellSize;

    if (visibilityMode == CtMapVisibilityMode.playerConstrained &&
        regionMapComponentVisibilityForTerrain(this, cell) == TileVisibility.unrevealed) {
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
        terrain == TerrainType.plains || regionMapComponentIsFeatureTerrain(terrain);
    final isDesert = terrain == TerrainType.desert;

    final nearDesertCorner = getCornerValues(
      cell.x,
      cell.y,
      (c) => !c.isSea && c.terrainType == TerrainType.desert,
    );
    final nearPlainsCorner = getCornerValues(
      cell.x,
      cell.y,
      (c) =>
          !c.isSea &&
          (c.terrainType == TerrainType.plains ||
              (c.terrainType != null && regionMapComponentIsFeatureTerrain(c.terrainType!))),
    );

    if (isPlains && !nearDesertCorner.same && nearDesertCorner.value) {
      final tileset = terrainTilesetCache.getPlainsDesertTileset();
      if (tileset == null) {
        throw StateError(
          'Plains desert tileset is null - terrain tileset failed to load',
        );
      }
      drawTile(
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
      drawTile(
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
          !isPlainTerrainAtDesertTransitionWangCell(cell)) {
        final dstRect = Rect.fromLTWH(left, top, cellSize, cellSize);
        drawLandInteriorUpperBaseForTerrain(
          canvas,
          landTerrain: TerrainType.plains,
          dstRect: dstRect,
          paint: Paint(),
        );
        return;
      }
    }

    final dstRect = Rect.fromLTWH(left, top, cellSize, cellSize);
    final paint = landBaseImagePaint(
      terrain: terrain,
      tileVisibility: regionMapComponentVisibilityForTerrain(this, cell),
    );
    drawLandInteriorUpperBaseForTerrain(
      canvas,
      landTerrain: terrain,
      dstRect: dstRect,
      paint: paint,
    );
  }
}
