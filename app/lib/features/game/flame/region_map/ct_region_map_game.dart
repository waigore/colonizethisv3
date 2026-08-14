import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart'
    show MapBaseLayerFlags;
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flutter/foundation.dart' show VoidCallback;
import 'package:flutter/material.dart' show Offset;

import 'ct_region_map_game_mixins.dart';
import 'ct_region_map_game_props.dart';
import 'ct_region_map_game_viewport.dart';
import 'region_map_component.dart';
import 'region_map_viewport_snapshot.dart' show RegionMapViewportSnapshot;
import 'package:colonizethis_world/colonizethis_world.dart' show PlayerView;

// ignore_for_file: deprecated_member_use

/// FlameGame host for the region map, with basic tap/drag/pinch wiring.
class CtRegionMapGame extends FlameGame
    with
        TapDetector,
        CtRegionMapGameFields,
        CtRegionMapGameCamera,
        CtRegionMapGameLifecycle {
  CtRegionMapGame({
    required RegionMapViewData region,
    required double cellSizePx,
    required bool showPoliticalOverlay,
    required bool showProvinceOverlay,
    required bool showProvinceOwnershipTint,
    required bool showProvinceNamesLayer,
    bool showCapitalLinkDisconnectedHighlight = true,
    required CtMapVisibilityMode visibilityMode,
    MapBaseLayerFlags? mapBaseLayerFlags,
    BaseLayerDisplayMode baseLayerDisplayMode =
        BaseLayerDisplayMode.terrainAndResourcesImprovementsRoads,
    void Function(String provinceId)? onProvinceSelected,
    void Function(String tileKey)? onMapTileTappedForDetail,
    VoidCallback? onRegionViewChanged,
    void Function(String? provinceId)? onProvinceHovered,
    void Function(String? tileKey)? onTileHovered,
    void Function(String tileKey)? onCivilianTileTapped,
    void Function(
      String locationScopeKey,
      List<String> fleetIds,
      String markerTileKey,
    )?
    onFleetMarkerTapped,
    VoidCallback? onCivilianTileSelectionCleared,
    String? selectedTileKey,
    String? selectedCivilianTileKey,
    String? secondaryHighlightTileKey,
    Set<String>? secondaryHighlightTileKeys,
    Set<String>? validTileKeys,
    void Function(String tileKey)? onTileSelected,
    VoidCallback? onWorkTargetSelectionCancelled,
    void Function(String provinceId)? onTownIconTapped,
    PlayerView? playerViewForResources,
    void Function(RegionMapViewportSnapshot)? onViewportSnapshotChanged,
    double initialZoomMultiplier = 1.0,
    bool showPlayerTerritoryOutline = false,
    Set<String>? playerTerritoryTileKeys,
  }) {
    this.region = region;
    this.cellSizePx = cellSizePx;
    this.showPoliticalOverlay = showPoliticalOverlay;
    this.showProvinceOverlay = showProvinceOverlay;
    this.showProvinceOwnershipTint = showProvinceOwnershipTint;
    this.showProvinceNamesLayer = showProvinceNamesLayer;
    this.showCapitalLinkDisconnectedHighlight =
        showCapitalLinkDisconnectedHighlight;
    this.visibilityMode = visibilityMode;
    this.mapBaseLayerFlags =
        mapBaseLayerFlags ??
        mapBaseLayerFlagsFromDisplayMode(baseLayerDisplayMode);
    this.baseLayerDisplayMode = baseLayerDisplayMode;
    this.onProvinceSelected = onProvinceSelected;
    this.onMapTileTappedForDetail = onMapTileTappedForDetail;
    this.onRegionViewChanged = onRegionViewChanged;
    this.onProvinceHovered = onProvinceHovered;
    this.onTileHovered = onTileHovered;
    this.onCivilianTileTapped = onCivilianTileTapped;
    this.onFleetMarkerTapped = onFleetMarkerTapped;
    this.onCivilianTileSelectionCleared = onCivilianTileSelectionCleared;
    this.selectedTileKey = selectedTileKey;
    this.selectedCivilianTileKey = selectedCivilianTileKey;
    this.secondaryHighlightTileKey = secondaryHighlightTileKey;
    this.secondaryHighlightTileKeys = secondaryHighlightTileKeys;
    this.validTileKeys = validTileKeys;
    this.onTileSelected = onTileSelected;
    this.onWorkTargetSelectionCancelled = onWorkTargetSelectionCancelled;
    this.onTownIconTapped = onTownIconTapped;
    this.playerViewForResources = playerViewForResources;
    this.onViewportSnapshotChanged = onViewportSnapshotChanged;
    this.showPlayerTerritoryOutline = showPlayerTerritoryOutline;
    this.playerTerritoryTileKeys = playerTerritoryTileKeys;
    state.zoomMultiplier = initialZoomMultiplier;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await onLoadRegionMapBody();
  }

  @override
  void update(double dt) {
    super.update(dt);
    updateRegionMapGame(dt);
  }

  void updateProps({
    RegionMapViewData? region,
    bool? showPoliticalOverlay,
    bool? showProvinceOverlay,
    bool? showProvinceOwnershipTint,
    bool? showProvinceNamesLayer,
    bool? showCapitalLinkDisconnectedHighlight,
    CtMapVisibilityMode? visibilityMode,
    MapBaseLayerFlags? mapBaseLayerFlags,
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
  }) => ctRegionMapGameUpdateProps(
    this,
    region: region,
    showPoliticalOverlay: showPoliticalOverlay,
    showProvinceOverlay: showProvinceOverlay,
    showProvinceOwnershipTint: showProvinceOwnershipTint,
    showProvinceNamesLayer: showProvinceNamesLayer,
    showCapitalLinkDisconnectedHighlight: showCapitalLinkDisconnectedHighlight,
    visibilityMode: visibilityMode,
    mapBaseLayerFlags: mapBaseLayerFlags,
    baseLayerDisplayMode: baseLayerDisplayMode,
    selectedTileKey: selectedTileKey,
    selectedCivilianTileKey: selectedCivilianTileKey,
    secondaryHighlightTileKey: secondaryHighlightTileKey,
    secondaryHighlightTileKeys: secondaryHighlightTileKeys,
    clearSelectedTileKey: clearSelectedTileKey,
    clearSelectedCivilianTileKey: clearSelectedCivilianTileKey,
    clearSecondaryHighlightTileKey: clearSecondaryHighlightTileKey,
    clearSecondaryHighlightTileKeys: clearSecondaryHighlightTileKeys,
    validTileKeys: validTileKeys,
    clearValidTileKeys: clearValidTileKeys,
    onTileSelected: onTileSelected,
    onWorkTargetSelectionCancelled: onWorkTargetSelectionCancelled,
    onCivilianTileTapped: onCivilianTileTapped,
    onFleetMarkerTapped: onFleetMarkerTapped,
    onCivilianTileSelectionCleared: onCivilianTileSelectionCleared,
    playerViewForResources: playerViewForResources,
    onViewportSnapshotChanged: onViewportSnapshotChanged,
    zoomMultiplier: zoomMultiplier,
    showPlayerTerritoryOutline: showPlayerTerritoryOutline,
    playerTerritoryTileKeys: playerTerritoryTileKeys,
    clearPlayerTerritoryTileKeys: clearPlayerTerritoryTileKeys,
  );

  void setCameraCenterWorld(double x, double y) =>
      ctRegionMapGameSetCameraCenterWorld(this, x, y);

  void panCameraWorld(double dx, double dy) =>
      ctRegionMapGamePanCameraWorld(this, dx, dy);

  void centerOnTileKey(String tileKey) =>
      ctRegionMapGameCenterOnTileKey(this, tileKey);

  void panBy(Offset delta) => ctRegionMapGamePanBy(this, delta);

  void zoomBy(double factor) => ctRegionMapGameZoomBy(this, factor);

  void setZoomMultiplierAbsolute(double multiplier) =>
      ctRegionMapGameSetZoomMultiplierAbsolute(this, multiplier);

  void updateHoverFromLocal(Offset localPosition) =>
      ctRegionMapGameUpdateHoverFromLocal(this, localPosition);

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    handleRegionMapGameResize(size, state.lastCanvasSize);
  }

  @override
  void onTapUp(TapUpInfo info) => handleRegionMapTapUp(info);
}
