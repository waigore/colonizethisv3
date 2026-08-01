import 'dart:math' as math;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:flutter/material.dart';

import '../caches/resource_icon_cache.dart';
import 'region_map_component_shared_palette.dart';
import 'region_map_component_shared_visibility_extraction.dart';
import 'region_map_component_shared_visibility_name_plates.dart';

export 'region_map_component_shared_visibility_extraction.dart'
    show
        extractionIndicatorDisplaySizePx,
        extractionIndicatorRectsForIconRect,
        paintResourceExtractionDiscIndicators;
export 'region_map_component_shared_visibility_name_plates.dart'
    show resolveSeaZoneNamePlateCenterWorld;

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
