import 'dart:math' as math;
import 'package:colonizethis_data/colonizethis_data.dart';

import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:flutter/material.dart';
import '../caches/resource_icon_cache.dart';
import '../tilesets/tilesets.dart';
import 'region_map_component.dart';
import 'region_map_component_render_core.dart';
import 'package:colonizethis_world/colonizethis_world.dart'
    show PlayerView, resourceIdVisibleInPlayerView;

extension CtRegionMapRenderCoreTransportFeature on CtRegionMapComponent {
  void paintL1PlainsInteriorResourceVariantOverlays(Canvas canvas) {
    for (final cell in region.cells) {
      if (cell.isSea) continue;
      if (visibilityMode == CtMapVisibilityMode.playerConstrained &&
          regionMapComponentVisibilityForTerrain(this, cell) ==
              TileVisibility.unrevealed) {
        continue;
      }
      if (cell.terrainType != TerrainType.plains) continue;
      if (isPlainTerrainAtDesertTransitionWangCell(cell)) continue;

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
        tileVisibility: regionMapComponentVisibilityForTerrain(this, cell),
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

  bool isPlainTerrainAtDesertTransitionWangCell(CellViewData cell) {
    final nearDesertCorner = getCornerValues(
      cell.x,
      cell.y,
      (c) => !c.isSea && c.terrainType == TerrainType.desert,
    );
    return !nearDesertCorner.same && nearDesertCorner.value;
  }

  void paintTransportOverlayTiles(Canvas canvas) {
    if (!shouldRenderTransportOverlay(flags: mapBaseLayerFlags) ||
        !transportOverlayTilesetCache.isLoaded) {
      return;
    }
    for (final cell in region.cells) {
      final tileVisibility = regionMapComponentVisibilityForTerrain(this, cell);
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
        getCellAt: getCellAt,
      );
      final srcRect = tileset.tileRectForMask(mask);
      if (srcRect == null) {
        regionMapComponentLifecycleLog.w(
          'Transport tile missing for family=$family mask=$mask',
        );
        continue;
      }
      final tileLeft = cell.x * cellSize;
      final tileTop = cell.y * cellSize;
      final dstRect = Rect.fromLTWH(tileLeft, tileTop, cellSize, cellSize);
      canvas.drawImageRect(
        tileset.image,
        srcRect,
        dstRect,
        resourceOverlayPaintForCell(cell),
      );
    }
  }

  void paintFeatureCell(Canvas canvas, CellViewData cell) {
    final left = cell.x * cellSize;
    final top = cell.y * cellSize;

    if (visibilityMode == CtMapVisibilityMode.playerConstrained &&
        regionMapComponentVisibilityForTerrain(this, cell) ==
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
      visibilityMode: visibilityMode,
      tileVisibility: regionMapComponentVisibilityForTerrain(this, cell),
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
    final dstRect = Rect.fromLTWH(left, top, cellSize, cellSize);
    canvas.drawImageRect(standaloneTile.image, srcRect, dstRect, paint);
  }

  Paint resourceOverlayPaintForCell(CellViewData cell) {
    final paint = Paint();
    if (visibilityMode == CtMapVisibilityMode.playerConstrained &&
        regionMapComponentVisibilityForTerrain(this, cell) ==
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
}

extension CtRegionMapRenderCoreOverlays on CtRegionMapComponent {
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

  void paintOverlay(Canvas canvas) {
    final showResources = shouldShowResourceIcons(flags: mapBaseLayerFlags);
    final showExtractionIndicators = shouldShowExtractionUnitIndicators(
      flags: mapBaseLayerFlags,
    );
    final showImprovementLabels = shouldShowImprovementLabels(
      flags: mapBaseLayerFlags,
    );
    for (final cell in region.cells) {
      if (cell.isSea) continue;
      if (visibilityMode == CtMapVisibilityMode.playerConstrained &&
          regionMapComponentVisibilityForTerrain(this, cell) ==
              TileVisibility.unrevealed) {
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
          final paint = resourceOverlayPaintForCell(cell);
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
              fogCompatibleOverlayPaint: resourceOverlayPaintForCell(cell),
            );
          }
        }
      }
    }

    if (showImprovementLabels) {
      for (final cell in region.cells) {
        if (cell.isSea) continue;
        if (visibilityMode == CtMapVisibilityMode.playerConstrained &&
            regionMapComponentVisibilityForTerrain(this, cell) ==
                TileVisibility.unrevealed) {
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
