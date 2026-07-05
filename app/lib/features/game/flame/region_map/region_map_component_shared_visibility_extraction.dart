part of 'region_map_component.dart';

/// On-map resource icon width/height in world/cell coordinates.
///
/// SPEC/ui/map-widget.md § Resource Icons: **one quarter** of [cellSize], capped
/// at [ResourceIconCache.iconSize] so 64×64 source assets are **never upscaled**
/// on the map (scale down only).
double resourceIconDisplaySizePx(double cellSize) {
  final quarter = cellSize * 0.25;
  return quarter < ResourceIconCache.iconSize
      ? quarter
      : ResourceIconCache.iconSize;
}

double extractionIndicatorDisplaySizePx(double resourceIconDisplaySizePx) {
  return math.min(
    ResourceIconCache.iconSize,
    resourceIconDisplaySizePx + _kExtractionIndicatorSizeBoostPx,
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
  final stepX = indicatorSize * (1.0 - _kExtractionIndicatorOverlapFactor);
  final startX = iconRect.right + _kExtractionIndicatorStartInsetXPx;
  final top = iconRect.bottom - indicatorSize;
  return List<Rect>.generate(
    units,
    (i) =>
        Rect.fromLTWH(startX + (i * stepX), top, indicatorSize, indicatorSize),
    growable: false,
  );
}

/// Paints per-tile extraction throughput as **filled discs** (not commodity
/// sprites). Effective slots use [_kMapSelectionGold] (transported toward
/// capital); blocked slots use [_kExtractionDiscBlockedBrown].
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
  for (var i = 0; i < indicatorRects.length; i++) {
    final isEffective = i < effectiveCount;
    final fillColor = isEffective
        ? _kMapSelectionGold
        : _kExtractionDiscBlockedBrown;
    final discPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = fillColor;
    if (fogFilter != null) {
      discPaint.colorFilter = fogFilter;
    }
    final r = indicatorRects[i];
    final radius = r.shortestSide * 0.5;
    canvas.drawCircle(r.center, radius, discPaint);
  }
}
