import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart'
    show MapBaseLayerFlags;
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart' show visibleForTesting, VoidCallback;
import 'package:flutter/material.dart' show Offset;

import 'ct_region_map_game_state.dart';
import 'region_map_component.dart';
import 'region_map_component_secondary.dart';
import 'region_map_viewport_snapshot.dart'
    show
        RegionMapViewportSnapshot,
        computeRegionMapFitMapZoom,
        kRegionMapZoomMultiplierMax,
        kRegionMapZoomMultiplierMin;
import 'package:colonizethis_world/colonizethis_world.dart' show PlayerView;

// ignore_for_file: deprecated_member_use

/// Mutable session fields for de-parted [CtRegionMapGame] libraries (Refs #4117).
mixin CtRegionMapGameFields on FlameGame {
  final CtRegionMapGameState state = CtRegionMapGameState();

  late RegionMapViewData region;
  late double cellSizePx;
  late bool showPoliticalOverlay;
  late bool showProvinceOverlay;
  late bool showProvinceOwnershipTint;
  late bool showProvinceNamesLayer;
  bool showCapitalLinkDisconnectedHighlight = true;
  late CtMapVisibilityMode visibilityMode;
  late MapBaseLayerFlags mapBaseLayerFlags;
  late BaseLayerDisplayMode baseLayerDisplayMode;
  void Function(String provinceId)? onProvinceSelected;
  void Function(String tileKey)? onMapTileTappedForDetail;
  void Function(String tileKey, Offset localPosition)?
  onMapTileSecondaryForRadial;
  bool suppressNextPrimaryTap = false;
  VoidCallback? onRegionViewChanged;
  void Function(String? provinceId)? onProvinceHovered;
  void Function(String? tileKey)? onTileHovered;
  void Function(String tileKey)? onCivilianTileTapped;
  void Function(
    String locationScopeKey,
    List<String> fleetIds,
    String markerTileKey,
  )?
  onFleetMarkerTapped;
  void Function(ArmyTileMarkerView marker)? onArmyMarkerTapped;
  VoidCallback? onCivilianTileSelectionCleared;
  String? selectedTileKey;
  String? selectedCivilianTileKey;
  String? secondaryHighlightTileKey;
  Set<String>? secondaryHighlightTileKeys;
  Set<String>? validTileKeys;
  String? lastTurnPulseTileKey;
  void Function(String tileKey)? onTileSelected;
  VoidCallback? onWorkTargetSelectionCancelled;
  void Function(String provinceId)? onTownIconTapped;
  PlayerView? playerViewForResources;
  void Function(RegionMapViewportSnapshot)? onViewportSnapshotChanged;
  bool showPlayerTerritoryOutline = false;
  Set<String>? playerTerritoryTileKeys;

  @visibleForTesting
  CtRegionMapComponent get debugMapComponentForTest => state.mapComponent;

  double get zoomMultiplier => state.zoomMultiplier;
}

