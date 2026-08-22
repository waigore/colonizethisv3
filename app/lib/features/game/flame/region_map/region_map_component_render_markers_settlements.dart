import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:flutter/material.dart';
import '../caches/town_icon_cache.dart';
import 'region_map_boundary_visibility.dart';
import 'region_map_component.dart';
import 'region_map_province_overlay_geometry.dart';

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
      final fortLevel = town.mapVisibleFortLevel;
      if (fortLevel != null) {
        _paintFortIconAt(
          canvas,
          cell: cell,
          cx: town.x,
          cy: town.y,
          fortLevel: fortLevel,
        );
      }
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
        regionMapComponentVisibilityForTerrain(this, cell) ==
            TileVisibility.fogged) {
      paint.color = Color.fromRGBO(0, 0, 0, RegionMapPalette.fogOverlayOpacity);
    }
    canvas.drawImageRect(uiImage, srcRect, dstRect, paint);
  }

  void _paintFortIconAt(
    Canvas canvas, {
    required CellViewData cell,
    required int cx,
    required int cy,
    required int fortLevel,
  }) {
    final icon = TownIconCache.fortIconId(fortLevel);
    final uiImage = townIconCache.getIcon(icon);
    if (uiImage == null) return;

    final centerX =
        cx * cellSize + cellSize / 2 + TownIconCache.fortIconOffsetDx;
    final centerY =
        cy * cellSize + cellSize / 2 + TownIconCache.fortIconOffsetDy;
    final iconSize = TownIconCache.fortIconSize;
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
        regionMapComponentVisibilityForTerrain(this, cell) ==
            TileVisibility.fogged) {
      paint.color = Color.fromRGBO(0, 0, 0, RegionMapPalette.fogOverlayOpacity);
    }
    canvas.drawImageRect(uiImage, srcRect, dstRect, paint);
  }
}
