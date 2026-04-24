import 'dart:async';

import 'package:colonizethis_logic/colonizethis_logic.dart' show PlayerView;
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flutter/foundation.dart' show visibleForTesting, VoidCallback;
import 'package:flutter/material.dart' show Offset;

import 'region_map_component.dart';
import 'region_map_viewport_snapshot.dart'
    show
        RegionMapViewportSnapshot,
        computeRegionMapFitMapZoom,
        kRegionMapZoomMultiplierMax,
        kRegionMapZoomMultiplierMin;

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
        // Tap handler for work target selection mode.
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

    // Initial camera clamp once size is available to avoid black bands on first paint.
    if (size != Vector2.zero()) {
      _syncCameraZoomFromMultiplier();
    } else {
      _emitViewportSnapshot();
    }
  }

  void _syncCameraZoomFromMultiplier() {
    if (!_mapLoaded || size == Vector2.zero()) return;
    _zoomMultiplier = _zoomMultiplier.clamp(
      kRegionMapZoomMultiplierMin,
      kRegionMapZoomMultiplierMax,
    );
    final mw = region.width * cellSizePx;
    final mh = region.height * cellSizePx;
    final zFit = computeRegionMapFitMapZoom(
      viewportWidthLogical: size.x,
      viewportHeightLogical: size.y,
      mapWidthWorld: mw,
      mapHeightWorld: mh,
    );
    camera.viewfinder.zoom = _zoomMultiplier * zFit;
    _clampCameraToMap();
    onRegionViewChanged?.call();
    _emitViewportSnapshot();
  }

  void _emitViewportSnapshot() {
    final cb = onViewportSnapshotChanged;
    if (cb == null) return;
    if (!_mapLoaded || size == Vector2.zero()) return;
    final mw = region.width * cellSizePx;
    final mh = region.height * cellSizePx;
    final zFit = computeRegionMapFitMapZoom(
      viewportWidthLogical: size.x,
      viewportHeightLogical: size.y,
      mapWidthWorld: mw,
      mapHeightWorld: mh,
    );
    cb(
      RegionMapViewportSnapshot(
        regionId: region.regionId,
        cellSizePx: cellSizePx,
        mapWidthWorld: mw,
        mapHeightWorld: mh,
        cameraCenterX: camera.viewfinder.position.x,
        cameraCenterY: camera.viewfinder.position.y,
        zoom: camera.viewfinder.zoom,
        fitMapZoom: zFit,
        viewportWidthLogical: size.x,
        viewportHeightLogical: size.y,
      ),
    );
  }

  /// Sets the camera center in world space (used by the region minimap). Clamped to the map.
  void setCameraCenterWorld(double x, double y) {
    camera.viewfinder.position = Vector2(x, y);
    _clampCameraToMap();
    onRegionViewChanged?.call();
    _emitViewportSnapshot();
  }

  /// Pans the camera center in world space (used by the region minimap). Clamped each step.
  void panCameraWorld(double dx, double dy) {
    if (dx == 0 && dy == 0) return;
    camera.viewfinder.position += Vector2(dx, dy);
    _clampCameraToMap();
    onRegionViewChanged?.call();
    _emitViewportSnapshot();
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
  }) {
    var regionChanged = false;
    if (region != null) {
      regionChanged = region.regionId != this.region.regionId;
      this.region = region;
    }
    if (showPoliticalOverlay != null) {
      this.showPoliticalOverlay = showPoliticalOverlay;
    }
    if (showProvinceOverlay != null) {
      this.showProvinceOverlay = showProvinceOverlay;
    }
    if (showProvinceOwnershipTint != null) {
      this.showProvinceOwnershipTint = showProvinceOwnershipTint;
    }
    if (showProvinceNamesLayer != null) {
      this.showProvinceNamesLayer = showProvinceNamesLayer;
    }
    if (visibilityMode != null) {
      this.visibilityMode = visibilityMode;
    }
    if (baseLayerDisplayMode != null) {
      this.baseLayerDisplayMode = baseLayerDisplayMode;
    }
    if (clearSelectedTileKey) {
      this.selectedTileKey = null;
    } else if (selectedTileKey != null) {
      this.selectedTileKey = selectedTileKey;
    }
    if (clearSelectedCivilianTileKey) {
      this.selectedCivilianTileKey = null;
    } else if (selectedCivilianTileKey != null) {
      this.selectedCivilianTileKey = selectedCivilianTileKey;
    }
    if (clearSecondaryHighlightTileKey) {
      this.secondaryHighlightTileKey = null;
    } else if (secondaryHighlightTileKey != null) {
      this.secondaryHighlightTileKey = secondaryHighlightTileKey;
    }
    if (clearValidTileKeys) {
      this.validTileKeys = null;
    } else if (validTileKeys != null) {
      this.validTileKeys = validTileKeys;
    }
    // Update callbacks (these may change when parent widget rebuilds).
    this.onTileSelected = onTileSelected;
    this.onWorkTargetSelectionCancelled = onWorkTargetSelectionCancelled;
    this.onCivilianTileTapped = onCivilianTileTapped;
    this.onFleetMarkerTapped = onFleetMarkerTapped;
    this.onCivilianTileSelectionCleared = onCivilianTileSelectionCleared;
    this.playerViewForResources = playerViewForResources;
    if (onViewportSnapshotChanged != null) {
      this.onViewportSnapshotChanged = onViewportSnapshotChanged;
    }
    if (zoomMultiplier != null) {
      _zoomMultiplier = zoomMultiplier;
    }

    assertCtMapPlayerViewRequired(
      visibilityMode: this.visibilityMode,
      playerViewForResources: this.playerViewForResources,
    );

    if (_mapLoaded) {
      _mapComponent
        ..region = this.region
        ..cellSize = cellSizePx
        ..showPoliticalOverlay = this.showPoliticalOverlay
        ..showProvinceOverlay = this.showProvinceOverlay
        ..showProvinceOwnershipTint = this.showProvinceOwnershipTint
        ..showProvinceNamesLayer = this.showProvinceNamesLayer
        ..visibilityMode = this.visibilityMode
        ..baseLayerDisplayMode = this.baseLayerDisplayMode
        ..selectedTileKey = this.selectedTileKey
        ..selectedCivilianTileKey = this.selectedCivilianTileKey
        ..secondaryHighlightTileKey = this.secondaryHighlightTileKey
        ..validTileKeys = this.validTileKeys
        ..playerViewForResources = this.playerViewForResources
        ..onFleetMarkerTapped = onFleetMarkerTapped;
      if (regionChanged || zoomMultiplier != null) {
        _syncCameraZoomFromMultiplier();
      } else {
        _emitViewportSnapshot();
      }
    }
  }

  /// Centers the camera on the given tile key, if valid.
  void centerOnTileKey(String tileKey) {
    final parts = tileKey.split('|');
    if (parts.length < 4) return;
    if (parts[0] != region.regionId) return;
    final x = int.tryParse(parts[2]);
    final y = int.tryParse(parts[3]);
    if (x == null || y == null) return;
    if (x < 0 || x >= region.width || y < 0 || y >= region.height) return;
    final worldX = x * cellSizePx + cellSizePx / 2;
    final worldY = y * cellSizePx + cellSizePx / 2;
    camera.moveTo(Vector2(worldX, worldY));
    _clampCameraToMap();
    onRegionViewChanged?.call();
    _emitViewportSnapshot();
  }

  /// Pan the camera by a Flutter offset (in logical pixels).
  void panBy(Offset delta) {
    if (delta == Offset.zero) return;
    final z = camera.viewfinder.zoom;
    if (z <= 0 || !z.isFinite) return;
    camera.viewfinder.position -= Vector2(delta.dx, delta.dy) / z;
    _clampCameraToMap();
    onRegionViewChanged?.call();
    _emitViewportSnapshot();
  }

  /// Zoom the camera by [factor] (>1 zooms in, <1 zooms out) on [zoomMultiplier].
  void zoomBy(double factor) {
    _zoomMultiplier = (_zoomMultiplier * factor).clamp(
      kRegionMapZoomMultiplierMin,
      kRegionMapZoomMultiplierMax,
    );
    _syncCameraZoomFromMultiplier();
  }

  /// Absolute fit-relative multiplier from the shell (slider). SPEC/ui/map-widget.md.
  void setZoomMultiplierAbsolute(double multiplier) {
    _zoomMultiplier = multiplier.clamp(
      kRegionMapZoomMultiplierMin,
      kRegionMapZoomMultiplierMax,
    );
    _syncCameraZoomFromMultiplier();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);

    final previousSize = _lastCanvasSize;
    _lastCanvasSize = size.clone();

    // If the map isn't ready yet, defer any camera logic.
    if (!_mapLoaded) {
      return;
    }

    // First resize with a valid size: clamp once so we don't start at (0, 0)
    // with visible black edges.
    if (previousSize == null || previousSize == Vector2.zero()) {
      _syncCameraZoomFromMultiplier();
      return;
    }

    final oldZoom = camera.viewfinder.zoom;
    if (oldZoom <= 0 || !oldZoom.isFinite) {
      _syncCameraZoomFromMultiplier();
      return;
    }

    final mapWidth = region.width * cellSizePx;
    final mapHeight = region.height * cellSizePx;

    final newZFit = computeRegionMapFitMapZoom(
      viewportWidthLogical: size.x,
      viewportHeightLogical: size.y,
      mapWidthWorld: mapWidth,
      mapHeightWorld: mapHeight,
    );
    _zoomMultiplier = _zoomMultiplier.clamp(
      kRegionMapZoomMultiplierMin,
      kRegionMapZoomMultiplierMax,
    );
    final newZoom = _zoomMultiplier * newZFit;

    final oldViewW = previousSize.x / oldZoom;
    final oldViewH = previousSize.y / oldZoom;
    final newViewW = size.x / newZoom;
    final newViewH = size.y / newZoom;

    var center = camera.viewfinder.position.clone();

    // Horizontal adjustment: preserve left edge when widening; clamp when shrinking.
    // Skip when the map is narrower than the viewport in world space (minX > maxX).
    if (newViewW != oldViewW && mapWidth > newViewW) {
      final halfNewW = newViewW / 2;
      final minX = halfNewW;
      final maxX = mapWidth - halfNewW;
      if (newViewW > oldViewW) {
        // Widening: keep previous left edge (if possible).
        final desired = center.x + (oldViewW - newViewW) / 2;
        center.x = desired.clamp(minX, maxX).toDouble();
      } else {
        // Shrinking: just clamp to new bounds.
        center.x = center.x.clamp(minX, maxX).toDouble();
      }
    }

    // Vertical adjustment: same policy for top edge.
    if (newViewH != oldViewH && mapHeight > newViewH) {
      final halfNewH = newViewH / 2;
      final minY = halfNewH;
      final maxY = mapHeight - halfNewH;
      if (newViewH > oldViewH) {
        final desired = center.y + (oldViewH - newViewH) / 2;
        center.y = desired.clamp(minY, maxY).toDouble();
      } else {
        center.y = center.y.clamp(minY, maxY).toDouble();
      }
    }

    camera.viewfinder.position = center;
    camera.viewfinder.zoom = newZoom;
    _clampCameraToMap();
    onRegionViewChanged?.call();
    _emitViewportSnapshot();
  }

  /// Update hover state from a widget-local position.
  void updateHoverFromLocal(Offset localPosition) {
    if (!_mapLoaded || size == Vector2.zero()) return;

    // Convert from widget-local (top-left origin) to world coordinates.
    final z = camera.viewfinder.zoom;
    if (z <= 0 || !z.isFinite) return;
    final screen = Vector2(localPosition.dx, localPosition.dy);
    final halfView = size / 2;
    final world = camera.viewfinder.position + (screen - halfView) / z;

    _mapComponent.updateHoverFromWorld(world);
  }

  @override
  void onTapUp(TapUpInfo info) {
    // Use same widget→world conversion as hover so tap works with camera zoom/pan
    // and on mobile (where hover is unavailable). SPEC/ui/province-sea-zone-detail-overlay.md.
    final z = camera.viewfinder.zoom;
    if (z <= 0 || !z.isFinite) return;
    final widgetPos = info.eventPosition.widget;
    final halfView = size / 2;
    final world = camera.viewfinder.position + (widgetPos - halfView) / z;
    _mapComponent.handleTapAtWorld(world);
    onRegionViewChanged?.call();
    _emitViewportSnapshot();
  }

  /// Constrain camera center so the viewport stays over the map.
  void _clampCameraToMap() {
    final mapWidth = region.width * cellSizePx;
    final mapHeight = region.height * cellSizePx;

    final z = camera.viewfinder.zoom;
    if (z <= 0 || !z.isFinite) return;

    // Viewport size in world units at current zoom.
    final viewW = size.x / z;
    final viewH = size.y / z;

    // If map is smaller than viewport on both axes, center the camera.
    if (mapWidth <= viewW && mapHeight <= viewH) {
      camera.viewfinder.position = Vector2(mapWidth / 2, mapHeight / 2);
      return;
    }

    final pos = camera.viewfinder.position.clone();
    if (mapWidth > viewW) {
      final halfW = viewW / 2;
      final minX = halfW;
      final maxX = mapWidth - halfW;
      pos.x = pos.x.clamp(minX, maxX).toDouble();
    } else {
      pos.x = mapWidth / 2;
    }
    if (mapHeight > viewH) {
      final halfH = viewH / 2;
      final minY = halfH;
      final maxY = mapHeight - halfH;
      pos.y = pos.y.clamp(minY, maxY).toDouble();
    } else {
      pos.y = mapHeight / 2;
    }

    camera.viewfinder.position = pos;
  }
}
