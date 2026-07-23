import 'dart:math' as math;
import 'package:colonizethis_app/core/utils/prefixed_id.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:flutter/material.dart';
import '../caches/civilian_icon_cache.dart';
import '../caches/fleet_icon_cache.dart';
import '../caches/town_icon_cache.dart';
import '../render/warp_zone_edge_geometry.dart';
import 'region_map_boundary_visibility.dart';
import 'region_map_component.dart';
import 'region_map_component_shared_palette.dart';
import 'region_map_component_support.dart';
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

extension CtRegionMapRenderMarkersSettlementsCapitals on CtRegionMapComponent {
  void paintCapitals(Canvas canvas) {
    final fill = Paint()..style = PaintingStyle.fill;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = kCapitalMarkerRingStrokeWidth
      ..color = Colors.black;
    for (final cap in region.capitalMarkers) {
      final cell = region.cellAt(cap.x, cap.y);
      if (regionMapSkipPointMarkerOnCell(
        playerConstrainedVisibility:
            visibilityMode == CtMapVisibilityMode.playerConstrained,
        cellVisibility: regionMapComponentVisibilityForTerrain(this, cell),
      )) {
        continue;
      }
      final cx = cap.x * cellSize + cellSize / 2;
      final cy = cap.y * cellSize + cellSize / 2;
      fill.color = RegionMapPalette.mapSelectionGold;
      canvas.drawCircle(Offset(cx, cy), 6, fill);
      canvas.drawCircle(Offset(cx, cy), 6, stroke);
    }
  }
}

extension CtRegionMapRenderMarkersSettlementsTowns on CtRegionMapComponent {
  void paintTowns(Canvas canvas) {
    if (!townIconCache.isLoaded) return;

    for (final town in region.townMarkers) {
      final cell = region.cellAt(town.x, town.y);
      if (regionMapSkipPointMarkerOnCell(
        playerConstrainedVisibility:
            visibilityMode == CtMapVisibilityMode.playerConstrained,
        cellVisibility: regionMapComponentVisibilityForTerrain(this, cell),
      )) {
        continue;
      }
      _paintTownIconAt(
        canvas,
        cell: cell,
        cx: town.x,
        cy: town.y,
        icon: TownIconCache.townIconIdForMarker(
          townIconStyle: town.townIconStyle,
          townDevelopmentLevel: town.townDevelopmentLevel,
        ),
        townDevelopmentLevel: town.townDevelopmentLevel,
      );
    }

    for (final town in region.townMarkers) {
      if (!town.isPort) continue;
      final px = town.portIconX;
      final py = town.portIconY;
      if (px == null || py == null) continue;
      final portCell = region.cellAt(px, py);
      if (regionMapSkipPointMarkerOnCell(
        playerConstrainedVisibility:
            visibilityMode == CtMapVisibilityMode.playerConstrained,
        cellVisibility: regionMapComponentVisibilityForTerrain(this, portCell),
      )) {
        continue;
      }
      _paintTownIconAt(
        canvas,
        cell: portCell,
        cx: px,
        cy: py,
        icon: TownIconCache.portIconId,
      );
    }
  }

  void _paintTownIconAt(
    Canvas canvas, {
    required CellViewData cell,
    required int cx,
    required int cy,
    required String icon,
    int? townDevelopmentLevel,
  }) {
    final uiImage = townIconCache.getIcon(icon);
    if (uiImage == null) return;

    final centerX = cx * cellSize + cellSize / 2;
    final centerY = cy * cellSize + cellSize / 2;
    final iconSize = icon == TownIconCache.portIconId
        ? TownIconCache.portIconSize
        : TownIconCache.townIconDestinationSize(townDevelopmentLevel ?? 4);
    final halfIcon = iconSize / 2;

    final srcRect = Rect.fromLTWH(
      0,
      0,
      uiImage.width.toDouble(),
      uiImage.height.toDouble(),
    );
    final dstRect = Rect.fromLTWH(
      centerX - halfIcon,
      centerY - halfIcon,
      iconSize,
      iconSize,
    );

    var paint = Paint();
    if (visibilityMode == CtMapVisibilityMode.playerConstrained &&
        regionMapComponentVisibilityForTerrain(this, cell) == TileVisibility.fogged) {
      paint.color = Color.fromRGBO(0, 0, 0, RegionMapPalette.fogOverlayOpacity);
    }
    canvas.drawImageRect(uiImage, srcRect, dstRect, paint);
  }
}

