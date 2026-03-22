import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../features/game/flame/region_map_component.dart';

export '../features/game/flame/region_map_component.dart'
    show BaseLayerDisplayMode, CtMapVisibilityMode;

/// FlameGame host for the region map, with basic tap/drag/pinch wiring.
class _CtRegionMapGame extends FlameGame with TapDetector {
  _CtRegionMapGame({
    required RegionMapViewData region,
    required double cellSizePx,
    required bool showPoliticalOverlay,
    required bool showBordersLayer,
    required CtMapVisibilityMode visibilityMode,
    BaseLayerDisplayMode baseLayerDisplayMode =
        BaseLayerDisplayMode.terrainResourcesImprovements,
    required void Function(String provinceId)? onProvinceSelected,
    void Function(String tileKey)? onMapTileTappedForDetail,
    required VoidCallback? onRegionViewChanged,
    required void Function(String? provinceId)? onProvinceHovered,
    required void Function(String? tileKey)? onTileHovered,
    required String? selectedTileKey,
    required String? secondaryHighlightTileKey,
    required Set<String>? validTileKeys,
    required void Function(String tileKey)? onTileSelected,
    required VoidCallback? onWorkTargetSelectionCancelled,
  }) : region = region,
       cellSizePx = cellSizePx,
       showPoliticalOverlay = showPoliticalOverlay,
       showBordersLayer = showBordersLayer,
       visibilityMode = visibilityMode,
       baseLayerDisplayMode = baseLayerDisplayMode,
       onProvinceSelected = onProvinceSelected,
       onMapTileTappedForDetail = onMapTileTappedForDetail,
       onRegionViewChanged = onRegionViewChanged,
       onProvinceHovered = onProvinceHovered,
       onTileHovered = onTileHovered,
       selectedTileKey = selectedTileKey,
       secondaryHighlightTileKey = secondaryHighlightTileKey,
       validTileKeys = validTileKeys,
       onTileSelected = onTileSelected,
       onWorkTargetSelectionCancelled = onWorkTargetSelectionCancelled;

  RegionMapViewData region;
  final double cellSizePx;
  bool showPoliticalOverlay;
  bool showBordersLayer;
  CtMapVisibilityMode visibilityMode;
  BaseLayerDisplayMode baseLayerDisplayMode;
  void Function(String provinceId)? onProvinceSelected;
  void Function(String tileKey)? onMapTileTappedForDetail;
  VoidCallback? onRegionViewChanged;
  void Function(String? provinceId)? onProvinceHovered;
  void Function(String? tileKey)? onTileHovered;
  String? selectedTileKey;
  String? secondaryHighlightTileKey;
  Set<String>? validTileKeys;
  void Function(String tileKey)? onTileSelected;
  VoidCallback? onWorkTargetSelectionCancelled;

  late final CtRegionMapComponent _mapComponent;

  double _zoom = 1.0;
  bool _mapLoaded = false;
  Vector2? _lastCanvasSize;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _mapComponent = CtRegionMapComponent(
      region: region,
      cellSize: cellSizePx,
      showPoliticalOverlay: showPoliticalOverlay,
      showBordersLayer: showBordersLayer,
      visibilityMode: visibilityMode,
      baseLayerDisplayMode: baseLayerDisplayMode,
      onProvinceSelected: onProvinceSelected,
      onMapTileTappedForDetail: onMapTileTappedForDetail,
      onProvinceHovered: onProvinceHovered,
      onTileHovered: onTileHovered,
      selectedTileKey: selectedTileKey,
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
    )..position = Vector2.zero();
    await world.add(_mapComponent);
    _mapLoaded = true;

