import 'package:flutter/material.dart';

import 'region_map_boundary_visibility.dart';
import 'region_map_component.dart';
import 'region_map_component_shared_palette.dart';
import 'region_map_component_support.dart';
import 'region_map_province_overlay_geometry.dart';

void regionMapComponentPaintFactionBorders(
  CtRegionMapComponent component,
  Canvas canvas,
) {
  final paint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = kProvinceOverlayPoliticalStrokeWidth
    ..color = RegionMapPalette.factionPoliticalBorderColor;
  for (var y = 0; y < component.region.height; y++) {
    for (var x = 0; x < component.region.width; x++) {
      final cell = component.region.cellAt(x, y);
      if (cell.isSea) continue;
      final owner = cell.ownerFactionId ?? '';
      if (x + 1 < component.region.width) {
        final right = component.region.cellAt(x + 1, y);
        if (!right.isSea && (right.ownerFactionId ?? '') != owner) {
          if (regionMapDrawBoundaryBetweenAdjacentCells(
            gateByUnrevealedTiles: component.gateMapBoundariesByVisibility,
            visibilityA: regionMapComponentVisibilityForTerrain(component, cell),
            visibilityB: regionMapComponentVisibilityForTerrain(component, right),
          )) {
            final xEdge = (x + 1) * component.cellSize;
            canvas.drawLine(
              Offset(xEdge, y * component.cellSize),
              Offset(xEdge, (y + 1) * component.cellSize),
              paint,
            );
          }
        }
      }
      if (y + 1 < component.region.height) {
        final bottom = component.region.cellAt(x, y + 1);
        if (!bottom.isSea && (bottom.ownerFactionId ?? '') != owner) {
          if (regionMapDrawBoundaryBetweenAdjacentCells(
            gateByUnrevealedTiles: component.gateMapBoundariesByVisibility,
            visibilityA: regionMapComponentVisibilityForTerrain(component, cell),
            visibilityB: regionMapComponentVisibilityForTerrain(component, bottom),
          )) {
            final yEdge = (y + 1) * component.cellSize;
            canvas.drawLine(
              Offset(x * component.cellSize, yEdge),
              Offset((x + 1) * component.cellSize, yEdge),
              paint,
            );
          }
        }
      }
    }
  }
}
