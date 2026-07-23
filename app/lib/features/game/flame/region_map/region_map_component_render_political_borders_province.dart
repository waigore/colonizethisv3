import 'dart:math' as math;

import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:flutter/material.dart';

import '../render/gp_ownership_tint_layer.dart';
import 'region_map_boundary_visibility.dart';
import 'region_map_component.dart';
import 'region_map_component_shared_palette.dart';
import 'region_map_component_support.dart';
import 'region_map_province_overlay_geometry.dart';

void regionMapComponentPaintHoveredProvinceGlow(
  CtRegionMapComponent component,
  Canvas canvas,
) {
  final t = component.session.hoverAnimationT;
  final opacity =
      RegionMapPalette.hoveredProvinceGlowOpacityMid +
      RegionMapPalette.hoveredProvinceGlowOpacityAmplitude *
          math.sin(t * RegionMapPalette.hoveredProvinceGlowAngularFrequency);
  final coastInset = provinceOverlayLandSeaInsetPx(
    cellSizePx: component.cellSize,
    topologyStrokeWidth: kProvinceOverlayTopologyStrokeWidth,
  );
  final paint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = kProvinceOverlayHoverGlowStrokeWidth
    ..color = RegionMapPalette.mapHoverSelectorIdle.withValues(alpha: opacity);
  final provinceId = component.session.hoveredProvinceId!;
  for (var y = 0; y < component.region.height; y++) {
    for (var x = 0; x < component.region.width; x++) {
      final cell = component.region.cellAt(x, y);
      if (cell.regionCellId != provinceId) continue;
      if (x + 1 < component.region.width) {
        final right = component.region.cellAt(x + 1, y);
        if (right.regionCellId != provinceId) {
          if (regionMapDrawBoundaryBetweenAdjacentCells(
            gateByUnrevealedTiles: component.gateMapBoundariesByVisibility,
            visibilityA: regionMapComponentVisibilityForTerrain(component, cell),
            visibilityB: regionMapComponentVisibilityForTerrain(component, right),
          )) {
            final xEdge = verticalProvinceTopologyEdgeX(
              left: cell,
              right: right,
              cellSizePx: component.cellSize,
              leftTileX: x,
              coastInsetPx: coastInset,
            );
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
        if (bottom.regionCellId != provinceId) {
          if (regionMapDrawBoundaryBetweenAdjacentCells(
            gateByUnrevealedTiles: component.gateMapBoundariesByVisibility,
            visibilityA: regionMapComponentVisibilityForTerrain(component, cell),
            visibilityB: regionMapComponentVisibilityForTerrain(component, bottom),
          )) {
            final yEdge = horizontalProvinceTopologyEdgeY(
              top: cell,
              bottom: bottom,
              cellSizePx: component.cellSize,
              topTileY: y,
              coastInsetPx: coastInset,
            );
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

void regionMapComponentPaintGreatPowerLandOwnershipTint(
  CtRegionMapComponent component,
  Canvas canvas,
) {
  paintGreatPowerOwnershipTintLayer(
    canvas: canvas,
    region: component.region,
    cellSize: component.cellSize,
    honorUnrevealedTiles:
        component.visibilityMode == CtMapVisibilityMode.playerConstrained,
  );
}

void regionMapComponentPaintProvinceBorders(
  CtRegionMapComponent component,
  Canvas canvas,
) {
  final coastInset = provinceOverlayLandSeaInsetPx(
    cellSizePx: component.cellSize,
    topologyStrokeWidth: kProvinceOverlayTopologyStrokeWidth,
  );
  final paint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = kProvinceOverlayTopologyStrokeWidth
    ..color = RegionMapPalette.provinceBorderLandColor;
  for (var y = 0; y < component.region.height; y++) {
    for (var x = 0; x < component.region.width; x++) {
      final cell = component.region.cellAt(x, y);
      if (x + 1 < component.region.width) {
        final right = component.region.cellAt(x + 1, y);
        if (cell.regionCellId != right.regionCellId) {
          if (regionMapDrawBoundaryBetweenAdjacentCells(
            gateByUnrevealedTiles: component.gateMapBoundariesByVisibility,
            visibilityA: regionMapComponentVisibilityForTerrain(component, cell),
            visibilityB: regionMapComponentVisibilityForTerrain(component, right),
          )) {
            paint.color = regionMapComponentProvinceBorderColor(cell, right);
            final xEdge = verticalProvinceTopologyEdgeX(
              left: cell,
              right: right,
              cellSizePx: component.cellSize,
              leftTileX: x,
              coastInsetPx: coastInset,
            );
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
        if (cell.regionCellId != bottom.regionCellId) {
          if (regionMapDrawBoundaryBetweenAdjacentCells(
            gateByUnrevealedTiles: component.gateMapBoundariesByVisibility,
            visibilityA: regionMapComponentVisibilityForTerrain(component, cell),
            visibilityB: regionMapComponentVisibilityForTerrain(component, bottom),
          )) {
            paint.color = regionMapComponentProvinceBorderColor(cell, bottom);
            final yEdge = horizontalProvinceTopologyEdgeY(
              top: cell,
              bottom: bottom,
              cellSizePx: component.cellSize,
              topTileY: y,
              coastInsetPx: coastInset,
            );
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

Color regionMapComponentProvinceBorderColor(CellViewData a, CellViewData b) {
  final aIsSea = a.isSea;
  final bIsSea = b.isSea;
  if (aIsSea && bIsSea) return RegionMapPalette.provinceBorderSeaZoneColor;
  if (!aIsSea && !bIsSea) return RegionMapPalette.provinceBorderLandColor;
  return RegionMapPalette.provinceBorderSeaLandColor;
}
