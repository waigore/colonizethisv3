import 'dart:math' as math;

import 'package:colonizethis_logic/colonizethis_logic.dart'
    show resourceIdVisibleInPlayerView;
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:flutter/material.dart';

import '../caches/resource_icon_cache.dart';
import 'region_map_component.dart';
import 'region_map_component_render_core_base_tiles_helpers.dart';
import 'region_map_component_shared_palette.dart';
import 'region_map_component_shared_visibility.dart';
import 'region_map_component_support.dart';

String? regionMapComponentResourceIdForMapIcon(
  CtRegionMapComponent component,
  CellViewData cell,
) {
  final raw = cell.resourceId;
  if (raw == null) return null;
  if (component.visibilityMode != CtMapVisibilityMode.playerConstrained) {
    return raw;
  }
  final view = component.playerViewForResources;
  if (view == null) {
    throw StateError(
      'CtRegionMapComponent: playerConstrained requires playerViewForResources',
    );
  }
  final tileKey =
      '${component.region.regionId}|${cell.regionCellId}|${cell.x}|${cell.y}';
  return resourceIdVisibleInPlayerView(view, tileKey, raw);
}

void regionMapComponentPaintOverlay(
  CtRegionMapComponent component,
  Canvas canvas,
) {
  final showResources =
      component.baseLayerDisplayMode != BaseLayerDisplayMode.terrainOnly;
  final showExtractionIndicators = shouldShowExtractionUnitIndicators(
    baseLayerDisplayMode: component.baseLayerDisplayMode,
  );
  final showImprovementLabels =
      component.baseLayerDisplayMode ==
          BaseLayerDisplayMode.terrainAndResourcesImprovementLabels ||
      component.baseLayerDisplayMode ==
          BaseLayerDisplayMode.terrainAndResourcesImprovementsRoads;
  for (final cell in component.region.cells) {
    if (cell.isSea) continue;
    if (component.visibilityMode == CtMapVisibilityMode.playerConstrained &&
        regionMapComponentVisibilityForTerrain(component, cell) ==
            TileVisibility.unrevealed) {
      continue;
    }

    final resourceForIcon = regionMapComponentResourceIdForMapIcon(component, cell);
    if (showResources && resourceForIcon != null) {
      final icon = resourceIconCache.getIcon(resourceForIcon);
      if (icon != null) {
        final assetSize = ResourceIconCache.iconSize;
        final displaySize = resourceIconDisplaySizePx(component.cellSize);
        final tileLeft = cell.x * component.cellSize;
        final tileTop = cell.y * component.cellSize;

        final iconX = tileLeft;
        final iconY = tileTop + component.cellSize - displaySize;

        final dstRect = Rect.fromLTWH(iconX, iconY, displaySize, displaySize);
        final srcRect = Rect.fromLTWH(0, 0, assetSize, assetSize);
        final paint = regionMapComponentResourceOverlayPaintForCell(component, cell);
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
            fogCompatibleOverlayPaint: regionMapComponentResourceOverlayPaintForCell(
              component,
              cell,
            ),
          );
        }
      }
    }
  }

  if (showImprovementLabels) {
    for (final cell in component.region.cells) {
      if (cell.isSea) continue;
      if (component.visibilityMode == CtMapVisibilityMode.playerConstrained &&
          regionMapComponentVisibilityForTerrain(component, cell) ==
              TileVisibility.unrevealed) {
        continue;
      }
      final imp = cell.improvementLevel ?? 0;
      if (imp <= 0) continue;
      regionMapComponentPaintTileCornerLabel(
        component,
        canvas,
        cell,
        'I$imp',
        alignEnd: false,
      );
    }
  }
}

void regionMapComponentPaintTileCornerLabel(
  CtRegionMapComponent component,
  Canvas canvas,
  CellViewData cell,
  String text, {
  required bool alignEnd,
}) {
  final tileLeft = cell.x * component.cellSize;
  final tileTop = cell.y * component.cellSize;
  final pad = math.max(1.0, component.cellSize * 0.06);
  final fontSize = math.max(8.0, component.cellSize * 0.25);
  final textPainter = TextPainter(textDirection: TextDirection.ltr);
  textPainter.text = TextSpan(
    text: text,
    style: TextStyle(
      color: Colors.black,
      fontSize: fontSize,
      fontWeight: FontWeight.w600,
    ),
  );
  textPainter.layout(maxWidth: component.cellSize - 2 * pad);
  final y = tileTop + pad;
  final x = alignEnd
      ? tileLeft + component.cellSize - pad - textPainter.width
      : tileLeft + pad;
  textPainter.paint(canvas, Offset(x, y));
}
