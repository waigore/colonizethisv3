import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart'
    show MapBaseLayerFlags;

import 'region_map_component_shared_palette.dart';
import 'region_map_component_shared_visibility_terrain.dart';

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
bool shouldRenderTransportOverlay({required MapBaseLayerFlags flags}) {
  return flags.paintsRoads;
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
