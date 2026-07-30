import 'dart:math' as math;
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart' show PlayerView, resourceIdVisibleInPlayerView;
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:flutter/material.dart';
import '../caches/civilian_icon_cache.dart';
import '../caches/fleet_icon_cache.dart';
import '../caches/province_label_icon_cache.dart';
import '../caches/resource_icon_cache.dart';
import '../caches/town_icon_cache.dart';
import '../tilesets/tilesets.dart';
import 'region_map_component.dart';
import 'region_map_component_render_core_overlays.dart';
import 'region_map_component_render_markers_selection.dart';
import 'region_map_component_render_markers_settlements.dart';
import 'region_map_component_render_markers_units.dart';
import 'region_map_component_render_player_territory_outline.dart';
import 'region_map_component_render_political.dart';
import 'region_map_component_render_political_borders.dart';
import 'region_map_component_shared_palette.dart';
import 'region_map_component_shared_visibility.dart';
import 'region_map_component_support.dart';

class RegionMapComponentCornerValues {
  final bool nw;
  final bool ne;
  final bool sw;
  final bool se;
  final bool same;
  final bool value;

  RegionMapComponentCornerValues({
    required this.nw,
    required this.ne,
    required this.sw,
    required this.se,
    required this.same,
    required this.value,
  });
}

extension CtRegionMapRenderOrchestrator on CtRegionMapComponent {
  void renderRegionMap(Canvas canvas) {
    paintTiles(canvas);
    if (showProvinceOwnershipTint) {
      paintGreatPowerLandOwnershipTint(canvas);
    }
    paintOverlay(canvas);
    if (showProvinceOverlay) {
      paintProvinceBorders(canvas);
    }
    if (showPlayerTerritoryOutline) {
      paintPlayerTerritoryOutline(canvas);
    }
    if (session.hoveredProvinceId != null) {
      paintHoveredProvinceGlow(canvas);
    }
    if (showPoliticalOverlay && showProvinceOverlay) {
      paintFactionBorders(canvas);
    }
    if (showProvinceNamesLayer) {
      paintProvinceNames(canvas);
      paintSeaZoneNames(canvas);
    }
    paintCapitals(canvas);
    paintTowns(canvas);
    paintWarpZones(canvas);
    paintCivilianTileMarkers(canvas);
    paintFleetTileMarkers(canvas);
    if (session.hoveredTileX != null && session.hoveredTileY != null) {
      paintSelector(canvas);
    }
    if (selectedTileKey != null) {
      paintSelectedTile(canvas);
    }
    final multiSecondary = secondaryHighlightTileKeys;
    if (multiSecondary != null && multiSecondary.isNotEmpty) {
      paintSecondaryHighlightTiles(canvas, multiSecondary);
    } else if (secondaryHighlightTileKey != null) {
      paintSecondaryHighlightTile(canvas);
    }
    if (validTileKeys != null && validTileKeys!.isNotEmpty) {
      paintValidTilesGlow(canvas);
    }
  }
}

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

extension CtRegionMapRenderCoreBaseTilesHelpers on CtRegionMapComponent {
  /// Wang interior upper-base tile for land: `sea_plains` for plains (and
  /// feature terrains on plains) or `sea_desert` for desert. Used for L1 cells
  /// and for the opaque grass under transparent `tile_plains_*` overlays.
  void drawLandInteriorUpperBaseForTerrain(
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

  Paint landBaseImagePaint({
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
        Color.fromRGBO(0, 0, 0, RegionMapPalette.fogOverlayOpacity),
        BlendMode.darken,
      );
    }
    return paint;
  }

  RegionMapComponentCornerValues getCornerValues(
    int x,
    int y,
    bool Function(CellViewData) predicate,
  ) {
    final nwCell = getCellAt(x - 1, y - 1);
    final nCell = getCellAt(x, y - 1);
    final neCell = getCellAt(x + 1, y - 1);
    final wCell = getCellAt(x - 1, y);
    final cCell = getCellAt(x, y);
    final eCell = getCellAt(x + 1, y);
    final swCell = getCellAt(x - 1, y + 1);
    final sCell = getCellAt(x, y + 1);
    final seCell = getCellAt(x + 1, y + 1);

    bool test(CellViewData? c) => c != null && predicate(c);

    final centerMatches = cCell != null && predicate(cCell);
    final hasNW = centerMatches && (test(nwCell) || test(nCell) || test(wCell));
    final hasNE = centerMatches && (test(neCell) || test(nCell) || test(eCell));
    final hasSW = centerMatches && (test(swCell) || test(sCell) || test(wCell));
    final hasSE = centerMatches && (test(seCell) || test(sCell) || test(eCell));

    final allSame = (hasNW == hasNE && hasNE == hasSW && hasSW == hasSE);
    final same = allSame && (!hasNW || centerMatches);
    final value = hasNW;

    return RegionMapComponentCornerValues(
      nw: hasNW,
      ne: hasNE,
      sw: hasSW,
      se: hasSE,
      same: same,
      value: value,
    );
  }

  RegionMapComponentCornerValues getCoastlineCornerValues(int x, int y) {
    final nwCell = getCellAt(x - 1, y - 1);
    final nCell = getCellAt(x, y - 1);
    final neCell = getCellAt(x + 1, y - 1);
    final wCell = getCellAt(x - 1, y);
    final eCell = getCellAt(x + 1, y);
    final swCell = getCellAt(x - 1, y + 1);
    final sCell = getCellAt(x, y + 1);
    final seCell = getCellAt(x + 1, y + 1);

    bool isLand(CellViewData? c) => c != null && !c.isSea;

    final hasNW = isLand(nwCell) || isLand(nCell) || isLand(wCell);
    final hasNE = isLand(neCell) || isLand(nCell) || isLand(eCell);
    final hasSW = isLand(swCell) || isLand(sCell) || isLand(wCell);
    final hasSE = isLand(seCell) || isLand(sCell) || isLand(eCell);

    final allSame = (hasNW == hasNE && hasNE == hasSW && hasSW == hasSE);
    final same = allSame && !hasNW;

    return RegionMapComponentCornerValues(
      nw: hasNW,
      ne: hasNE,
      sw: hasSW,
      se: hasSE,
      same: same,
      value: hasNW,
    );
  }

  bool drawTile(
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
      regionMapComponentLifecycleLog.w(
        'No tile found in ${tileset.name} for corners: NW=$nw, NE=$ne, SW=$sw, SE=$se',
      );
      return false;
    }

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
    return true;
  }

  CellViewData? getCellAt(int x, int y) {
    if (x < 0 || x >= region.width || y < 0 || y >= region.height) return null;
    return region.cellAt(x, y);
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
