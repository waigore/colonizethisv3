import 'dart:math' as math;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:flutter/material.dart';

import '../caches/resource_icon_cache.dart';
import 'region_map_component_shared_palette.dart';

/// True when `(x, y)` is within Chebyshev distance ≤ 2 of a fleet marker that
/// applies the naval move-draft reveal halo. SPEC/ui/map-widget.md.
bool isCellUnderFleetRevealHalo({
  required int x,
  required int y,
  required List<FleetTileMarkerView> fleetTileMarkers,
}) {
  for (final m in fleetTileMarkers) {
    if (!m.applyFleetRevealHalo) {
      continue;
    }
    if (math.max((x - m.x).abs(), (y - m.y).abs()) <= 2) {
      return true;
    }
  }
  return false;
}

/// True when `(x, y)` is within Chebyshev distance <= 2 of a civilian marker
/// that applies the draft assignment reveal halo.
bool isCellUnderCivilianRevealHalo({
  required int x,
  required int y,
  required List<CivilianTileMarkerView> civilianTileMarkers,
}) {
  for (final m in civilianTileMarkers) {
    if (!m.applyCivilianRevealHalo) {
      continue;
    }
    if (math.max((x - m.x).abs(), (y - m.y).abs()) <= 2) {
      return true;
    }
  }
  return false;
}

/// Effective terrain visibility for map painting (fog + reveal halos).
///
/// Used by the region map renderer and tests for sea zone label gating (#1756).
TileVisibility visibilityForTerrainForMapCell({
  required CtMapVisibilityMode visibilityMode,
  required CellViewData cell,
  required List<FleetTileMarkerView> fleetTileMarkers,
  required List<CivilianTileMarkerView> civilianTileMarkers,
}) {
  if (visibilityMode != CtMapVisibilityMode.playerConstrained) {
    return cell.visibility;
  }
  if (isCellUnderFleetRevealHalo(
    x: cell.x,
    y: cell.y,
    fleetTileMarkers: fleetTileMarkers,
  )) {
    return TileVisibility.visible;
  }
  if (isCellUnderCivilianRevealHalo(
    x: cell.x,
    y: cell.y,
    civilianTileMarkers: civilianTileMarkers,
  )) {
    return TileVisibility.visible;
  }
  return cell.visibility;
}

/// Resolves map province-label icon ids.
///
/// Capital icon is prepended, then optional presence icons follow.
List<String> resolveProvinceLabelIconIds({
  required bool isCapital,
  ProvinceUnitPresenceView? presence,
}) {
  final ids = <String>[
    if (isCapital) RegionMapPalette.provinceLabelCapitalIconId,
  ];
  ids.addAll(resolveProvinceLabelPresenceIconIds(presence));
  return ids;
}

/// Resolves optional prefix icon ids for sea-zone labels.
List<String> resolveSeaZoneLabelPrefixIconIds({required bool isWarpZone}) {
  if (!isWarpZone) {
    return const <String>[];
  }
  return const <String>[RegionMapPalette.seaZoneLabelWarpIconId];
}

/// Resolves map province-label presence icon ids from province presence data.
///
/// Order is always civilian, regiment, ship. Icons are suppressed when intel is
/// not visible or count is zero.
List<String> resolveProvinceLabelPresenceIconIds(
  ProvinceUnitPresenceView? presence,
) {
  final showPresenceIcons = presence != null && presence.intelVisible;
  if (!showPresenceIcons) {
    return const <String>[];
  }
  return <String>[
    if (presence.civilianCount > 0) 'map_presence_civilian',
    if (presence.regimentCount > 0) 'map_presence_regiment',
    if (presence.shipCount > 0) 'map_presence_ship',
  ];
}

