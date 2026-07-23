import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../caches/civilian_icon_cache.dart';
import 'region_map_boundary_visibility.dart';
import 'region_map_component.dart';
import 'region_map_component_shared_palette.dart';
import 'region_map_component_support.dart';

void regionMapComponentPaintCivilianTileMarkers(
  CtRegionMapComponent component,
  Canvas canvas,
) {
  if (component.region.civilianTileMarkers.isEmpty) return;
  for (final marker in component.region.civilianTileMarkers) {
    if (marker.x < 0 ||
        marker.x >= component.region.width ||
        marker.y < 0 ||
        marker.y >= component.region.height) {
      continue;
    }
    final cell = component.region.cellAt(marker.x, marker.y);
    if (regionMapSkipPointMarkerOnCell(
      playerConstrainedVisibility:
          component.visibilityMode == CtMapVisibilityMode.playerConstrained,
      cellVisibility: regionMapComponentVisibilityForTerrain(component, cell),
    )) {
      continue;
    }
    final left = marker.x * component.cellSize;
    final top = marker.y * component.cellSize;
    final selected = component.selectedCivilianTileKey == marker.tileKey;
    final blinkAlpha = selected
        ? RegionMapPalette.hoveredProvinceGlowOpacityMid +
              RegionMapPalette.hoveredProvinceGlowOpacityAmplitude *
                  math.sin(
                    component.session.hoverAnimationT *
                        RegionMapPalette.hoveredProvinceGlowAngularFrequency,
                  )
        : 1.0;

    final icon = civilianIconCache.getIcon(
      unitType: marker.representativeUnitType,
      grayscale: marker.representativeIsAssigned,
    );
    if (icon != null) {
      final srcRect = Rect.fromLTWH(
        0,
        0,
        CivilianIconCache.iconSize,
        CivilianIconCache.iconSize,
      );
      final dstRect = Rect.fromLTWH(
        left,
        top,
        component.cellSize,
        component.cellSize,
      );
      final paint = Paint();
      final alpha = blinkAlpha.clamp(0.35, 1.0);
      if (marker.representativeIsAssigned) {
        paint.colorFilter = const ColorFilter.matrix(<double>[
          0.2126,
          0.7152,
          0.0722,
          0,
          0,
          0.2126,
          0.7152,
          0.0722,
          0,
          0,
          0.2126,
          0.7152,
          0.0722,
          0,
          0,
          0,
          0,
          0,
          1,
          0,
        ]);
      }
      paint.color = Colors.white.withValues(alpha: alpha);
      canvas.drawImageRect(icon, srcRect, dstRect, paint);
    } else {
      final fallback = Paint()
        ..style = PaintingStyle.fill
        ..color = const Color(
          0xFF495057,
        ).withValues(alpha: blinkAlpha.clamp(0.35, 1.0));
      canvas.drawRect(
        Rect.fromLTWH(left, top, component.cellSize, component.cellSize),
        fallback,
      );
    }

    if (marker.stackCount <= 1) continue;
    final badgeRadius = math.max(7.0, component.cellSize * 0.2);
    final badgeCx = left + component.cellSize - badgeRadius;
    final badgeCy = top + component.cellSize - badgeRadius;
    final badgeFill = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.black.withValues(alpha: blinkAlpha.clamp(0.35, 1.0));
    canvas.drawCircle(Offset(badgeCx, badgeCy), badgeRadius, badgeFill);
    final badgeText = TextPainter(
      text: TextSpan(
        text: '${marker.stackCount}',
        style: TextStyle(
          color: Colors.white,
          fontSize: math.max(8.0, component.cellSize * 0.24),
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    badgeText.paint(
      canvas,
      Offset(badgeCx - badgeText.width / 2, badgeCy - badgeText.height / 2),
    );
  }
}
