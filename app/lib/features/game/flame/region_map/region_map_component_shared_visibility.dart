part of 'region_map_component.dart';

/// Visibility mode for the region map. SPEC/ui/map-widget.md.
enum CtMapVisibilityMode {
  /// Full visibility: ignore per-tile visibility and render all tiles as visible.
  full,

  /// Player-constrained visibility: honor [CellViewData.visibility] for each tile.
  playerConstrained,
}

/// [CtMapVisibilityMode.playerConstrained] requires [playerViewForResources].
void assertCtMapPlayerViewRequired({
  required CtMapVisibilityMode visibilityMode,
  required PlayerView? playerViewForResources,
}) {
  if (visibilityMode == CtMapVisibilityMode.playerConstrained &&
      playerViewForResources == null) {
    throw StateError(
      'CtMapVisibilityMode.playerConstrained requires a non-null '
      'PlayerView (pass playerViewForResources), e.g. '
      'buildPlayerView(game, topology, humanPlayerId).',
    );
  }
}

/// Base layer display mode: terrain, resource icons, improvement labels, and
/// road/rail transport sprite overlays.
/// SPEC/ui/map-widget.md § Base layer display mode.
enum BaseLayerDisplayMode {
  /// Terrain only; no resource icons, improvement labels, or transport overlay.
  terrainOnly,

  /// Terrain + resource icons; no improvement labels or transport overlay.
  terrainAndResources,

  /// Terrain + resource icons + improvement labels (`I{n}` when n > 0); no
  /// transport overlay.
  terrainAndResourcesImprovementLabels,

  /// Terrain + resource icons + improvement labels + road/rail transport
  /// overlay (`roadLevel > 0`).
  terrainAndResourcesImprovementsRoads,
}

/// Returns true when extraction indicators are allowed for the current base mode.
bool shouldShowExtractionUnitIndicators({
  required BaseLayerDisplayMode baseLayerDisplayMode,
}) {
  return baseLayerDisplayMode != BaseLayerDisplayMode.terrainOnly;
}
