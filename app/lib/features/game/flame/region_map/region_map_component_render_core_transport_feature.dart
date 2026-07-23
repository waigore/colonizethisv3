import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:flutter/material.dart';

import '../tilesets/tilesets.dart';
import 'region_map_component.dart';
import 'region_map_component_render_core_base_tiles_helpers.dart';
import 'region_map_component_shared_palette.dart';
import 'region_map_component_shared_visibility.dart';
import 'region_map_component_support.dart';

/// Interior L1 plains resource decals (`tile_plains_*`) must stack above
/// transport (SPEC/ui/map-widget.md § Base overlay paint order). Skips
/// plains↔desert Wang cells — same gating as [regionMapComponentPaintLandBaseTile].
void regionMapComponentPaintL1PlainsInteriorResourceVariantOverlays(
  CtRegionMapComponent component,
  Canvas canvas,
) {
  for (final cell in component.region.cells) {
    if (cell.isSea) continue;
    if (component.visibilityMode == CtMapVisibilityMode.playerConstrained &&
        regionMapComponentVisibilityForTerrain(component, cell) ==
            TileVisibility.unrevealed) {
      continue;
    }
    if (cell.terrainType != TerrainType.plains) continue;
    if (regionMapComponentIsPlainTerrainAtDesertTransitionWangCell(
      component,
      cell,
    )) {
      continue;
    }

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
    final left = cell.x * component.cellSize;
    final top = cell.y * component.cellSize;
    final dstRect = Rect.fromLTWH(left, top, component.cellSize, component.cellSize);
    final overlayPaint = Paint();
    if (shouldApplyFogToInteriorPlainsVariantOverlay(
      visibilityMode: component.visibilityMode,
      tileVisibility: regionMapComponentVisibilityForTerrain(component, cell),
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

void regionMapComponentPaintTransportOverlayTiles(
  CtRegionMapComponent component,
  Canvas canvas,
) {
  if (!shouldRenderTransportOverlay(
    baseLayerDisplayMode: component.baseLayerDisplayMode,
  )) {
    return;
  }
  if (!transportOverlayTilesetCache.isLoaded) {
    return;
  }
  for (final cell in component.region.cells) {
    final tileVisibility = regionMapComponentVisibilityForTerrain(component, cell);
    if (!shouldPaintTransportOverlayForCell(
      cell: cell,
      visibilityMode: component.visibilityMode,
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
      getCellAt: (x, y) => regionMapComponentGetCellAt(component, x, y),
    );
    final srcRect = tileset.tileRectForMask(mask);
    if (srcRect == null) {
      regionMapComponentLifecycleLog.w(
        'Transport tile missing for family=$family mask=$mask',
      );
      continue;
    }
    final tileLeft = cell.x * component.cellSize;
    final tileTop = cell.y * component.cellSize;
    final dstRect = Rect.fromLTWH(
      tileLeft,
      tileTop,
      component.cellSize,
      component.cellSize,
    );
    canvas.drawImageRect(
      tileset.image,
      srcRect,
      dstRect,
      regionMapComponentResourceOverlayPaintForCell(component, cell),
    );
  }
}

void regionMapComponentPaintFeatureCell(
  CtRegionMapComponent component,
  Canvas canvas,
  CellViewData cell,
) {
  final left = cell.x * component.cellSize;
  final top = cell.y * component.cellSize;

  if (component.visibilityMode == CtMapVisibilityMode.playerConstrained &&
      regionMapComponentVisibilityForTerrain(component, cell) ==
          TileVisibility.unrevealed) {
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
    regionMapComponentLifecycleLog.w(
      'Feature overlay tile missing for key=$overlayTileKey terrain=$terrain; '
      'skipping feature overlay for cell (${cell.x}, ${cell.y})',
    );
    return;
  }

  final paint = Paint();
  if (shouldApplyFogToFeatureOverlay(
    visibilityMode: component.visibilityMode,
    tileVisibility: regionMapComponentVisibilityForTerrain(component, cell),
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
  final dstRect = Rect.fromLTWH(left, top, component.cellSize, component.cellSize);
  canvas.drawImageRect(standaloneTile.image, srcRect, dstRect, paint);
}
