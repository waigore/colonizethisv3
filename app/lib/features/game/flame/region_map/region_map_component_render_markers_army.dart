import 'dart:math' as math;
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:flutter/material.dart';

import '../caches/province_label_icon_cache.dart';
import 'region_map_boundary_visibility.dart';
import 'region_map_component.dart';

extension CtRegionMapRenderMarkersUnitsArmy on CtRegionMapComponent {
  void paintArmyTileMarkers(Canvas canvas) {
    if (region.armyTileMarkers.isEmpty) {
      return;
    }
    for (final marker in region.armyTileMarkers) {
      if (marker.x < 0 ||
          marker.x >= region.width ||
          marker.y < 0 ||
          marker.y >= region.height) {
        continue;
      }
      final cell = region.cellAt(marker.x, marker.y);
      if (regionMapSkipPointMarkerOnCell(
        playerConstrainedVisibility:
            visibilityMode == CtMapVisibilityMode.playerConstrained,
        cellVisibility: regionMapComponentVisibilityForTerrain(this, cell),
      )) {
        continue;
      }
      final origin = ArmyTileMarkerLayout.originFrac * cellSize;
      final left = marker.x * cellSize + origin;
      final top = marker.y * cellSize + origin;
      final size = cellSize - origin;
      final icon = provinceLabelIconCache.getIcon('map_presence_regiment');
      if (icon != null) {
        final srcRect = Rect.fromLTWH(
          0,
          0,
          ProvinceLabelIconCache.iconSize,
          ProvinceLabelIconCache.iconSize,
        );
        final dstRect = Rect.fromLTWH(left, top, size, size);
        final paint = Paint();
        if (marker.renderGrayscale) {
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
        canvas.drawImageRect(icon, srcRect, dstRect, paint);
      } else {
        final fallback = Paint()
          ..style = PaintingStyle.fill
          ..color = const Color(0xFF6B4F2A);
        canvas.drawRect(Rect.fromLTWH(left, top, size, size), fallback);
      }

      if (marker.stackCount <= 1) {
        continue;
      }
      final badgeRadius = math.max(6.0, size * 0.28);
      final badgeCx = left + size - badgeRadius;
      final badgeCy = top + size - badgeRadius;
      final badgeFill = Paint()
        ..style = PaintingStyle.fill
        ..color = Colors.black;
      canvas.drawCircle(Offset(badgeCx, badgeCy), badgeRadius, badgeFill);
      final badgeText = TextPainter(
        text: TextSpan(
          text: '${marker.stackCount}',
          style: TextStyle(
            color: Colors.white,
            fontSize: math.max(8.0, size * 0.32),
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
}
