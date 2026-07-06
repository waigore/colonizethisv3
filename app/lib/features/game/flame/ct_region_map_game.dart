import 'dart:async';

import 'package:colonizethis_app/core/utils/prefixed_id.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart' show PlayerView;
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flutter/foundation.dart' show visibleForTesting, VoidCallback;
import 'package:flutter/material.dart' show Offset;

import 'region_map/region_map_component.dart';
import 'region_map/region_map_viewport_snapshot.dart'
    show
        RegionMapViewportSnapshot,
        computeRegionMapFitMapZoom,
        kRegionMapZoomMultiplierMax,
        kRegionMapZoomMultiplierMin;

part 'ct_region_map_game_camera.dart';
part 'ct_region_map_game_props.dart';
part 'ct_region_map_game_viewport.dart';

// ignore_for_file: deprecated_member_use

/// FlameGame host for the region map, with basic tap/drag/pinch wiring.
class CtRegionMapGame extends FlameGame with TapDetector {
  CtRegionMapGame({
    required this.region,
    required this.cellSizePx,
    required this.showPoliticalOverlay,
    required this.showProvinceOverlay,
    required this.showProvinceOwnershipTint,
    required this.showProvinceNamesLayer,
    required this.visibilityMode,
    this.baseLayerDisplayMode =
        BaseLayerDisplayMode.terrainAndResourcesImprovementsRoads,
    required this.onProvinceSelected,
    this.onMapTileTappedForDetail,
    required this.onRegionViewChanged,
    required this.onProvinceHovered,
    required this.onTileHovered,
    required this.onCivilianTileTapped,
    this.onFleetMarkerTapped,
    required this.onCivilianTileSelectionCleared,
    required this.selectedTileKey,
    required this.selectedCivilianTileKey,
    required this.secondaryHighlightTileKey,
    required this.validTileKeys,
    required this.onTileSelected,
    required this.onWorkTargetSelectionCancelled,
    required this.onTownIconTapped,
    this.playerViewForResources,
    this.onViewportSnapshotChanged,
    this.initialZoomMultiplier = 1.0,
  });

  RegionMapViewData region;
  final double cellSizePx;
  bool showPoliticalOverlay;
  bool showProvinceOverlay;
  bool showProvinceOwnershipTint;
  bool showProvinceNamesLayer;
  CtMapVisibilityMode visibilityMode;
  BaseLayerDisplayMode baseLayerDisplayMode;
  void Function(String provinceId)? onProvinceSelected;
  void Function(String tileKey)? onMapTileTappedForDetail;
  VoidCallback? onRegionViewChanged;
  void Function(String? provinceId)? onProvinceHovered;
  void Function(String? tileKey)? onTileHovered;
  void Function(String tileKey)? onCivilianTileTapped;
  void Function(
    String locationScopeKey,
    String? initialFleetId,
    String markerTileKey,
  )?
  onFleetMarkerTapped;
  VoidCallback? onCivilianTileSelectionCleared;
  String? selectedTileKey;
  String? selectedCivilianTileKey;
  String? secondaryHighlightTileKey;
  Set<String>? validTileKeys;
  void Function(String tileKey)? onTileSelected;
  VoidCallback? onWorkTargetSelectionCancelled;
  void Function(String provinceId)? onTownIconTapped;
  PlayerView? playerViewForResources;
  void Function(RegionMapViewportSnapshot)? onViewportSnapshotChanged;
  final double initialZoomMultiplier;

  late final CtRegionMapComponent _mapComponent;

  /// Widget tests only: Flame [onLoad] must have completed before reading.
  @visibleForTesting
  CtRegionMapComponent get debugMapComponentForTest => _mapComponent;

  /// `m` in [kRegionMapZoomMultiplierMin]–[kRegionMapZoomMultiplierMax]; camera zoom = `m × z_fit`.
  late double _zoomMultiplier = initialZoomMultiplier;
  bool _mapLoaded = false;
  Vector2? _lastCanvasSize;

  double get zoomMultiplier => _zoomMultiplier;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _mapComponent = CtRegionMapComponent(
      region: region,
      cellSize: cellSizePx,
      showPoliticalOverlay: showPoliticalOverlay,
      showProvinceOverlay: showProvinceOverlay,
      showProvinceOwnershipTint: showProvinceOwnershipTint,
      showProvinceNamesLayer: showProvinceNamesLayer,
      visibilityMode: visibilityMode,
      baseLayerDisplayMode: baseLayerDisplayMode,
      onProvinceSelected: onProvinceSelected,
      onMapTileTappedForDetail: onMapTileTappedForDetail,
      onProvinceHovered: onProvinceHovered,
      onTileHovered: onTileHovered,
      onCivilianTileTapped: onCivilianTileTapped,
      onFleetMarkerTapped: onFleetMarkerTapped,
      onCivilianTileSelectionCleared: onCivilianTileSelectionCleared,
      selectedTileKey: selectedTileKey,
      selectedCivilianTileKey: selectedCivilianTileKey,
      secondaryHighlightTileKey: secondaryHighlightTileKey,
      onTileTapped: (tileKey) {
        if (onTileSelected != null && validTileKeys != null) {
          if (tileKey != null &&
              validTileKeys!.isNotEmpty &&
              validTileKeys!.contains(tileKey)) {
            onTileSelected!.call(tileKey);
          }
        }
      },
      validTileKeys: validTileKeys,
      onTownIconTapped: onTownIconTapped,
      playerViewForResources: playerViewForResources,
    )..position = Vector2.zero();
    await world.add(_mapComponent);
    _mapLoaded = true;