/// Returns true when province-name text + icons should wrap icons to line 2.
bool shouldWrapProvinceLabelPresenceIcons({
  required double textWidthPx,
  required int iconCount,
  double maxWidthPx = RegionMapPalette.provinceLabelMaxWidthPx,
  double iconRenderedPx = RegionMapPalette.provinceLabelIconRenderedPx,
  double iconGapPx = RegionMapPalette.provinceLabelIconGapPx,
  double textIconGapPx = RegionMapPalette.provinceLabelTextIconGapPx,
}) {
  if (iconCount <= 0) {
    return false;
  }
  final iconsWidth =
      (iconCount * iconRenderedPx) + ((iconCount - 1) * iconGapPx);
  final singleLineContentWidth = textWidthPx + textIconGapPx + iconsWidth;
  return singleLineContentWidth > maxWidthPx;
}

/// Capital labels must keep full text + star visible; do not ellipsize.
bool shouldEllipsizeProvinceLabelText({required bool isCapital}) {
  return !isCapital;
}

/// Returns true when the land-base pass should apply fog darkening.
///
/// Feature terrain (forest/hills/mountain/swamp) is darkened in the feature
/// overlay pass, so land-base darkening must be skipped there to avoid
/// compounded fog attenuation on the same tile.
bool shouldApplyFogToLandBase({
  required CtMapVisibilityMode visibilityMode,
  required TileVisibility tileVisibility,
  required TerrainType? terrain,
}) {
  if (visibilityMode != CtMapVisibilityMode.playerConstrained) {
    return false;
  }
  if (tileVisibility != TileVisibility.fogged) {
    return false;
  }
  if (terrain == null) {
    return true;
  }
  return !regionMapComponentIsFeatureTerrain(terrain);
}

/// Returns true when the feature-overlay pass should apply fog darkening.
///
/// Feature terrain should receive fog attenuation in the overlay pass only, so
/// fogged feature cells do not get darkened twice across base + overlay.
bool shouldApplyFogToFeatureOverlay({
  required CtMapVisibilityMode visibilityMode,
  required TileVisibility tileVisibility,
  required TerrainType? terrain,
}) {
  if (visibilityMode != CtMapVisibilityMode.playerConstrained) {
    return false;
  }
  if (tileVisibility != TileVisibility.fogged) {
    return false;
  }
  if (terrain == null) {
    return false;
  }
  return regionMapComponentIsFeatureTerrain(terrain);
}

/// Returns true when the interior-plains variant base draw should apply fog.
///
/// For `tile_plains_*` composition, fog must be applied once across the final
/// composed result. The base pass intentionally stays un-fogged, and the
/// variant overlay pass receives fog attenuation when needed.
bool shouldApplyFogToInteriorPlainsVariantBase({
  required CtMapVisibilityMode visibilityMode,
  required TileVisibility tileVisibility,
}) {
  return false;
}

/// Returns true when the interior-plains variant overlay draw should apply fog.
///
/// This is the single fog attenuation point for fogged interior-plains
/// `tile_plains_*` composition to avoid double darkening.
bool shouldApplyFogToInteriorPlainsVariantOverlay({
  required CtMapVisibilityMode visibilityMode,
  required TileVisibility tileVisibility,
}) {
  if (visibilityMode != CtMapVisibilityMode.playerConstrained) {
    return false;
  }
  return tileVisibility == TileVisibility.fogged;
}

/// Returns true when transport sprites should render for the selected base mode.
bool shouldRenderTransportOverlay({
  required BaseLayerDisplayMode baseLayerDisplayMode,
}) {
  return baseLayerDisplayMode ==
      BaseLayerDisplayMode.terrainAndResourcesImprovementsRoads;
}

/// Returns true when a road level should use the rail transport family.
///
/// Current v1 behavior uses rail sprites only for level 4.
bool isRailTransportLevel(int roadLevel) => roadLevel == 4;

/// Returns true when a given cell is eligible for transport overlay rendering.
///
/// Overlay is land-only, requires `roadLevel > 0`, and is hidden for unrevealed
/// cells in player-constrained visibility mode.
bool shouldPaintTransportOverlayForCell({
  required CellViewData cell,
  required CtMapVisibilityMode visibilityMode,
  required TileVisibility tileVisibility,
}) {
  if (cell.isSea || (cell.roadLevel ?? 0) <= 0) {
    return false;
  }
  if (visibilityMode == CtMapVisibilityMode.playerConstrained &&
      tileVisibility == TileVisibility.unrevealed) {
    return false;
  }
  return true;
}

