import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:flutter/material.dart';

import '../tilesets/tilesets.dart';
import 'region_map_component.dart';
import 'region_map_component_shared_corner_values.dart';
import 'region_map_component_shared_palette.dart';
import 'region_map_component_shared_visibility.dart';
import 'region_map_component_support.dart';

/// Wang interior upper-base tile for land: `sea_plains` for plains (and
/// feature terrains on plains) or `sea_desert` for desert. Used for L1 cells
/// and for the opaque grass under transparent `tile_plains_*` overlays.
void regionMapComponentDrawLandInteriorUpperBaseForTerrain(
  CtRegionMapComponent component,
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

Paint regionMapComponentLandBaseImagePaint(
  CtRegionMapComponent component, {
  required TerrainType terrain,
  required TileVisibility tileVisibility,
}) {
  final paint = Paint();
  if (shouldApplyFogToLandBase(
    visibilityMode: component.visibilityMode,
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

RegionMapComponentCornerValues regionMapComponentGetCornerValues(
  CtRegionMapComponent component,
  int x,
  int y,
  bool Function(CellViewData) predicate,
) {
  final nwCell = regionMapComponentGetCellAt(component, x - 1, y - 1);
  final nCell = regionMapComponentGetCellAt(component, x, y - 1);
  final neCell = regionMapComponentGetCellAt(component, x + 1, y - 1);
  final wCell = regionMapComponentGetCellAt(component, x - 1, y);
  final cCell = regionMapComponentGetCellAt(component, x, y);
  final eCell = regionMapComponentGetCellAt(component, x + 1, y);
  final swCell = regionMapComponentGetCellAt(component, x - 1, y + 1);
  final sCell = regionMapComponentGetCellAt(component, x, y + 1);
  final seCell = regionMapComponentGetCellAt(component, x + 1, y + 1);

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

RegionMapComponentCornerValues regionMapComponentGetCoastlineCornerValues(
  CtRegionMapComponent component,
  int x,
  int y,
) {
  final nwCell = regionMapComponentGetCellAt(component, x - 1, y - 1);
  final nCell = regionMapComponentGetCellAt(component, x, y - 1);
  final neCell = regionMapComponentGetCellAt(component, x + 1, y - 1);
  final wCell = regionMapComponentGetCellAt(component, x - 1, y);
  final eCell = regionMapComponentGetCellAt(component, x + 1, y);
  final swCell = regionMapComponentGetCellAt(component, x - 1, y + 1);
  final sCell = regionMapComponentGetCellAt(component, x, y + 1);
  final seCell = regionMapComponentGetCellAt(component, x + 1, y + 1);

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

bool regionMapComponentDrawTile(
  CtRegionMapComponent component,
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
  final dstRect = Rect.fromLTWH(left, top, component.cellSize, component.cellSize);
  canvas.drawImageRect(tileset.image, srcRect, dstRect, Paint());

  if (component.visibilityMode == CtMapVisibilityMode.playerConstrained &&
      regionMapComponentVisibilityForTerrain(component, cell) ==
          TileVisibility.fogged) {
    canvas.drawRect(
      dstRect,
      Paint()..color = Color.fromRGBO(0, 0, 0, RegionMapPalette.fogOverlayOpacity),
    );
  }
  return true;
}

CellViewData? regionMapComponentGetCellAt(
  CtRegionMapComponent component,
  int x,
  int y,
) {
  if (x < 0 || x >= component.region.width || y < 0 || y >= component.region.height) {
    return null;
  }
  return component.region.cellAt(x, y);
}

Paint regionMapComponentResourceOverlayPaintForCell(
  CtRegionMapComponent component,
  CellViewData cell,
) {
  final paint = Paint();
  if (component.visibilityMode == CtMapVisibilityMode.playerConstrained &&
      regionMapComponentVisibilityForTerrain(component, cell) ==
          TileVisibility.fogged) {
    paint.colorFilter = ColorFilter.mode(
      RegionMapPalette.mapHoverSelectorIdle.withValues(
        alpha: RegionMapPalette.foggedResourceIconModulateAlpha,
      ),
      BlendMode.modulate,
    );
  }
  return paint;
}

bool regionMapComponentIsPlainTerrainAtDesertTransitionWangCell(
  CtRegionMapComponent component,
  CellViewData cell,
) {
  final nearDesertCorner = regionMapComponentGetCornerValues(
    component,
    cell.x,
    cell.y,
    (c) => !c.isSea && c.terrainType == TerrainType.desert,
  );
  return !nearDesertCorner.same && nearDesertCorner.value;
}
