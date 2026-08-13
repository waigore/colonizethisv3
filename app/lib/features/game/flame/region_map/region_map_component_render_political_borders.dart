import 'dart:math' as math;
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:flutter/material.dart';
import '../render/capital_link_disconnected_highlight_layer.dart';
import '../render/gp_ownership_tint_layer.dart';
import 'region_map_boundary_visibility.dart';
import 'region_map_component.dart';
import 'region_map_province_overlay_geometry.dart';

extension CtRegionMapRenderPoliticalBordersProvince on CtRegionMapComponent {
  void paintHoveredProvinceGlow(Canvas canvas) {
    final t = session.hoverAnimationT;
    final opacity =
        RegionMapPalette.hoveredProvinceGlowOpacityMid +
        RegionMapPalette.hoveredProvinceGlowOpacityAmplitude *
            math.sin(t * RegionMapPalette.hoveredProvinceGlowAngularFrequency);
    final coastInset = provinceOverlayLandSeaInsetPx(
      cellSizePx: cellSize,
      topologyStrokeWidth: kProvinceOverlayTopologyStrokeWidth,
    );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = kProvinceOverlayHoverGlowStrokeWidth
      ..color = RegionMapPalette.mapHoverSelectorIdle.withValues(alpha: opacity);
    final provinceId = session.hoveredProvinceId!;
    for (var y = 0; y < region.height; y++) {
      for (var x = 0; x < region.width; x++) {
        final cell = region.cellAt(x, y);
        if (cell.regionCellId != provinceId) continue;
        if (x + 1 < region.width) {
          final right = region.cellAt(x + 1, y);
          if (right.regionCellId != provinceId) {
            if (regionMapDrawBoundaryBetweenAdjacentCells(
              gateByUnrevealedTiles: gateMapBoundariesByVisibility,
              visibilityA: regionMapComponentVisibilityForTerrain(this, cell),
              visibilityB: regionMapComponentVisibilityForTerrain(this, right),
            )) {
              final xEdge = verticalProvinceTopologyEdgeX(
                left: cell,
                right: right,
                cellSizePx: cellSize,
                leftTileX: x,
                coastInsetPx: coastInset,
              );
              canvas.drawLine(
                Offset(xEdge, y * cellSize),
                Offset(xEdge, (y + 1) * cellSize),
                paint,
              );
            }
          }
        }
        if (y + 1 < region.height) {
          final bottom = region.cellAt(x, y + 1);
          if (bottom.regionCellId != provinceId) {
            if (regionMapDrawBoundaryBetweenAdjacentCells(
              gateByUnrevealedTiles: gateMapBoundariesByVisibility,
              visibilityA: regionMapComponentVisibilityForTerrain(this, cell),
              visibilityB: regionMapComponentVisibilityForTerrain(this, bottom),
            )) {
              final yEdge = horizontalProvinceTopologyEdgeY(
                top: cell,
                bottom: bottom,
                cellSizePx: cellSize,
                topTileY: y,
                coastInsetPx: coastInset,
              );
              canvas.drawLine(
                Offset(x * cellSize, yEdge),
                Offset((x + 1) * cellSize, yEdge),
                paint,
              );
            }
          }
        }
      }
    }
  }

  void paintGreatPowerLandOwnershipTint(Canvas canvas) {
    paintGreatPowerOwnershipTintLayer(
      canvas: canvas,
      region: region,
      cellSize: cellSize,
      honorUnrevealedTiles:
          visibilityMode == CtMapVisibilityMode.playerConstrained,
    );
  }

  void paintCapitalLinkDisconnectedHighlight(Canvas canvas) {
    paintCapitalLinkDisconnectedHighlightLayer(
      canvas: canvas,
      region: region,
      cellSize: cellSize,
      honorUnrevealedTiles:
          visibilityMode == CtMapVisibilityMode.playerConstrained,
    );
  }

