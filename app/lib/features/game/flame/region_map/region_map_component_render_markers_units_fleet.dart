import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../caches/fleet_icon_cache.dart';
import 'region_map_component.dart';

void regionMapComponentPaintFleetTileMarkers(
  CtRegionMapComponent component,
  Canvas canvas,
) {
  if (component.region.fleetTileMarkers.isEmpty) {
    return;
  }
  for (final marker in component.region.fleetTileMarkers) {
    if (marker.x < 0 ||
        marker.x >= component.region.width ||
        marker.y < 0 ||
        marker.y >= component.region.height) {
      continue;
    }
    final left = marker.x * component.cellSize;
    final top = marker.y * component.cellSize;
    final icon = fleetIconCache.getIcon();
    if (icon != null) {
      final srcRect = Rect.fromLTWH(
        0,
        0,
        FleetIconCache.iconSize,
        FleetIconCache.iconSize,
      );
      final dstRect = Rect.fromLTWH(
        left,
        top,
        component.cellSize,
        component.cellSize,
      );
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
        ..color = const Color(0xFF1c3d5a);
      canvas.drawRect(
        Rect.fromLTWH(left, top, component.cellSize, component.cellSize),
        fallback,
      );
    }

    if (marker.stackCount <= 1) {
      continue;
    }
    final badgeRadius = math.max(7.0, component.cellSize * 0.2);
    final badgeCx = left + component.cellSize - badgeRadius;
    final badgeCy = top + component.cellSize - badgeRadius;
    final badgeFill = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.black;
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
