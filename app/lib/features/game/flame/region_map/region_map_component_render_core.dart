import 'package:colonizethis_data/colonizethis_data.dart';

import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:flutter/material.dart';
import '../tilesets/tilesets.dart';
import 'region_map_component.dart';
import 'region_map_component_render_core_land_sea.dart';
import 'region_map_component_render_core_overlays.dart';
import 'region_map_component_render_markers_army.dart';
import 'region_map_component_render_markers_selection.dart';
import 'region_map_component_render_markers_settlements.dart';
import 'region_map_component_render_markers_units.dart';
import 'region_map_component_render_player_territory_outline.dart';
import 'region_map_component_render_political.dart';
import 'region_map_component_render_political_borders.dart';
import 'region_map_component_render_political_sea_labels.dart';
import 'region_map_component_shared_corner_values.dart';

extension CtRegionMapRenderOrchestrator on CtRegionMapComponent {
  void renderRegionMap(Canvas canvas) {
    paintTiles(canvas);
    if (showProvinceOwnershipTint) {
      paintGreatPowerLandOwnershipTint(canvas);
    }
    if (showCapitalLinkDisconnectedHighlight) {
      paintCapitalLinkDisconnectedHighlight(canvas);
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
    paintArmyTileMarkers(canvas);
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
        regionMapComponentVisibilityForTerrain(this, cell) ==
            TileVisibility.fogged) {
      canvas.drawRect(
        dstRect,
        Paint()
          ..color = Color.fromRGBO(0, 0, 0, RegionMapPalette.fogOverlayOpacity),
      );
    }
    return true;
  }

  CellViewData? getCellAt(int x, int y) {
    if (x < 0 || x >= region.width || y < 0 || y >= region.height) return null;
    return region.cellAt(x, y);
  }
}
