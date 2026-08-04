
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:flutter/foundation.dart' show VoidCallback;

import 'ct_region_map_game_mixins.dart';
import 'region_map_component.dart';
import 'region_map_viewport_snapshot.dart' show RegionMapViewportSnapshot;
import 'package:colonizethis_world/colonizethis_world.dart' show PlayerView;

/// Updates [CtRegionMapGame] configuration without recreating the game instance.
void ctRegionMapGameUpdateProps(
  CtRegionMapGameFields game, {
  RegionMapViewData? region,
  bool? showPoliticalOverlay,
  bool? showProvinceOverlay,
  bool? showProvinceOwnershipTint,
  bool? showProvinceNamesLayer,
  CtMapVisibilityMode? visibilityMode,
  BaseLayerDisplayMode? baseLayerDisplayMode,
  String? selectedTileKey,
  String? selectedCivilianTileKey,
  String? secondaryHighlightTileKey,
  Set<String>? secondaryHighlightTileKeys,
  bool clearSelectedTileKey = false,
  bool clearSelectedCivilianTileKey = false,
  bool clearSecondaryHighlightTileKey = false,
  bool clearSecondaryHighlightTileKeys = false,
  Set<String>? validTileKeys,
  bool clearValidTileKeys = false,
  void Function(String tileKey)? onTileSelected,
  VoidCallback? onWorkTargetSelectionCancelled,
  void Function(String tileKey)? onCivilianTileTapped,
  void Function(
    String locationScopeKey,
    List<String> fleetIds,
    String markerTileKey,
  )?
  onFleetMarkerTapped,
  VoidCallback? onCivilianTileSelectionCleared,
  required PlayerView? playerViewForResources,
  void Function(RegionMapViewportSnapshot)? onViewportSnapshotChanged,
  double? zoomMultiplier,
  bool? showPlayerTerritoryOutline,
  Set<String>? playerTerritoryTileKeys,
  bool clearPlayerTerritoryTileKeys = false,
}) {
  var regionChanged = false;
  if (region != null) {
    regionChanged = region.regionId != game.region.regionId;
    game.region = region;
  }
  if (showPoliticalOverlay != null) {
    game.showPoliticalOverlay = showPoliticalOverlay;
  }
  if (showProvinceOverlay != null) {
    game.showProvinceOverlay = showProvinceOverlay;
  }
  if (showProvinceOwnershipTint != null) {
    game.showProvinceOwnershipTint = showProvinceOwnershipTint;
  }
  if (showProvinceNamesLayer != null) {
    game.showProvinceNamesLayer = showProvinceNamesLayer;
  }
  if (visibilityMode != null) {
    game.visibilityMode = visibilityMode;
  }
  if (baseLayerDisplayMode != null) {
    game.baseLayerDisplayMode = baseLayerDisplayMode;
  }
  if (clearSelectedTileKey) {
    game.selectedTileKey = null;
  } else if (selectedTileKey != null) {
    game.selectedTileKey = selectedTileKey;
  }
  if (clearSelectedCivilianTileKey) {
    game.selectedCivilianTileKey = null;
  } else if (selectedCivilianTileKey != null) {
    game.selectedCivilianTileKey = selectedCivilianTileKey;
  }
  if (clearSecondaryHighlightTileKey) {
    game.secondaryHighlightTileKey = null;
  } else if (secondaryHighlightTileKey != null) {
    game.secondaryHighlightTileKey = secondaryHighlightTileKey;
  }
  if (clearSecondaryHighlightTileKeys) {
    game.secondaryHighlightTileKeys = null;
  } else if (secondaryHighlightTileKeys != null) {
    game.secondaryHighlightTileKeys = secondaryHighlightTileKeys;
  }
  if (clearValidTileKeys) {
    game.validTileKeys = null;
  } else if (validTileKeys != null) {
    game.validTileKeys = validTileKeys;
  }
  game.onTileSelected = onTileSelected;
  game.onWorkTargetSelectionCancelled = onWorkTargetSelectionCancelled;
  game.onCivilianTileTapped = onCivilianTileTapped;
  game.onFleetMarkerTapped = onFleetMarkerTapped;
  game.onCivilianTileSelectionCleared = onCivilianTileSelectionCleared;
  game.playerViewForResources = playerViewForResources;
  if (onViewportSnapshotChanged != null) {
    game.onViewportSnapshotChanged = onViewportSnapshotChanged;
  }
  if (zoomMultiplier != null) {
    game.state.zoomMultiplier = zoomMultiplier;
  }
  if (showPlayerTerritoryOutline != null) {
    game.showPlayerTerritoryOutline = showPlayerTerritoryOutline;
  }
  if (clearPlayerTerritoryTileKeys) {
    game.playerTerritoryTileKeys = null;
  } else if (playerTerritoryTileKeys != null) {
    game.playerTerritoryTileKeys = playerTerritoryTileKeys;
  }

  assertCtMapPlayerViewRequired(
    visibilityMode: game.visibilityMode,
    playerViewForResources: game.playerViewForResources,
  );

  if (game.state.mapLoaded) {
    game.state.mapComponent
      ..region = game.region
      ..cellSize = game.cellSizePx
      ..showPoliticalOverlay = game.showPoliticalOverlay
      ..showProvinceOverlay = game.showProvinceOverlay
      ..showProvinceOwnershipTint = game.showProvinceOwnershipTint
      ..showProvinceNamesLayer = game.showProvinceNamesLayer
      ..visibilityMode = game.visibilityMode
      ..baseLayerDisplayMode = game.baseLayerDisplayMode
      ..selectedTileKey = game.selectedTileKey
      ..selectedCivilianTileKey = game.selectedCivilianTileKey
      ..secondaryHighlightTileKey = game.secondaryHighlightTileKey
      ..secondaryHighlightTileKeys = game.secondaryHighlightTileKeys
      ..validTileKeys = game.validTileKeys
      ..playerViewForResources = game.playerViewForResources
      ..showPlayerTerritoryOutline = game.showPlayerTerritoryOutline
      ..playerTerritoryTileKeys = game.playerTerritoryTileKeys
      ..onFleetMarkerTapped = onFleetMarkerTapped;
    if (regionChanged || zoomMultiplier != null) {
      (game as CtRegionMapGameCamera).syncCameraZoomFromMultiplier();
    } else {
      (game as CtRegionMapGameCamera).emitViewportSnapshot();
    }
  }
}
