import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:flutter/material.dart';

import '../tilesets/tilesets.dart';
import 'region_map_component.dart';
import 'region_map_component_render_core_base_tiles_helpers.dart';
import 'region_map_component_shared_palette.dart';
import 'region_map_component_shared_visibility.dart';
import 'region_map_component_support.dart';

void regionMapComponentPaintSeaCell(
  CtRegionMapComponent component,
  Canvas canvas,
  CellViewData cell,
) {
  final left = cell.x * component.cellSize;
  final top = cell.y * component.cellSize;

  if (component.visibilityMode == CtMapVisibilityMode.playerConstrained &&
      regionMapComponentVisibilityForTerrain(component, cell) ==
          TileVisibility.unrevealed) {
    final paint = Paint()..color = Colors.black;
    canvas.drawRect(
      Rect.fromLTWH(left, top, component.cellSize, component.cellSize),
      paint,
    );
    return;
  }

  final landCorner = regionMapComponentGetCoastlineCornerValues(
    component,
    cell.x,
    cell.y,
  );
  final dominantLandType = regionMapComponentDominantAdjacentLandBase(
    cell.x,
    cell.y,
    (x, y) => regionMapComponentGetCellAt(component, x, y),
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
      final dstRect = Rect.fromLTWH(
        left,
        top,
        component.cellSize,
        component.cellSize,
      );
      canvas.drawImageRect(tileset.image, srcRect, dstRect, Paint());
      if (component.visibilityMode == CtMapVisibilityMode.playerConstrained &&
          regionMapComponentVisibilityForTerrain(component, cell) ==
              TileVisibility.fogged) {
        canvas.drawRect(
          dstRect,
          Paint()..color = Color.fromRGBO(0, 0, 0, RegionMapPalette.fogOverlayOpacity),
        );
      }
    }
    return;
  }

  regionMapComponentDrawTile(
    component,
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
