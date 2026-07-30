import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:flutter/material.dart';

import 'region_map_boundary_visibility.dart';
import 'region_map_component.dart';
import 'region_map_component_shared_palette.dart';
import 'region_map_component_shared_visibility.dart';

/// Player-owned land perimeter stroke for panel maps. Refs #4175.
const double kPlayerTerritoryOutlineStrokeWidth = 2.0;

String regionMapCellTileKey(RegionMapViewData region, CellViewData cell) =>
    '${region.regionId}|${cell.regionCellId}|${cell.x}|${cell.y}';

bool regionMapCellIsPlayerTerritory(
  RegionMapViewData region,
  CellViewData cell,
  Set<String> playerTerritoryTileKeys,
) {
  if (cell.isSea) return false;
  return playerTerritoryTileKeys.contains(regionMapCellTileKey(region, cell));
}

extension CtRegionMapRenderPlayerTerritoryOutline on CtRegionMapComponent {
  void paintPlayerTerritoryOutline(Canvas canvas) {
    final territoryKeys = playerTerritoryTileKeys;
    if (!showPlayerTerritoryOutline ||
        territoryKeys == null ||
        territoryKeys.isEmpty) {
      return;
    }

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = kPlayerTerritoryOutlineStrokeWidth
      ..color = RegionMapPalette.mapHoverSelectorIdle.withValues(alpha: 0.55);

    for (var y = 0; y < region.height; y++) {
      for (var x = 0; x < region.width; x++) {
        final cell = region.cellAt(x, y);
        if (!regionMapCellIsPlayerTerritory(region, cell, territoryKeys)) {
          continue;
        }
        final cellVisibility = regionMapComponentVisibilityForTerrain(this, cell);

        if (x + 1 < region.width) {
          final right = region.cellAt(x + 1, y);
          final rightVisibility =
              regionMapComponentVisibilityForTerrain(this, right);
          if (!regionMapCellIsPlayerTerritory(region, right, territoryKeys)) {
            if (regionMapDrawBoundaryBetweenAdjacentCells(
              gateByUnrevealedTiles: gateMapBoundariesByVisibility,
              visibilityA: cellVisibility,
              visibilityB: rightVisibility,
            )) {
              final xEdge = (x + 1) * cellSize;
              canvas.drawLine(
                Offset(xEdge, y * cellSize),
                Offset(xEdge, (y + 1) * cellSize),
                paint,
              );
            }
          }
        } else {
          if (regionMapDrawBoundaryBetweenAdjacentCells(
            gateByUnrevealedTiles: gateMapBoundariesByVisibility,
            visibilityA: cellVisibility,
            visibilityB: TileVisibility.unrevealed,
          )) {
            final xEdge = (x + 1) * cellSize;
            canvas.drawLine(
              Offset(xEdge, y * cellSize),
              Offset(xEdge, (y + 1) * cellSize),
              paint,
            );
          }
        }

        if (y + 1 < region.height) {
          final bottom = region.cellAt(x, y + 1);
          final bottomVisibility =
              regionMapComponentVisibilityForTerrain(this, bottom);
          if (!regionMapCellIsPlayerTerritory(region, bottom, territoryKeys)) {
            if (regionMapDrawBoundaryBetweenAdjacentCells(
              gateByUnrevealedTiles: gateMapBoundariesByVisibility,
              visibilityA: cellVisibility,
              visibilityB: bottomVisibility,
            )) {
              final yEdge = (y + 1) * cellSize;
              canvas.drawLine(
                Offset(x * cellSize, yEdge),
                Offset((x + 1) * cellSize, yEdge),
                paint,
              );
            }
          }
        } else {
          if (regionMapDrawBoundaryBetweenAdjacentCells(
            gateByUnrevealedTiles: gateMapBoundariesByVisibility,
            visibilityA: cellVisibility,
            visibilityB: TileVisibility.unrevealed,
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