extension CtRegionMapRenderMarkersSettlementsWarp on CtRegionMapComponent {
  Set<(int x, int y)> _warpTileCoordsForZones(Set<String> warpSeaZoneIds) {
    final warpTiles = <(int x, int y)>{};
    for (var y = 0; y < region.height; y++) {
      for (var x = 0; x < region.width; x++) {
        final cell = region.cellAt(x, y);
        if (warpSeaZoneIds.contains(cell.regionCellId)) {
          warpTiles.add((x, y));
        }
      }
    }
    return warpTiles;
  }

  void paintWarpZones(Canvas canvas) {
    final warpSeaZoneIds = region.warpMarkers.map((m) => m.seaZoneId).toSet();
    if (warpSeaZoneIds.isEmpty) return;

    final warpTiles = _warpTileCoordsForZones(warpSeaZoneIds);

    final glowOuter = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = kWarpZoneGlowOuterStrokeWidth
      ..color = RegionMapPalette.mapSelectionGold.withValues(alpha: RegionMapPalette.warpZoneOuterGlowAlpha);
    final glowInner = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = kWarpZoneGlowInnerStrokeWidth
      ..color = RegionMapPalette.warpZoneInnerHighlight;

    for (final (x, y) in warpTiles) {
      final cell = region.cellAt(x, y);
      // Defense in depth: [warpTiles] is built from warp sea-zone ids, but keep
      // this guard so a stale set or future caller change cannot paint edges
      // from non-warp cells.
      if (!warpSeaZoneIds.contains(cell.regionCellId)) {
        continue;
      }

      _paintWarpZoneEdge(
        canvas,
        x: x,
        y: y,
        cell: cell,
        warpSeaZoneIds: warpSeaZoneIds,
        dx: 1,
        dy: 0,
        glowOuter: glowOuter,
        glowInner: glowInner,
      );
      _paintWarpZoneEdge(
        canvas,
        x: x,
        y: y,
        cell: cell,
        warpSeaZoneIds: warpSeaZoneIds,
        dx: 0,
        dy: 1,
        glowOuter: glowOuter,
        glowInner: glowInner,
      );
      _paintWarpZoneEdge(
        canvas,
        x: x,
        y: y,
        cell: cell,
        warpSeaZoneIds: warpSeaZoneIds,
        dx: -1,
        dy: 0,
        glowOuter: glowOuter,
        glowInner: glowInner,
      );
      _paintWarpZoneEdge(
        canvas,
        x: x,
        y: y,
        cell: cell,
        warpSeaZoneIds: warpSeaZoneIds,
        dx: 0,
        dy: -1,
        glowOuter: glowOuter,
        glowInner: glowInner,
      );
    }
  }

  void _paintWarpZoneEdge(
    Canvas canvas, {
    required int x,
    required int y,
    required CellViewData cell,
    required Set<String> warpSeaZoneIds,
    required int dx,
    required int dy,
    required Paint glowOuter,
    required Paint glowInner,
  }) {
    final nx = x + dx;
    final ny = y + dy;
    if (nx < 0 || nx >= region.width || ny < 0 || ny >= region.height) {
      return;
    }

    final neighbor = region.cellAt(nx, ny);
    if (warpSeaZoneIds.contains(neighbor.regionCellId)) {
      return;
    }

    if (!regionMapDrawBoundaryBetweenAdjacentCells(
      gateByUnrevealedTiles: gateMapBoundariesByVisibility,
      visibilityA: regionMapComponentVisibilityForTerrain(this, cell),
      visibilityB: regionMapComponentVisibilityForTerrain(this, neighbor),
    )) {
      return;
    }

    final segment = warpZoneGlowLineForDirection(
      cellSize: cellSize,
      x: x,
      y: y,
      dx: dx,
      dy: dy,
    );
    canvas.drawLine(segment.$1, segment.$2, glowOuter);
    canvas.drawLine(segment.$1, segment.$2, glowInner);
  }
}

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
