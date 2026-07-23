import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:flutter/material.dart';

import '../caches/town_icon_cache.dart';
import 'region_map_boundary_visibility.dart';
import 'region_map_component.dart';
import 'region_map_component_shared_palette.dart';
import 'region_map_component_support.dart';

void regionMapComponentPaintTowns(
  CtRegionMapComponent component,
  Canvas canvas,
) {
  if (!townIconCache.isLoaded) return;

  for (final town in component.region.townMarkers) {
    final cell = component.region.cellAt(town.x, town.y);
    if (regionMapSkipPointMarkerOnCell(
      playerConstrainedVisibility:
          component.visibilityMode == CtMapVisibilityMode.playerConstrained,
      cellVisibility: regionMapComponentVisibilityForTerrain(component, cell),
    )) {
      continue;
    }
    regionMapComponentPaintTownIconAt(
      component,
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

  for (final town in component.region.townMarkers) {
    if (!town.isPort) continue;
    final px = town.portIconX;
    final py = town.portIconY;
    if (px == null || py == null) continue;
    final portCell = component.region.cellAt(px, py);
    if (regionMapSkipPointMarkerOnCell(
      playerConstrainedVisibility:
          component.visibilityMode == CtMapVisibilityMode.playerConstrained,
      cellVisibility: regionMapComponentVisibilityForTerrain(
        component,
        portCell,
      ),
    )) {
      continue;
    }
    regionMapComponentPaintTownIconAt(
      component,
      canvas,
      cell: portCell,
      cx: px,
      cy: py,
      icon: TownIconCache.portIconId,
    );
  }
}

void regionMapComponentPaintTownIconAt(
  CtRegionMapComponent component,
  Canvas canvas, {
  required CellViewData cell,
  required int cx,
  required int cy,
  required String icon,
  int? townDevelopmentLevel,
}) {
  final uiImage = townIconCache.getIcon(icon);
  if (uiImage == null) return;

  final centerX = cx * component.cellSize + component.cellSize / 2;
  final centerY = cy * component.cellSize + component.cellSize / 2;
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
  if (component.visibilityMode == CtMapVisibilityMode.playerConstrained &&
      regionMapComponentVisibilityForTerrain(component, cell) ==
          TileVisibility.fogged) {
    paint.color = Color.fromRGBO(0, 0, 0, RegionMapPalette.fogOverlayOpacity);
  }
  canvas.drawImageRect(uiImage, srcRect, dstRect, paint);
}