/// Check if a terrain type uses L2+ standalone tile rendering (features).
/// L0: Sea (Wang). L1: Plains/Desert (Wang). L2+: Features (standalone).
bool regionMapComponentIsFeatureTerrain(TerrainType terrain) {
  return isForestTerrain(terrain) ||
      terrain == TerrainType.hills ||
      terrain == TerrainType.mountain ||
      terrain == TerrainType.swamp;
}

final class _PlainsDesertTally {
  int plains = 0;
  int desert = 0;
}

void _tallyDominantLandNeighbor(CellViewData? cell, _PlainsDesertTally tally) {
  if (cell == null || cell.isSea) {
    return;
  }
  final terrain = cell.terrainType;
  if (terrain == TerrainType.plains) {
    tally.plains++;
    return;
  }
  if (terrain == TerrainType.desert) {
    tally.desert++;
    return;
  }
  if (terrain != null && regionMapComponentIsFeatureTerrain(terrain)) {
    tally.plains++; // Features have plains underneath
  }
}

/// Get the dominant adjacent land base type for coastline tileset selection.
/// Returns 'plains' or 'desert' based on which is more common among neighbors.
TerrainType? regionMapComponentDominantAdjacentLandBase(
  int x,
  int y,
  CellViewData? Function(int, int) getCellAt,
) {
  final tally = _PlainsDesertTally();

  for (final dy in [-1, 0, 1]) {
    for (final dx in [-1, 0, 1]) {
      if (dx == 0 && dy == 0) {
        continue;
      }
      _tallyDominantLandNeighbor(getCellAt(x + dx, y + dy), tally);
    }
  }

  if (tally.plains >= tally.desert) {
    return TerrainType.plains;
  }
  return TerrainType.desert;
}

/// On-map resource icon width/height in world/cell coordinates.
///
/// SPEC/ui/map-widget.md § Resource Icons: **one quarter** of [cellSize], capped
/// at [ResourceIconCache.iconSize] so 64×64 source assets are **never upscaled**
/// on the map (scale down only).
double resourceIconDisplaySizePx(double cellSize) {
  final quarter = cellSize * 0.25;
  return quarter < ResourceIconCache.iconSize
      ? quarter
      : ResourceIconCache.iconSize;
}

double extractionIndicatorDisplaySizePx(double resourceIconDisplaySizePx) {
  return math.min(
    ResourceIconCache.iconSize,
    resourceIconDisplaySizePx + RegionMapPalette.extractionIndicatorSizeBoostPx,
  );
}

List<Rect> extractionIndicatorRectsForIconRect({
  required Rect iconRect,
  required int units,
}) {
  if (units <= 0) {
    return const <Rect>[];
  }
  final indicatorSize = extractionIndicatorDisplaySizePx(iconRect.width);
  final stepX =
      indicatorSize * (1.0 - RegionMapPalette.extractionIndicatorOverlapFactor);
  final startX =
      iconRect.right + RegionMapPalette.extractionIndicatorStartInsetXPx;
  final top = iconRect.bottom - indicatorSize;
  return List<Rect>.generate(
    units,
    (i) =>
        Rect.fromLTWH(startX + (i * stepX), top, indicatorSize, indicatorSize),
    growable: false,
  );
}

