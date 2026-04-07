import 'dart:async';

import 'package:colonizethis_logic/colonizethis_logic.dart' show PlayerView;
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/services/subscription_tracker.dart';
import '../features/game/flame/region_map_component.dart';
import '../features/game/flame/region_map_viewport_snapshot.dart'
    show
        RegionMapViewportSnapshot,
        computeRegionMapFitMapZoom,
        kRegionMapZoomMultiplierMax,
        kRegionMapZoomMultiplierMin;

export '../features/game/flame/region_map_component.dart'
    show
        assertCtMapPlayerViewRequired,
        BaseLayerDisplayMode,
        CtMapVisibilityMode;

/// FlameGame host for the region map, with basic tap/drag/pinch wiring.
// ignore: deprecated_member_use
class _CtRegionMapGame extends FlameGame with TapDetector {
  _CtRegionMapGame({
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

  late final CtRegionMapComponent _mapComponent;

  /// `m` in [kRegionMapZoomMultiplierMin]–[kRegionMapZoomMultiplierMax]; camera zoom = `m × z_fit`.
  double _zoomMultiplier = 1.0;
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
          } else {
            onWorkTargetSelectionCancelled?.call();
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
    VoidCallback? onCivilianTileSelectionCleared,
    required PlayerView? playerViewForResources,
    void Function(RegionMapViewportSnapshot)? onViewportSnapshotChanged,
  }) {
    if (region != null) {
      if (region.regionId != this.region.regionId) {
        _zoomMultiplier = 1.0;
      }
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
    this.onCivilianTileSelectionCleared = onCivilianTileSelectionCleared;
    this.playerViewForResources = playerViewForResources;
    if (onViewportSnapshotChanged != null) {
      this.onViewportSnapshotChanged = onViewportSnapshotChanged;
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
        ..playerViewForResources = this.playerViewForResources;
      _emitViewportSnapshot();
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
  void onGameResize(Vector2 canvasSize) {
    super.onGameResize(canvasSize);

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

/// Flutter wrapper for the region map; renders via Flame. SPEC/ui/map-widget.md.
class CtRegionMap extends StatefulWidget {
  const CtRegionMap({
    super.key,
    required this.region,
    this.showPoliticalOverlay = true,
    this.showProvinceOverlay = true,
    this.showProvinceOwnershipTint = false,
    this.showProvinceNamesLayer = true,
    this.cellSizePx = 32,
    this.visibilityMode = CtMapVisibilityMode.full,
    this.baseLayerDisplayMode,
    this.onProvinceSelected,
    this.onMapTileTappedForDetail,
    this.onRegionViewChanged,
    this.onProvinceHovered,
    this.onTileHovered,
    this.onCivilianTileTapped,
    this.onCivilianTileSelectionCleared,
    this.selectedTileKey,
    this.selectedCivilianTileKey,
    this.secondaryHighlightTileKey,
    this.centerOnTileKey,
    this.validTileKeys,
    this.onTileSelected,
    this.onWorkTargetSelectionCancelled,
    this.bus,
    this.playerViewForResources,
    this.onViewportSnapshotChanged,
  });

  final RegionMapViewData region;
  final bool showPoliticalOverlay;
  final bool showProvinceOverlay;
  final bool showProvinceOwnershipTint;
  final bool showProvinceNamesLayer;
  final double cellSizePx;
  final CtMapVisibilityMode visibilityMode;

  /// When null, full detail (terrain + resources + improvements + roads) for backward compatibility.
  final BaseLayerDisplayMode? baseLayerDisplayMode;
  final void Function(String provinceId)? onProvinceSelected;
  final void Function(String tileKey)? onMapTileTappedForDetail;
  final VoidCallback? onRegionViewChanged;
  final void Function(String? provinceId)? onProvinceHovered;
  final void Function(String? tileKey)? onTileHovered;
  final void Function(String tileKey)? onCivilianTileTapped;
  final VoidCallback? onCivilianTileSelectionCleared;
  final String? selectedTileKey;
  final String? selectedCivilianTileKey;
  final String? secondaryHighlightTileKey;
  final String? centerOnTileKey;
  final Set<String>? validTileKeys;
  final void Function(String tileKey)? onTileSelected;
  final VoidCallback? onWorkTargetSelectionCancelled;

  /// Optional event bus for emitting town icon tap events.
  /// When provided, tapping a town/port icon emits OpenProvinceDetailPanelEvent.
  final AppEventBus? bus;

  /// Required when [visibilityMode] is [CtMapVisibilityMode.playerConstrained].
  final PlayerView? playerViewForResources;

  /// Optional: notified when the camera viewport changes (for region minimap sync).
  final void Function(RegionMapViewportSnapshot viewport)?
  onViewportSnapshotChanged;

  @override
  State<CtRegionMap> createState() => _CtRegionMapState();
}

class _CtRegionMapState extends State<CtRegionMap> {
  late _CtRegionMapGame _game;
  final SubscriptionTracker _subscriptions = SubscriptionTracker();
  double _scaleGestureStartMultiplier = 1.0;

  @override
  void initState() {
    super.initState();
    _game = _buildGame();
    _attachMinimapCameraBusSubscriptions();
  }

  @override
  void dispose() {
    _subscriptions.cancelAll();
    super.dispose();
  }

  void _attachMinimapCameraBusSubscriptions() {
    _subscriptions.cancelAll();
    final b = widget.bus;
    if (b == null) return;
    _subscriptions.track(
      b.on<RequestRegionMapCameraCenterWorldEvent>().listen((e) {
        if (!mounted || e.regionId != widget.region.regionId) return;
        _game.setCameraCenterWorld(e.worldCenterX, e.worldCenterY);
      }),
    );
    _subscriptions.track(
      b.on<RequestRegionMapCameraPanWorldDeltaEvent>().listen((e) {
        if (!mounted || e.regionId != widget.region.regionId) return;
        _game.panCameraWorld(e.worldDx, e.worldDy);
      }),
    );
    _subscriptions.track(
      b.on<RequestRegionMapSetZoomMultiplierEvent>().listen((e) {
        if (!mounted || e.regionId != widget.region.regionId) return;
        _game.setZoomMultiplierAbsolute(e.zoomMultiplier);
      }),
    );
  }

  @override
  void didUpdateWidget(covariant CtRegionMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.region != oldWidget.region ||
        widget.showPoliticalOverlay != oldWidget.showPoliticalOverlay ||
        widget.showProvinceOverlay != oldWidget.showProvinceOverlay ||
        widget.showProvinceOwnershipTint !=
            oldWidget.showProvinceOwnershipTint ||
        widget.showProvinceNamesLayer != oldWidget.showProvinceNamesLayer ||
        widget.visibilityMode != oldWidget.visibilityMode ||
        widget.baseLayerDisplayMode != oldWidget.baseLayerDisplayMode ||
        widget.validTileKeys != oldWidget.validTileKeys ||
        widget.onCivilianTileTapped != oldWidget.onCivilianTileTapped ||
        widget.onCivilianTileSelectionCleared !=
            oldWidget.onCivilianTileSelectionCleared ||
        widget.selectedTileKey != oldWidget.selectedTileKey ||
        widget.selectedCivilianTileKey != oldWidget.selectedCivilianTileKey ||
        widget.secondaryHighlightTileKey !=
            oldWidget.secondaryHighlightTileKey ||
        widget.onTileSelected != oldWidget.onTileSelected ||
        widget.onWorkTargetSelectionCancelled !=
            oldWidget.onWorkTargetSelectionCancelled ||
        widget.playerViewForResources != oldWidget.playerViewForResources ||
        widget.onViewportSnapshotChanged !=
            oldWidget.onViewportSnapshotChanged) {
      _game.updateProps(
        region: widget.region,
        showPoliticalOverlay: widget.showPoliticalOverlay,
        showProvinceOverlay: widget.showProvinceOverlay,
        showProvinceOwnershipTint: widget.showProvinceOwnershipTint,
        showProvinceNamesLayer: widget.showProvinceNamesLayer,
        visibilityMode: widget.visibilityMode,
        baseLayerDisplayMode:
            widget.baseLayerDisplayMode ??
            BaseLayerDisplayMode.terrainAndResourcesImprovementsRoads,
        selectedTileKey: widget.selectedTileKey,
        clearSelectedTileKey: widget.selectedTileKey == null,
        selectedCivilianTileKey: widget.selectedCivilianTileKey,
        clearSelectedCivilianTileKey: widget.selectedCivilianTileKey == null,
        secondaryHighlightTileKey: widget.secondaryHighlightTileKey,
        clearSecondaryHighlightTileKey:
            widget.secondaryHighlightTileKey == null,
        validTileKeys: widget.validTileKeys,
        clearValidTileKeys:
            widget.validTileKeys == null && oldWidget.validTileKeys != null,
        onTileSelected: widget.onTileSelected,
        onWorkTargetSelectionCancelled: widget.onWorkTargetSelectionCancelled,
        onCivilianTileTapped: widget.onCivilianTileTapped,
        onCivilianTileSelectionCleared: widget.onCivilianTileSelectionCleared,
        playerViewForResources: widget.playerViewForResources,
        onViewportSnapshotChanged: widget.onViewportSnapshotChanged,
      );
    }
    if (widget.bus != oldWidget.bus) {
      _attachMinimapCameraBusSubscriptions();
    }
    if (widget.centerOnTileKey != null &&
        widget.centerOnTileKey != oldWidget.centerOnTileKey) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _game.centerOnTileKey(widget.centerOnTileKey!);
      });
    }
  }

  _CtRegionMapGame _buildGame() {
    return _CtRegionMapGame(
      region: widget.region,
      cellSizePx: widget.cellSizePx,
      showPoliticalOverlay: widget.showPoliticalOverlay,
      showProvinceOverlay: widget.showProvinceOverlay,
      showProvinceOwnershipTint: widget.showProvinceOwnershipTint,
      showProvinceNamesLayer: widget.showProvinceNamesLayer,
      visibilityMode: widget.visibilityMode,
      baseLayerDisplayMode:
          widget.baseLayerDisplayMode ??
          BaseLayerDisplayMode.terrainAndResourcesImprovementsRoads,
      onProvinceSelected: widget.onProvinceSelected,
      onMapTileTappedForDetail: widget.onMapTileTappedForDetail,
      onRegionViewChanged: widget.onRegionViewChanged,
      onProvinceHovered: widget.onProvinceHovered,
      onTileHovered: widget.onTileHovered,
      onCivilianTileTapped: widget.onCivilianTileTapped,
      onCivilianTileSelectionCleared: widget.onCivilianTileSelectionCleared,
      selectedTileKey: widget.selectedTileKey,
      selectedCivilianTileKey: widget.selectedCivilianTileKey,
      secondaryHighlightTileKey: widget.secondaryHighlightTileKey,
      validTileKeys: widget.validTileKeys,
      onTileSelected: widget.onTileSelected,
      onWorkTargetSelectionCancelled: widget.onWorkTargetSelectionCancelled,
      onTownIconTapped: widget.bus != null
          ? (provinceId) {
              widget.bus!.emit(OpenProvinceDetailPanelEvent(provinceId));
            }
          : null,
      playerViewForResources: widget.playerViewForResources,
      onViewportSnapshotChanged: widget.onViewportSnapshotChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    assertCtMapPlayerViewRequired(
      visibilityMode: widget.visibilityMode,
      playerViewForResources: widget.playerViewForResources,
    );
    return Focus(
      autofocus: true,
      child: CallbackShortcuts(
        bindings: <ShortcutActivator, VoidCallback>{
          // Zoom in
          const SingleActivator(LogicalKeyboardKey.equal): () =>
              _game.zoomBy(1.1),
          const SingleActivator(LogicalKeyboardKey.add): () =>
              _game.zoomBy(1.1),
          const SingleActivator(LogicalKeyboardKey.numpadAdd): () =>
              _game.zoomBy(1.1),
          // Zoom out
          const SingleActivator(LogicalKeyboardKey.minus): () =>
              _game.zoomBy(0.9),
          const SingleActivator(LogicalKeyboardKey.numpadSubtract): () =>
              _game.zoomBy(0.9),
        },
        child: Listener(
          onPointerSignal: (event) {
            if (event is PointerScrollEvent) {
              final dx = event.scrollDelta.dx;
              final dy = event.scrollDelta.dy;
              // Pick the dominant scroll axis; treat horizontal as zoom as well (Magic Mouse support).
              final primary = dy.abs() >= dx.abs() ? dy : -dx;
              if (primary == 0) return;
              final factor = primary < 0 ? 1.1 : 0.9;
              _game.zoomBy(factor);
            }
          },
          child: MouseRegion(
            onHover: (event) => _game.updateHoverFromLocal(event.localPosition),
            onExit: (_) => _game.updateHoverFromLocal(const Offset(-1, -1)),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onScaleStart: (_) {
                _scaleGestureStartMultiplier = _game.zoomMultiplier;
              },
              onScaleUpdate: (details) {
                if (details.pointerCount > 1) {
                  _game.setZoomMultiplierAbsolute(
                    _scaleGestureStartMultiplier * details.scale,
                  );
                }
                _game.panBy(details.focalPointDelta);
              },
              child: ClipRect(child: GameWidget(game: _game)),
            ),
          ),
        ),
      ),
    );
  }
}
