import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:flutter/material.dart';

import '../render/warp_zone_edge_geometry.dart';
import 'region_map_boundary_visibility.dart';
import 'region_map_component.dart';
import 'region_map_component_shared_palette.dart';
import 'region_map_component_support.dart';
import 'region_map_province_overlay_geometry.dart';

Set<(int x, int y)> regionMapComponentWarpTileCoordsForZones(
  CtRegionMapComponent component,
  Set<String> warpSeaZoneIds,
) {
  final warpTiles = <(int x, int y)>{};
  for (var y = 0; y < component.region.height; y++) {
    for (var x = 0; x < component.region.width; x++) {
      final cell = component.region.cellAt(x, y);
      if (warpSeaZoneIds.contains(cell.regionCellId)) {
        warpTiles.add((x, y));
      }
    }
  }
  return warpTiles;
}

void regionMapComponentPaintWarpZones(
  CtRegionMapComponent component,
  Canvas canvas,
) {
  final warpSeaZoneIds =
      component.region.warpMarkers.map((m) => m.seaZoneId).toSet();
  if (warpSeaZoneIds.isEmpty) return;

  final warpTiles = regionMapComponentWarpTileCoordsForZones(
    component,
    warpSeaZoneIds,
  );

  final glowOuter = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = kWarpZoneGlowOuterStrokeWidth
    ..color = RegionMapPalette.mapSelectionGold.withValues(
      alpha: RegionMapPalette.warpZoneOuterGlowAlpha,
    );
  final glowInner = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = kWarpZoneGlowInnerStrokeWidth
    ..color = RegionMapPalette.warpZoneInnerHighlight;

  for (final (x, y) in warpTiles) {
    final cell = component.region.cellAt(x, y);
    // Defense in depth: [warpTiles] is built from warp sea-zone ids, but keep
    // this guard so a stale set or future caller change cannot paint edges
    // from non-warp cells.
    if (!warpSeaZoneIds.contains(cell.regionCellId)) {
      continue;
    }

    regionMapComponentPaintWarpZoneEdge(
      component,
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
    regionMapComponentPaintWarpZoneEdge(
      component,
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
    regionMapComponentPaintWarpZoneEdge(
      component,
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
    regionMapComponentPaintWarpZoneEdge(
      component,
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

void regionMapComponentPaintWarpZoneEdge(
  CtRegionMapComponent component,
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
  if (nx < 0 ||
      nx >= component.region.width ||
      ny < 0 ||
      ny >= component.region.height) {
    return;
  }

  final neighbor = component.region.cellAt(nx, ny);
  if (warpSeaZoneIds.contains(neighbor.regionCellId)) {
    return;
  }

  if (!regionMapDrawBoundaryBetweenAdjacentCells(
    gateByUnrevealedTiles: component.gateMapBoundariesByVisibility,
    visibilityA: regionMapComponentVisibilityForTerrain(component, cell),
    visibilityB: regionMapComponentVisibilityForTerrain(component, neighbor),
  )) {
    return;
  }

  final segment = warpZoneGlowLineForDirection(
    cellSize: component.cellSize,
    x: x,
    y: y,
    dx: dx,
    dy: dy,
  );
  canvas.drawLine(segment.$1, segment.$2, glowOuter);
  canvas.drawLine(segment.$1, segment.$2, glowInner);
}