mixin CtRegionMapGameCamera on CtRegionMapGameFields {
  void syncCameraZoomFromMultiplier() {
    if (!state.mapLoaded || size == Vector2.zero()) return;
    state.zoomMultiplier = state.zoomMultiplier.clamp(
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
    camera.viewfinder.zoom = state.zoomMultiplier * zFit;
    clampCameraToMap();
    onRegionViewChanged?.call();
    emitViewportSnapshot();
  }

  void emitViewportSnapshot() {
    final cb = onViewportSnapshotChanged;
    if (cb == null) return;
    if (!state.mapLoaded || size == Vector2.zero()) return;
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

  void handleGameResize(Vector2 size, Vector2? previousSize) {
    if (!state.mapLoaded) return;
    if (previousSize == null || previousSize == Vector2.zero()) {
      syncCameraZoomFromMultiplier();
      return;
    }
    final oldZoom = camera.viewfinder.zoom;
    if (oldZoom <= 0 || !oldZoom.isFinite) {
      syncCameraZoomFromMultiplier();
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
    state.zoomMultiplier = state.zoomMultiplier.clamp(
      kRegionMapZoomMultiplierMin,
      kRegionMapZoomMultiplierMax,
    );
    final newZoom = state.zoomMultiplier * newZFit;
    final oldViewW = previousSize.x / oldZoom;
    final oldViewH = previousSize.y / oldZoom;
    final newViewW = size.x / newZoom;
    final newViewH = size.y / newZoom;
    var center = camera.viewfinder.position.clone();
    if (newViewW != oldViewW && mapWidth > newViewW) {
      final halfNewW = newViewW / 2;
      final minX = halfNewW;
      final maxX = mapWidth - halfNewW;
      if (newViewW > oldViewW) {
        center.x = (center.x + (oldViewW - newViewW) / 2)
            .clamp(minX, maxX)
            .toDouble();
      } else {
        center.x = center.x.clamp(minX, maxX).toDouble();
      }
    }
    if (newViewH != oldViewH && mapHeight > newViewH) {
      final halfNewH = newViewH / 2;
      final minY = halfNewH;
      final maxY = mapHeight - halfNewH;
      if (newViewH > oldViewH) {
        center.y = (center.y + (oldViewH - newViewH) / 2)
            .clamp(minY, maxY)
            .toDouble();
      } else {
        center.y = center.y.clamp(minY, maxY).toDouble();
      }
    }
    camera.viewfinder.position = center;
    camera.viewfinder.zoom = newZoom;
    clampCameraToMap();
    onRegionViewChanged?.call();
    emitViewportSnapshot();
  }

  void clampCameraToMap() {
    final mapWidth = region.width * cellSizePx;
    final mapHeight = region.height * cellSizePx;
    final z = camera.viewfinder.zoom;
    if (z <= 0 || !z.isFinite) return;
    final viewW = size.x / z;
    final viewH = size.y / z;
    if (mapWidth <= viewW && mapHeight <= viewH) {
      camera.viewfinder.position = Vector2(mapWidth / 2, mapHeight / 2);
      return;
    }
    final pos = camera.viewfinder.position.clone();
    if (mapWidth > viewW) {
      final halfW = viewW / 2;
      pos.x = pos.x.clamp(halfW, mapWidth - halfW).toDouble();
    } else {
      pos.x = mapWidth / 2;
    }
    if (mapHeight > viewH) {
      final halfH = viewH / 2;
      pos.y = pos.y.clamp(halfH, mapHeight - halfH).toDouble();
    } else {
      pos.y = mapHeight / 2;
    }
    camera.viewfinder.position = pos;
  }
}

mixin CtRegionMapGameLifecycle on CtRegionMapGameFields, CtRegionMapGameCamera {
  Future<void> onLoadRegionMapBody() async {
    state.mapComponent = CtRegionMapComponent(
      region: region,
      cellSize: cellSizePx,
      showPoliticalOverlay: showPoliticalOverlay,
      showProvinceOverlay: showProvinceOverlay,
      showProvinceOwnershipTint: showProvinceOwnershipTint,
      showProvinceNamesLayer: showProvinceNamesLayer,
      showCapitalLinkDisconnectedHighlight:
          showCapitalLinkDisconnectedHighlight,
      visibilityMode: visibilityMode,
      mapBaseLayerFlags: mapBaseLayerFlags,
      baseLayerDisplayMode: baseLayerDisplayMode,
      onProvinceSelected: onProvinceSelected,
      onMapTileTappedForDetail: onMapTileTappedForDetail,
      onProvinceHovered: onProvinceHovered,
      onTileHovered: onTileHovered,
      onCivilianTileTapped: onCivilianTileTapped,
      onFleetMarkerTapped: onFleetMarkerTapped,
      onArmyMarkerTapped: onArmyMarkerTapped,
      onCivilianTileSelectionCleared: onCivilianTileSelectionCleared,
      selectedTileKey: selectedTileKey,
      selectedCivilianTileKey: selectedCivilianTileKey,
      secondaryHighlightTileKey: secondaryHighlightTileKey,
      secondaryHighlightTileKeys: secondaryHighlightTileKeys,
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
      lastTurnPulseTileKey: lastTurnPulseTileKey,
      onTownIconTapped: onTownIconTapped,
      playerViewForResources: playerViewForResources,
      showPlayerTerritoryOutline: showPlayerTerritoryOutline,
      playerTerritoryTileKeys: playerTerritoryTileKeys,
    )..position = Vector2.zero();
    await world.add(state.mapComponent);
    state.mapLoaded = true;
    if (size != Vector2.zero()) {
      syncCameraZoomFromMultiplier();
    } else {
      emitViewportSnapshot();
    }
  }

  void updateRegionMapGame(double dt) {
    if (!state.mapLoaded) return;
    final z = camera.viewfinder.zoom;
    state.mapComponent.cameraZoom = z.isFinite && z > 0 ? z : 1.0;
  }

  void handleRegionMapGameResize(Vector2 size, Vector2? previousSize) {
    state.lastCanvasSize = size.clone();
    handleGameResize(size, previousSize);
  }

  void handleRegionMapTapUp(TapUpInfo info) {
    if (suppressNextPrimaryTap) {
      suppressNextPrimaryTap = false;
      return;
    }
    final z = camera.viewfinder.zoom;
    if (z <= 0 || !z.isFinite) return;
    final widgetPos = info.eventPosition.widget;
    final halfView = size / 2;
    final world = camera.viewfinder.position + (widgetPos - halfView) / z;
    state.mapComponent.handleTapAtWorld(world);
    onRegionViewChanged?.call();
    emitViewportSnapshot();
  }

  void handleRegionMapSecondaryFromLocal(Offset localPosition) {
    if (!state.mapLoaded || size == Vector2.zero()) return;
    final z = camera.viewfinder.zoom;
    if (z <= 0 || !z.isFinite) return;
    final screen = Vector2(localPosition.dx, localPosition.dy);
    final halfView = size / 2;
    final world = camera.viewfinder.position + (screen - halfView) / z;
    final tileKey = ctRegionMapComponentTileKeyForSecondaryAtWorld(
      state.mapComponent,
      world,
    );
    if (tileKey == null) return;
    onMapTileSecondaryForRadial?.call(tileKey, localPosition);
  }
}
