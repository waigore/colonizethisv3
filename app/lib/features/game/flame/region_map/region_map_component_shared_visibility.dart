import 'dart:math' as math;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_map/colonizethis_map.dart';

import '../caches/resource_icon_cache.dart';
import 'region_map_component_shared_palette.dart';
import 'region_map_component_shared_visibility_coastline.dart';
import 'region_map_component_shared_visibility_fog_transport.dart';
import 'region_map_component_shared_visibility_terrain.dart';

export 'region_map_component_shared_visibility_coastline.dart'
    show regionMapComponentDominantAdjacentLandBase;
export 'region_map_component_shared_visibility_extraction.dart'
    show
        extractionIndicatorDisplaySizePx,
        extractionIndicatorRectsForIconRect,
        paintResourceExtractionDiscIndicators;
export 'region_map_component_shared_visibility_fog_transport.dart'
    show
        isRailTransportLevel,
        shouldApplyFogToFeatureOverlay,
        shouldApplyFogToInteriorPlainsVariantBase,
        shouldApplyFogToInteriorPlainsVariantOverlay,
        shouldApplyFogToLandBase,
        shouldPaintTransportOverlayForCell,
        shouldRenderTransportOverlay;
export 'region_map_component_shared_visibility_name_plates.dart'
    show resolveSeaZoneNamePlateCenterWorld;
export 'region_map_component_shared_visibility_terrain.dart'
    show regionMapComponentIsFeatureTerrain;

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
