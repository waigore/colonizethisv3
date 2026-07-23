import 'package:flutter/material.dart';

import 'region_map_boundary_visibility.dart';
import 'region_map_component.dart';
import 'region_map_component_shared_palette.dart';
import 'region_map_component_support.dart';
import 'region_map_province_overlay_geometry.dart';

void regionMapComponentPaintCapitals(
  CtRegionMapComponent component,
  Canvas canvas,
) {
  final fill = Paint()..style = PaintingStyle.fill;
  final stroke = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = kCapitalMarkerRingStrokeWidth
    ..color = Colors.black;
  for (final cap in component.region.capitalMarkers) {
    final cell = component.region.cellAt(cap.x, cap.y);
    if (regionMapSkipPointMarkerOnCell(
      playerConstrainedVisibility:
          component.visibilityMode == CtMapVisibilityMode.playerConstrained,
      cellVisibility: regionMapComponentVisibilityForTerrain(component, cell),
    )) {
      continue;
    }
    final cx = cap.x * component.cellSize + component.cellSize / 2;
    final cy = cap.y * component.cellSize + component.cellSize / 2;
    fill.color = RegionMapPalette.mapSelectionGold;
    canvas.drawCircle(Offset(cx, cy), 6, fill);
    canvas.drawCircle(Offset(cx, cy), 6, stroke);
  }
}