    if (size != Vector2.zero()) {
      _syncCameraZoomFromMultiplier();
    } else {
      _emitViewportSnapshot();
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_mapLoaded) {
      final z = camera.viewfinder.zoom;
      _mapComponent.cameraZoom = z.isFinite && z > 0 ? z : 1.0;
    }
  }

  /// Update map configuration without recreating the game.
  void updateProps({
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
    bool clearSelectedTileKey = false,
    bool clearSelectedCivilianTileKey = false,
    bool clearSecondaryHighlightTileKey = false,
    Set<String>? validTileKeys,
    bool clearValidTileKeys = false,
    void Function(String tileKey)? onTileSelected,
    VoidCallback? onWorkTargetSelectionCancelled,
    void Function(String tileKey)? onCivilianTileTapped,
    void Function(
      String locationScopeKey,
      String? initialFleetId,
      String markerTileKey,
    )?
    onFleetMarkerTapped,
    VoidCallback? onCivilianTileSelectionCleared,
    required PlayerView? playerViewForResources,
    void Function(RegionMapViewportSnapshot)? onViewportSnapshotChanged,
    double? zoomMultiplier,
  }) =>
      _ctRegionMapGameUpdateProps(
        this,
        region: region,
        showPoliticalOverlay: showPoliticalOverlay,
        showProvinceOverlay: showProvinceOverlay,
        showProvinceOwnershipTint: showProvinceOwnershipTint,
        showProvinceNamesLayer: showProvinceNamesLayer,
        visibilityMode: visibilityMode,
        baseLayerDisplayMode: baseLayerDisplayMode,
        selectedTileKey: selectedTileKey,
        selectedCivilianTileKey: selectedCivilianTileKey,
        secondaryHighlightTileKey: secondaryHighlightTileKey,
        clearSelectedTileKey: clearSelectedTileKey,
        clearSelectedCivilianTileKey: clearSelectedCivilianTileKey,
        clearSecondaryHighlightTileKey: clearSecondaryHighlightTileKey,
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
      );

  /// Sets the camera center in world space (used by the region minimap). Clamped to the map.
  void setCameraCenterWorld(double x, double y) =>
      _ctRegionMapGameSetCameraCenterWorld(this, x, y);

  /// Pans the camera center in world space (used by the region minimap). Clamped each step.
  void panCameraWorld(double dx, double dy) =>
      _ctRegionMapGamePanCameraWorld(this, dx, dy);

  /// Centers the camera on the given tile key, if valid.
  void centerOnTileKey(String tileKey) =>
      _ctRegionMapGameCenterOnTileKey(this, tileKey);

  /// Pan the camera by a Flutter offset (in logical pixels).
  void panBy(Offset delta) => _ctRegionMapGamePanBy(this, delta);

  /// Zoom the camera by [factor] (>1 zooms in, <1 zooms out) on [zoomMultiplier].
  void zoomBy(double factor) => _ctRegionMapGameZoomBy(this, factor);

  /// Absolute fit-relative multiplier from the shell (slider). SPEC/ui/map-widget.md.
  void setZoomMultiplierAbsolute(double multiplier) =>
      _ctRegionMapGameSetZoomMultiplierAbsolute(this, multiplier);

  /// Update hover state from a widget-local position.
  void updateHoverFromLocal(Offset localPosition) =>
      _ctRegionMapGameUpdateHoverFromLocal(this, localPosition);

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);

    final previousSize = _lastCanvasSize;
    _lastCanvasSize = size.clone();
    _handleGameResize(size, previousSize);
  }

  @override
  void onTapUp(TapUpInfo info) {
    final z = camera.viewfinder.zoom;
    if (z <= 0 || !z.isFinite) return;
    final widgetPos = info.eventPosition.widget;
    final halfView = size / 2;
    final world = camera.viewfinder.position + (widgetPos - halfView) / z;
    _mapComponent.handleTapAtWorld(world);
    onRegionViewChanged?.call();
    _emitViewportSnapshot();
  }
}