  void paintProvinceBorders(Canvas canvas) {
    final coastInset = provinceOverlayLandSeaInsetPx(
      cellSizePx: cellSize,
      topologyStrokeWidth: kProvinceOverlayTopologyStrokeWidth,
    );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = kProvinceOverlayTopologyStrokeWidth
      ..color = RegionMapPalette.provinceBorderLandColor;
    for (var y = 0; y < region.height; y++) {
      for (var x = 0; x < region.width; x++) {
        final cell = region.cellAt(x, y);
        if (x + 1 < region.width) {
          final right = region.cellAt(x + 1, y);
          if (cell.regionCellId != right.regionCellId) {
            if (regionMapDrawBoundaryBetweenAdjacentCells(
              gateByUnrevealedTiles: gateMapBoundariesByVisibility,
              visibilityA: regionMapComponentVisibilityForTerrain(this, cell),
              visibilityB: regionMapComponentVisibilityForTerrain(this, right),
            )) {
              paint.color = _provinceBorderColor(cell, right);
              final xEdge = verticalProvinceTopologyEdgeX(
                left: cell,
                right: right,
                cellSizePx: cellSize,
                leftTileX: x,
                coastInsetPx: coastInset,
              );
              canvas.drawLine(
                Offset(xEdge, y * cellSize),
                Offset(xEdge, (y + 1) * cellSize),
                paint,
              );
            }
          }
        }
        if (y + 1 < region.height) {
          final bottom = region.cellAt(x, y + 1);
          if (cell.regionCellId != bottom.regionCellId) {
            if (regionMapDrawBoundaryBetweenAdjacentCells(
              gateByUnrevealedTiles: gateMapBoundariesByVisibility,
              visibilityA: regionMapComponentVisibilityForTerrain(this, cell),
              visibilityB: regionMapComponentVisibilityForTerrain(this, bottom),
            )) {
              paint.color = _provinceBorderColor(cell, bottom);
              final yEdge = horizontalProvinceTopologyEdgeY(
                top: cell,
                bottom: bottom,
                cellSizePx: cellSize,
                topTileY: y,
                coastInsetPx: coastInset,
              );
              canvas.drawLine(
                Offset(x * cellSize, yEdge),
                Offset((x + 1) * cellSize, yEdge),
                paint,
              );
            }
          }
        }
      }
    }
  }

  Color _provinceBorderColor(CellViewData a, CellViewData b) {
    final aIsSea = a.isSea;
    final bIsSea = b.isSea;
    if (aIsSea && bIsSea) return RegionMapPalette.provinceBorderSeaZoneColor;
    if (!aIsSea && !bIsSea) return RegionMapPalette.provinceBorderLandColor;
    return RegionMapPalette.provinceBorderSeaLandColor;
  }
}

extension CtRegionMapRenderPoliticalBordersFaction on CtRegionMapComponent {
  void paintFactionBorders(Canvas canvas) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = kProvinceOverlayPoliticalStrokeWidth
      ..color = RegionMapPalette.factionPoliticalBorderColor;
    for (var y = 0; y < region.height; y++) {
      for (var x = 0; x < region.width; x++) {
        final cell = region.cellAt(x, y);
        if (cell.isSea) continue;
        final owner = cell.ownerFactionId ?? '';
        if (x + 1 < region.width) {
          final right = region.cellAt(x + 1, y);
          if (!right.isSea && (right.ownerFactionId ?? '') != owner) {
            if (regionMapDrawBoundaryBetweenAdjacentCells(
              gateByUnrevealedTiles: gateMapBoundariesByVisibility,
              visibilityA: regionMapComponentVisibilityForTerrain(this, cell),
              visibilityB: regionMapComponentVisibilityForTerrain(this, right),
            )) {
              final xEdge = (x + 1) * cellSize;
              canvas.drawLine(
                Offset(xEdge, y * cellSize),
                Offset(xEdge, (y + 1) * cellSize),
                paint,
              );
            }
          }
        }
        if (y + 1 < region.height) {
          final bottom = region.cellAt(x, y + 1);
          if (!bottom.isSea && (bottom.ownerFactionId ?? '') != owner) {
            if (regionMapDrawBoundaryBetweenAdjacentCells(
              gateByUnrevealedTiles: gateMapBoundariesByVisibility,
              visibilityA: regionMapComponentVisibilityForTerrain(this, cell),
              visibilityB: regionMapComponentVisibilityForTerrain(this, bottom),
            )) {
              final yEdge = (y + 1) * cellSize;
              canvas.drawLine(
                Offset(x * cellSize, yEdge),
                Offset((x + 1) * cellSize, yEdge),
                paint,
              );
            }
          }
        }
      }
    }
  }
}
