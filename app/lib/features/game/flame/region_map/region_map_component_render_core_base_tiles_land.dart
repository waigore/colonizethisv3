import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:flutter/material.dart';

import '../tilesets/tilesets.dart';
import 'region_map_component.dart';
import 'region_map_component_render_core_base_tiles_helpers.dart';
import 'region_map_component_shared_palette.dart';
import 'region_map_component_shared_visibility.dart';
import 'region_map_component_support.dart';

void regionMapComponentPaintLandBaseCell(
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

  final terrain = cell.terrainType;
  if (terrain == null) {
    throw StateError('Cell has no terrain type: $cell');
  }
  regionMapComponentPaintLandBaseTile(component, canvas, cell);
}

void regionMapComponentPaintLandBaseTile(
  CtRegionMapComponent component,
  Canvas canvas,
  CellViewData cell,
) {
  final left = cell.x * component.cellSize;
  final top = cell.y * component.cellSize;
  final terrainNullable = cell.terrainType;
  if (terrainNullable == null) {
    throw StateError('Cell has no terrain type: $cell');
  }
  final terrain = terrainNullable;

  final isPlains =
      terrain == TerrainType.plains || regionMapComponentIsFeatureTerrain(terrain);
  final isDesert = terrain == TerrainType.desert;

  final nearDesertCorner = regionMapComponentGetCornerValues(
    component,
    cell.x,
    cell.y,
    (c) => !c.isSea && c.terrainType == TerrainType.desert,
  );
  final nearPlainsCorner = regionMapComponentGetCornerValues(
    component,
    cell.x,
    cell.y,
    (c) =>
        !c.isSea &&
        (c.terrainType == TerrainType.plains ||
            (c.terrainType != null &&
                regionMapComponentIsFeatureTerrain(c.terrainType!))),
  );

  if (isPlains && !nearDesertCorner.same && nearDesertCorner.value) {
    final tileset = terrainTilesetCache.getPlainsDesertTileset();
    if (tileset == null) {
      throw StateError(
        'Plains desert tileset is null - terrain tileset failed to load',
      );
    }
    regionMapComponentDrawTile(
      component,
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
    regionMapComponentDrawTile(
      component,
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
        !regionMapComponentIsPlainTerrainAtDesertTransitionWangCell(
          component,
          cell,
        )) {
      final dstRect = Rect.fromLTWH(left, top, component.cellSize, component.cellSize);
      regionMapComponentDrawLandInteriorUpperBaseForTerrain(
        component,
        canvas,
        landTerrain: TerrainType.plains,
        dstRect: dstRect,
        paint: Paint(),
      );
      return;
    }
  }

  final dstRect = Rect.fromLTWH(left, top, component.cellSize, component.cellSize);
  final paint = regionMapComponentLandBaseImagePaint(
    component,
    terrain: terrain,
    tileVisibility: regionMapComponentVisibilityForTerrain(component, cell),
  );
  regionMapComponentDrawLandInteriorUpperBaseForTerrain(
    component,
    canvas,
    landTerrain: terrain,
    dstRect: dstRect,
    paint: paint,
  );
}
