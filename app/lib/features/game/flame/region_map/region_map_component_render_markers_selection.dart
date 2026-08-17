import 'dart:math' as math;
import 'package:colonizethis_app/core/utils/prefixed_id.dart';
import 'package:flutter/material.dart';
import 'region_map_component.dart';
import 'region_map_province_overlay_geometry.dart';

extension CtRegionMapRenderMarkersSelection on CtRegionMapComponent {
  void paintValidTilesGlow(Canvas canvas) {
    final keys = validTileKeys!;
    final t = session.hoverAnimationT;
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
    for (var y = 0; y < region.height; y++) {
      for (var x = 0; x < region.width; x++) {
        final cell = region.cellAt(x, y);
        final tileKey = '${region.regionId}|${cell.regionCellId}|$x|$y';
        if (!keys.contains(tileKey)) continue;
        final left = x * cellSize;
        final top = y * cellSize;
        canvas.drawRect(Rect.fromLTWH(left, top, cellSize, cellSize), paint);
      }
    }
  }

  void paintLastTurnPulse(Canvas canvas) {
    final tileKey = lastTurnPulseTileKey!;
    final t = session.hoverAnimationT;
    final opacity =
        RegionMapPalette.validWorkTargetGlowOpacityBase +
        RegionMapPalette.validWorkTargetGlowOpacityAmplitude *
            (RegionMapPalette.sinNormalizedMid +
                RegionMapPalette.sinNormalizedMid *
                    math.sin(
                      t * RegionMapPalette.hoveredProvinceGlowAngularFrequency,
                    ));
    _paintTileOutlineRing(
      canvas,
      tileKey: tileKey,
      color: RegionMapPalette.lastTurnPulseColor.withValues(alpha: opacity),
      strokeWidth: kMapValidTileTargetStrokeWidth,
    );
  }

  void paintSelectedTile(Canvas canvas) {
    _paintTileOutlineRing(
      canvas,
      tileKey: selectedTileKey!,
      color: RegionMapPalette.mapSelectedHighlightOrange,
      strokeWidth: kMapSelectedTileStrokeWidth,
    );
  }

  void paintSecondaryHighlightTile(Canvas canvas) {
    _paintTileOutlineRing(
      canvas,
      tileKey: secondaryHighlightTileKey!,
      color: RegionMapPalette.mapSecondarySelectionCyan,
      strokeWidth: kMapSecondaryHighlightStrokeWidth,
    );
  }

  void paintSecondaryHighlightTiles(Canvas canvas, Set<String> tileKeys) {
    for (final tileKey in tileKeys) {
      _paintTileOutlineRing(
        canvas,
        tileKey: tileKey,
        color: RegionMapPalette.mapSecondarySelectionCyan,
        strokeWidth: kMapSecondaryHighlightStrokeWidth,
      );
    }
  }

  void _paintTileOutlineRing(
    Canvas canvas, {
    required String tileKey,
    required Color color,
    required double strokeWidth,
  }) {
    final parsed = tryParseTileKey(tileKey);
    if (parsed == null || parsed.regionId != region.regionId) return;
    final x = parsed.x;
    final y = parsed.y;
    if (x < 0 || x >= region.width || y < 0 || y >= region.height) return;
    final left = x * cellSize;
    final top = y * cellSize;
    final rect = Rect.fromLTWH(left, top, cellSize, cellSize);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = color;
    canvas.drawRect(rect, paint);
  }

  void paintSelector(Canvas canvas) {
    final x = session.hoveredTileX!;
    final y = session.hoveredTileY!;
    final bounce =
        RegionMapPalette.hoverSelectorBounceBaseline +
        RegionMapPalette.hoverSelectorBounceAmplitude *
            math.sin(session.hoverAnimationT * RegionMapPalette.hoveredProvinceGlowAngularFrequency);
    final cx = x * cellSize + cellSize / 2;
    final cy = y * cellSize + cellSize / 2;
    final half = (cellSize / 2 - 2.0) * bounce;
    final left = cx - half;
    final top = cy - half;
    final size = half * 2;
    final rect = Rect.fromLTWH(left, top, size, size);
    final color = (validTileKeys != null && validTileKeys!.isNotEmpty)
        ? RegionMapPalette.mapSelectedHighlightOrange
        : RegionMapPalette.mapHoverSelectorIdle;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = kMapHoverSelectorStrokeWidth
      ..color = color;
    canvas.drawRect(rect, paint);
  }
}
