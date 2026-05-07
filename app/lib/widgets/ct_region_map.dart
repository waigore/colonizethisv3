import 'package:colonizethis_logic/colonizethis_logic.dart' show PlayerView;
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/services/region_map_widget_bindings.dart';
import '../core/services/subscription_tracker.dart';

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
    this.onCivilianTileStateChanged,
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
    this.zoomMultiplier,
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
  final void Function(String tileKey)? onCivilianTileStateChanged;
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
  final double? zoomMultiplier;

  @override
  State<CtRegionMap> createState() => _CtRegionMapState();
}

class _CtRegionMapState extends State<CtRegionMap> {
  late CtRegionMapGame _game;
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
        widget.onCivilianTileStateChanged !=
            oldWidget.onCivilianTileStateChanged ||
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
            oldWidget.onViewportSnapshotChanged ||
        widget.zoomMultiplier != oldWidget.zoomMultiplier) {
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
        onCivilianTileTapped: _handleCivilianTileTapped,
        onFleetMarkerTapped: _handleFleetMarkerTapped,
        onCivilianTileSelectionCleared: widget.onCivilianTileSelectionCleared,
        playerViewForResources: widget.playerViewForResources,
        onViewportSnapshotChanged: widget.onViewportSnapshotChanged,
        zoomMultiplier: widget.zoomMultiplier,
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

  CtRegionMapGame _buildGame() {
    return defaultCreateCtRegionMapGame(
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
      onCivilianTileTapped: _handleCivilianTileTapped,
      onFleetMarkerTapped: _handleFleetMarkerTapped,
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
      initialZoomMultiplier: widget.zoomMultiplier ?? 1.0,
    );
  }

  void _handleCivilianTileTapped(String tileKey) {
    widget.onCivilianTileStateChanged?.call(tileKey);
    final bus = widget.bus;
    if (bus == null) {
      return;
    }
    String? initialSelectedUnitId;
    for (final marker in widget.region.civilianTileMarkers) {
      if (marker.tileKey == tileKey && marker.unitIds.isNotEmpty) {
        initialSelectedUnitId = marker.unitIds.first;
        break;
      }
    }
    bus.emit(
      OpenCivilianUnitsPanelEvent(
        tileScopeTileKey: tileKey,
        initialSelectedUnitId: initialSelectedUnitId,
      ),
    );
  }

  void _handleFleetMarkerTapped(
    String locationScopeKey,
    String? initialFleetId,
    String markerTileKey,
  ) {
    widget.bus?.emit(
      OpenNavalUnitsPanelEvent(
        locationScopeKey: locationScopeKey,
        initialSelectedFleetId: initialFleetId,
        tileScopeTileKey: markerTileKey,
      ),
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
              child: buildRegionMapGameViewport(_game),
            ),
          ),
        ),
      ),
    );
  }
}
