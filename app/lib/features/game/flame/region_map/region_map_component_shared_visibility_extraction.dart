import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../caches/resource_icon_cache.dart';
import 'region_map_component_shared_palette.dart';

double extractionIndicatorDisplaySizePx(double resourceIconDisplaySizePx) {
  return math.min(
    ResourceIconCache.iconSize,
    resourceIconDisplaySizePx + RegionMapPalette.extractionIndicatorSizeBoostPx,
  );
}

List<Rect> extractionIndicatorRectsForIconRect({
  required Rect iconRect,
  required int units,
}) {
  if (units <= 0) {
    return const <Rect>[];
  }
  final indicatorSize = extractionIndicatorDisplaySizePx(iconRect.width);
  final stepX =
      indicatorSize * (1.0 - RegionMapPalette.extractionIndicatorOverlapFactor);
  final startX =
      iconRect.right + RegionMapPalette.extractionIndicatorStartInsetXPx;
  final top = iconRect.bottom - indicatorSize;
  return List<Rect>.generate(
    units,
    (i) =>
        Rect.fromLTWH(startX + (i * stepX), top, indicatorSize, indicatorSize),
    growable: false,
  );
}

/// Paints per-tile extraction throughput as **filled discs with dark stroke**
/// (not commodity sprites). Effective slots use [RegionMapPalette.mapSelectionGold]
/// (transported toward capital); blocked slots use
/// [RegionMapPalette.extractionDiscBlockedBrown]. Paint order: fill then stroke.
/// [fogCompatibleOverlayPaint] supplies the same fog `ColorFilter` as resource
/// icons when the tile is fogged.
///
/// SPEC/ui/map-widget.md § Per-tile extraction throughput indicators;
/// SPEC/program/map-region-map-render.md (`_paintOverlay` extraction discs).
void paintResourceExtractionDiscIndicators({
  required Canvas canvas,
  required List<Rect> indicatorRects,
  required int effectiveCount,
  required Paint fogCompatibleOverlayPaint,
}) {
  if (indicatorRects.isEmpty) {
    return;
  }
  final fogFilter = fogCompatibleOverlayPaint.colorFilter;
  final strokeWidth = RegionMapPalette.extractionDiscStrokeWidthPx;
  for (var i = 0; i < indicatorRects.length; i++) {
    final isEffective = i < effectiveCount;
    final fillColor = isEffective
        ? RegionMapPalette.mapSelectionGold
        : RegionMapPalette.extractionDiscBlockedBrown;
    final r = indicatorRects[i];
    final center = r.center;
    final radius = r.shortestSide * 0.5;

    final fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = fillColor;
    if (fogFilter != null) {
      fillPaint.colorFilter = fogFilter;
    }
    canvas.drawCircle(center, radius, fillPaint);

    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = RegionMapPalette.extractionDiscStrokeColor;
    if (fogFilter != null) {
      strokePaint.colorFilter = fogFilter;
    }
    final strokeRadius = radius - strokeWidth * 0.5;
    if (strokeRadius > 0) {
      canvas.drawCircle(center, strokeRadius, strokePaint);
    }
  }
}