    // Initial camera clamp once size is available to avoid black bands on first paint.
    if (size != Vector2.zero()) {
      _clampCameraToMap();
    }
  }

  /// Update map configuration without recreating the game.
  void updateProps({
    RegionMapViewData? region,
    bool? showPoliticalOverlay,
    bool? showBordersLayer,
    CtMapVisibilityMode? visibilityMode,
    BaseLayerDisplayMode? baseLayerDisplayMode,
    String? selectedTileKey,
    String? secondaryHighlightTileKey,
    bool clearSelectedTileKey = false,
    bool clearSecondaryHighlightTileKey = false,
    Set<String>? validTileKeys,
    bool clearValidTileKeys = false,
    void Function(String tileKey)? onTileSelected,
    VoidCallback? onWorkTargetSelectionCancelled,
  }) {
    if (region != null) {
      this.region = region;
    }
    if (showPoliticalOverlay != null) {
      this.showPoliticalOverlay = showPoliticalOverlay;
    }
    if (showBordersLayer != null) {
      this.showBordersLayer = showBordersLayer;
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

    if (_mapLoaded) {
      _mapComponent
        ..region = this.region
        ..cellSize = cellSizePx
        ..showPoliticalOverlay = this.showPoliticalOverlay
        ..showBordersLayer = this.showBordersLayer
        ..visibilityMode = this.visibilityMode
        ..baseLayerDisplayMode = this.baseLayerDisplayMode
        ..selectedTileKey = this.selectedTileKey
        ..secondaryHighlightTileKey = this.secondaryHighlightTileKey
        ..validTileKeys = this.validTileKeys;
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
    onRegionViewChanged?.call();
  }

  /// Pan the camera by a Flutter offset (in logical pixels).
  void panBy(Offset delta) {
    if (delta == Offset.zero) return;
    camera.viewfinder.position -= Vector2(delta.dx, delta.dy) / _zoom;
    _clampCameraToMap();
    onRegionViewChanged?.call();
  }

  /// Zoom the camera by [factor] (>1 zooms in, <1 zooms out).
  void zoomBy(double factor) {
    _applyZoom(factor);
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
      _clampCameraToMap();
      return;
    }

    final oldViewW = previousSize.x / _zoom;
    final oldViewH = previousSize.y / _zoom;
    final newViewW = size.x / _zoom;
    final newViewH = size.y / _zoom;

    final mapWidth = region.width * cellSizePx;
    final mapHeight = region.height * cellSizePx;

    var center = camera.viewfinder.position.clone();

    // Horizontal adjustment: preserve left edge when widening; clamp when shrinking.
    if (newViewW != oldViewW) {
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
    if (newViewH != oldViewH) {
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
  }

  /// Update hover state from a widget-local position.
  void updateHoverFromLocal(Offset localPosition) {
    if (!_mapLoaded || size == Vector2.zero()) return;

    // Convert from widget-local (top-left origin) to world coordinates.
    final screen = Vector2(localPosition.dx, localPosition.dy);
    final halfView = size / 2;
    final world = camera.viewfinder.position + (screen - halfView) / _zoom;

    _mapComponent.updateHoverFromWorld(world);
  }

  @override
  void onTapUp(TapUpInfo info) {
    // Use same widget→world conversion as hover so tap works with camera zoom/pan
    // and on mobile (where hover is unavailable). SPEC/ui/province-sea-zone-detail-overlay.md.
    final widgetPos = info.eventPosition.widget;
    final halfView = size / 2;
    final world = camera.viewfinder.position + (widgetPos - halfView) / _zoom;
    _mapComponent.handleTapAtWorld(world);
    onRegionViewChanged?.call();
  }

  void _applyZoom(double scaleDelta) {
    final newZoom = (_zoom * scaleDelta).clamp(0.25, 1.0);
    if (newZoom == _zoom) return;
    _zoom = newZoom;
    camera.viewfinder.zoom = _zoom;
    _clampCameraToMap();
    onRegionViewChanged?.call();
  }

  /// Constrain camera center so the viewport stays over the map.
  void _clampCameraToMap() {
    final mapWidth = region.width * cellSizePx;
    final mapHeight = region.height * cellSizePx;

    // Viewport size in world units at current zoom.
    final viewW = size.x / _zoom;
    final viewH = size.y / _zoom;

    // If map is smaller than viewport, center the camera.
    if (mapWidth <= viewW && mapHeight <= viewH) {
      camera.viewfinder.position = Vector2(mapWidth / 2, mapHeight / 2);
      return;
    }

    final halfW = viewW / 2;
    final halfH = viewH / 2;

    final minX = halfW;
    final maxX = mapWidth - halfW;
    final minY = halfH;
    final maxY = mapHeight - halfH;

    final pos = camera.viewfinder.position;
    final clampedX = pos.x.clamp(minX, maxX);
    final clampedY = pos.y.clamp(minY, maxY);

    camera.viewfinder.position = Vector2(
      clampedX.toDouble(),
      clampedY.toDouble(),
    );
  }
}

/// Flutter wrapper for the region map; renders via Flame. SPEC/ui/map-widget.md.
class CtRegionMap extends StatefulWidget {
  const CtRegionMap({
    super.key,
    required this.region,
    this.showPoliticalOverlay = true,
    this.showBordersLayer = true,
    this.cellSizePx = 32,
    this.visibilityMode = CtMapVisibilityMode.full,
    this.baseLayerDisplayMode,
    this.onProvinceSelected,
    this.onMapTileTappedForDetail,
    this.onRegionViewChanged,
    this.onProvinceHovered,
    this.onTileHovered,
    this.selectedTileKey,
    this.secondaryHighlightTileKey,
    this.centerOnTileKey,
    this.validTileKeys,
    this.onTileSelected,
    this.onWorkTargetSelectionCancelled,
  });

  final RegionMapViewData region;
  final bool showPoliticalOverlay;
  final bool showBordersLayer;
  final double cellSizePx;
  final CtMapVisibilityMode visibilityMode;

  /// When null, full letters (terrain + resources + improvements) for backward compatibility.
  final BaseLayerDisplayMode? baseLayerDisplayMode;
  final void Function(String provinceId)? onProvinceSelected;
  final void Function(String tileKey)? onMapTileTappedForDetail;
  final VoidCallback? onRegionViewChanged;
  final void Function(String? provinceId)? onProvinceHovered;
  final void Function(String? tileKey)? onTileHovered;
  final String? selectedTileKey;
  final String? secondaryHighlightTileKey;
  final String? centerOnTileKey;
  final Set<String>? validTileKeys;
  final void Function(String tileKey)? onTileSelected;
  final VoidCallback? onWorkTargetSelectionCancelled;

  @override
  State<CtRegionMap> createState() => _CtRegionMapState();
}

class _CtRegionMapState extends State<CtRegionMap> {
  late _CtRegionMapGame _game;

  @override
  void initState() {
    super.initState();
    _game = _buildGame();
  }

  @override
  void didUpdateWidget(covariant CtRegionMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.region != oldWidget.region ||
        widget.showPoliticalOverlay != oldWidget.showPoliticalOverlay ||
        widget.showBordersLayer != oldWidget.showBordersLayer ||
        widget.visibilityMode != oldWidget.visibilityMode ||
        widget.baseLayerDisplayMode != oldWidget.baseLayerDisplayMode ||
        widget.validTileKeys != oldWidget.validTileKeys ||
        widget.selectedTileKey != oldWidget.selectedTileKey ||
        widget.secondaryHighlightTileKey !=
            oldWidget.secondaryHighlightTileKey ||
        widget.onTileSelected != oldWidget.onTileSelected ||
        widget.onWorkTargetSelectionCancelled !=
            oldWidget.onWorkTargetSelectionCancelled) {
      _game.updateProps(
        region: widget.region,
        showPoliticalOverlay: widget.showPoliticalOverlay,
        showBordersLayer: widget.showBordersLayer,
        visibilityMode: widget.visibilityMode,
        baseLayerDisplayMode:
            widget.baseLayerDisplayMode ??
            BaseLayerDisplayMode.terrainResourcesImprovements,
        selectedTileKey: widget.selectedTileKey,
        clearSelectedTileKey: widget.selectedTileKey == null,
        secondaryHighlightTileKey: widget.secondaryHighlightTileKey,
        clearSecondaryHighlightTileKey:
            widget.secondaryHighlightTileKey == null,
        validTileKeys: widget.validTileKeys,
        clearValidTileKeys:
            widget.validTileKeys == null && oldWidget.validTileKeys != null,
        onTileSelected: widget.onTileSelected,
        onWorkTargetSelectionCancelled: widget.onWorkTargetSelectionCancelled,
      );
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
      showBordersLayer: widget.showBordersLayer,
      visibilityMode: widget.visibilityMode,
      baseLayerDisplayMode:
          widget.baseLayerDisplayMode ??
          BaseLayerDisplayMode.terrainResourcesImprovements,
      onProvinceSelected: widget.onProvinceSelected,
      onMapTileTappedForDetail: widget.onMapTileTappedForDetail,
      onRegionViewChanged: widget.onRegionViewChanged,
      onProvinceHovered: widget.onProvinceHovered,
      onTileHovered: widget.onTileHovered,
      selectedTileKey: widget.selectedTileKey,
      secondaryHighlightTileKey: widget.secondaryHighlightTileKey,
      validTileKeys: widget.validTileKeys,
      onTileSelected: widget.onTileSelected,
      onWorkTargetSelectionCancelled: widget.onWorkTargetSelectionCancelled,
    );
  }

  @override
  Widget build(BuildContext context) {
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
              // Drag to pan the map.
              onPanUpdate: (details) {
                _game.panBy(details.delta);
              },
              child: ClipRect(child: GameWidget(game: _game)),
            ),
          ),
        ),
      ),
    );
  }
}
