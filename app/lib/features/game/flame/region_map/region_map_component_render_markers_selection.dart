import 'dart:math' as math;

import 'package:colonizethis_app/core/utils/prefixed_id.dart';
import 'package:flutter/material.dart';

import 'region_map_component.dart';
import 'region_map_component_shared_palette.dart';
import 'region_map_province_overlay_geometry.dart';

void regionMapComponentPaintValidTilesGlow(
  CtRegionMapComponent component,
  Canvas canvas,
) {
  final keys = component.validTileKeys!;
  final t = component.session.hoverAnimationT;
  final opacity =
      RegionMapPalette.validWorkTargetGlowOpacityBase +
      RegionMapPalette.validWorkTargetGlowOpacityAmplitude *
          (RegionMapPalette.sinNormalizedMid +
              RegionMapPalette.sinNormalizedMid *
                  math.sin(t * RegionMapPalette.validWorkTargetGlowTimeScale));
  final paint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = kMapValidTileTargetStrokeWidth
    ..color = RegionMapPalette.validWorkTargetStrokeYellow.withValues(alpha: opacity);
  for (var y = 0; y < component.region.height; y++) {
    for (var x = 0; x < component.region.width; x++) {
      final cell = component.region.cellAt(x, y);
      final tileKey = '${component.region.regionId}|${cell.regionCellId}|$x|$y';
      if (!keys.contains(tileKey)) continue;
      final left = x * component.cellSize;
      final top = y * component.cellSize;
      canvas.drawRect(
        Rect.fromLTWH(left, top, component.cellSize, component.cellSize),
        paint,
      );
    }
  }
}

void regionMapComponentPaintSelectedTile(
  CtRegionMapComponent component,
  Canvas canvas,
) {
  regionMapComponentPaintTileOutlineRing(
    component,
    canvas,
    tileKey: component.selectedTileKey!,
    color: RegionMapPalette.mapSelectedHighlightOrange,
    strokeWidth: kMapSelectedTileStrokeWidth,
  );
}

void regionMapComponentPaintSecondaryHighlightTile(
  CtRegionMapComponent component,
  Canvas canvas,
) {
  regionMapComponentPaintTileOutlineRing(
    component,
    canvas,
    tileKey: component.secondaryHighlightTileKey!,
    color: RegionMapPalette.mapSecondarySelectionCyan,
    strokeWidth: kMapSecondaryHighlightStrokeWidth,
  );
}

void regionMapComponentPaintSecondaryHighlightTiles(
  CtRegionMapComponent component,
  Canvas canvas,
  Set<String> tileKeys,
) {
  for (final tileKey in tileKeys) {
    regionMapComponentPaintTileOutlineRing(
      component,
      canvas,
      tileKey: tileKey,
      color: RegionMapPalette.mapSecondarySelectionCyan,
      strokeWidth: kMapSecondaryHighlightStrokeWidth,
    );
  }
}

void regionMapComponentPaintTileOutlineRing(
  CtRegionMapComponent component,
  Canvas canvas, {
  required String tileKey,
  required Color color,
  required double strokeWidth,
}) {
  final parsed = tryParseTileKey(tileKey);
  if (parsed == null || parsed.regionId != component.region.regionId) return;
  final x = parsed.x;
  final y = parsed.y;
  if (x < 0 ||
      x >= component.region.width ||
      y < 0 ||
      y >= component.region.height) {
    return;
  }
  final left = x * component.cellSize;
  final top = y * component.cellSize;
  final rect = Rect.fromLTWH(left, top, component.cellSize, component.cellSize);
  final paint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = strokeWidth
    ..color = color;
  canvas.drawRect(rect, paint);
}

void regionMapComponentPaintSelector(
  CtRegionMapComponent component,
  Canvas canvas,
) {
  final x = component.session.hoveredTileX!;
  final y = component.session.hoveredTileY!;
  final bounce =
      RegionMapPalette.hoverSelectorBounceBaseline +
      RegionMapPalette.hoverSelectorBounceAmplitude *
          math.sin(
            component.session.hoverAnimationT *
                RegionMapPalette.hoveredProvinceGlowAngularFrequency,
          );
  final cx = x * component.cellSize + component.cellSize / 2;
  final cy = y * component.cellSize + component.cellSize / 2;
  final half = (component.cellSize / 2 - 2.0) * bounce;
  final left = cx - half;
  final top = cy - half;
  final size = half * 2;
  final rect = Rect.fromLTWH(left, top, size, size);
  final color = (component.validTileKeys != null &&
          component.validTileKeys!.isNotEmpty)
      ? RegionMapPalette.mapSelectedHighlightOrange
      : RegionMapPalette.mapHoverSelectorIdle;
  final paint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = kMapHoverSelectorStrokeWidth
    ..color = color;
  canvas.drawRect(rect, paint);
}