/// Paints per-tile extraction throughput as **filled discs with dark stroke**
/// (not commodity sprites). Effective slots use [RegionMapPalette.mapSelectionGold]
/// (transported toward capital); blocked slots use
/// [RegionMapPalette.extractionDiscBlockedBrown]. Paint order: fill then stroke.
/// [fogCompatibleOverlayPaint] supplies the same fog `ColorFilter` as resource
/// icons when the tile is fogged.
///
/// SPEC/ui/map-widget.md § Per-tile extraction throughput indicators;
/// SPEC/program/map-region-map-render.md (`_paintOverlay` extraction discs).
void paintResourceExtractionDiscIndicators({
  required Canvas canvas,
  required List<Rect> indicatorRects,
  required int effectiveCount,
  required Paint fogCompatibleOverlayPaint,
}) {
  if (indicatorRects.isEmpty) {
    return;
  }
  final fogFilter = fogCompatibleOverlayPaint.colorFilter;
  final strokeWidth = RegionMapPalette.extractionDiscStrokeWidthPx;
  for (var i = 0; i < indicatorRects.length; i++) {
    final isEffective = i < effectiveCount;
    final fillColor = isEffective
        ? RegionMapPalette.mapSelectionGold
        : RegionMapPalette.extractionDiscBlockedBrown;
    final r = indicatorRects[i];
    final center = r.center;
    final radius = r.shortestSide * 0.5;

    final fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = fillColor;
    if (fogFilter != null) {
      fillPaint.colorFilter = fogFilter;
    }
    canvas.drawCircle(center, radius, fillPaint);

    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = RegionMapPalette.extractionDiscStrokeColor;
    if (fogFilter != null) {
      strokePaint.colorFilter = fogFilter;
    }
    final strokeRadius = radius - strokeWidth * 0.5;
    if (strokeRadius > 0) {
      canvas.drawCircle(center, strokeRadius, strokePaint);
    }
  }
}

Offset resolveSeaZoneNamePlateCenterWorld({
  required int centroidTileX,
  required int centroidTileY,
  required double cellSize,
  required int gridWidth,
  required int gridHeight,
  required double plateWidthLogicalPx,
  required double plateHeightLogicalPx,
  required double cameraZoom,
  int? avoidedTileX,
  int? avoidedTileY,
}) {
  final avoidTileX = avoidedTileX ?? centroidTileX;
  final avoidTileY = avoidedTileY ?? centroidTileY;
  final invZ = 1.0 / cameraZoom.clamp(0.25, 4.0);
  final ww = plateWidthLogicalPx * invZ / 2;
  final hh = plateHeightLogicalPx * invZ / 2;
  final mapW = gridWidth * cellSize;
  final mapH = gridHeight * cellSize;
  final cellL = avoidTileX * cellSize;
  final cellT = avoidTileY * cellSize;
  final cellR = cellL + cellSize;
  final cellB = cellT + cellSize;
  const gap = 1.0;
  var cx = (centroidTileX + 0.5) * cellSize;
  bool overlapsCell(double pcx, double pcy) {
    final l = pcx - ww;
    final r = pcx + ww;
    final t = pcy - hh;
    final b = pcy + hh;
    return !(r <= cellL || l >= cellR || b <= cellT || t >= cellB);
  }
  ({double x, double y}) clampPlateCenter(double pcx, double pcy) {
    var x = pcx;
    var y = pcy;
    var l = x - ww;
    var r = x + ww;
    if (l < 0) x -= l;
    r = x + ww;
    if (r > mapW) x -= r - mapW;
    l = x - ww;
    if (l < 0) x = ww;
    var t = y - hh;
    var b = y + hh;
    if (t < 0) y -= t;
    b = y + hh;
    if (b > mapH) y -= b - mapH;
    t = y - hh;
    if (t < 0) y = hh;
    return (x: x, y: y);
  }
  final aboveY = cellT - gap - hh;
  final aboveTop = aboveY - hh;
  final useAbove = aboveTop >= 0;
  var cy = useAbove ? aboveY : cellB + gap + hh;
  var clamped = clampPlateCenter(cx, cy);
  cx = clamped.x;
  cy = clamped.y;
  if (overlapsCell(cx, cy)) {
    if (useAbove) {
      cy = cellB + gap + hh;
    } else if (aboveTop >= 0) {
      cy = aboveY;
    }
    clamped = clampPlateCenter(cx, cy);
    cx = clamped.x;
    cy = clamped.y;
  }
  for (var i = 0; i < 48 && overlapsCell(cx, cy); i++) {
    final midY = (cellT + cellB) / 2;
    if (cy < midY) {
      cy -= 1;
    } else {
      cy += 1;
    }
    clamped = clampPlateCenter(cx, cy);
    cx = clamped.x;
    cy = clamped.y;
  }
  return Offset(cx, cy);
}
