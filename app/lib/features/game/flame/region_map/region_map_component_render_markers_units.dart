import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../caches/civilian_icon_cache.dart';
import '../caches/fleet_icon_cache.dart';
import 'region_map_boundary_visibility.dart';
import 'region_map_component.dart';

extension CtRegionMapRenderMarkersUnitsCivilian on CtRegionMapComponent {
  void paintCivilianTileMarkers(Canvas canvas) {
    if (region.civilianTileMarkers.isEmpty) return;
    for (final marker in region.civilianTileMarkers) {
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
      final left = marker.x * cellSize;
      final top = marker.y * cellSize;
      final selected = selectedCivilianTileKey == marker.tileKey;
      final blinkAlpha = selected
          ? RegionMapPalette.hoveredProvinceGlowOpacityMid +
                RegionMapPalette.hoveredProvinceGlowOpacityAmplitude *
                    math.sin(
                      session.hoverAnimationT * RegionMapPalette.hoveredProvinceGlowAngularFrequency,
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
        final dstRect = Rect.fromLTWH(left, top, cellSize, cellSize);
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
        canvas.drawRect(Rect.fromLTWH(left, top, cellSize, cellSize), fallback);
      }

      if (marker.stackCount <= 1) continue;
      final badgeRadius = math.max(7.0, cellSize * 0.2);
      final badgeCx = left + cellSize - badgeRadius;
      final badgeCy = top + cellSize - badgeRadius;
      final badgeFill = Paint()
        ..style = PaintingStyle.fill
        ..color = Colors.black.withValues(alpha: blinkAlpha.clamp(0.35, 1.0));
      canvas.drawCircle(Offset(badgeCx, badgeCy), badgeRadius, badgeFill);
      final badgeText = TextPainter(
        text: TextSpan(
          text: '${marker.stackCount}',
          style: TextStyle(
            color: Colors.white,
            fontSize: math.max(8.0, cellSize * 0.24),
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

extension CtRegionMapRenderMarkersUnitsFleet on CtRegionMapComponent {
  void paintFleetTileMarkers(Canvas canvas) {
    if (region.fleetTileMarkers.isEmpty) {
      return;
    }
    for (final marker in region.fleetTileMarkers) {
      if (marker.x < 0 ||
          marker.x >= region.width ||
          marker.y < 0 ||
          marker.y >= region.height) {
        continue;
      }
      final left = marker.x * cellSize;
      final top = marker.y * cellSize;
      final icon = fleetIconCache.getIcon();
      if (icon != null) {
        final srcRect = Rect.fromLTWH(
          0,
          0,
          FleetIconCache.iconSize,
          FleetIconCache.iconSize,
        );
        final dstRect = Rect.fromLTWH(left, top, cellSize, cellSize);
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
        canvas.drawRect(Rect.fromLTWH(left, top, cellSize, cellSize), fallback);
      }

      if (marker.stackCount <= 1) {
        continue;
      }
      final badgeRadius = math.max(7.0, cellSize * 0.2);
      final badgeCx = left + cellSize - badgeRadius;
      final badgeCy = top + cellSize - badgeRadius;
      final badgeFill = Paint()
        ..style = PaintingStyle.fill
        ..color = Colors.black;
      canvas.drawCircle(Offset(badgeCx, badgeCy), badgeRadius, badgeFill);
      final badgeText = TextPainter(
        text: TextSpan(
          text: '${marker.stackCount}',
          style: TextStyle(
            color: Colors.white,
            fontSize: math.max(8.0, cellSize * 0.24),
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
