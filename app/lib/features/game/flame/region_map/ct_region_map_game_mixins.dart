import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart' show Offset;

import 'ct_region_map_game_camera.dart';
import 'ct_region_map_game_fields.dart';
import 'region_map_component.dart';
import 'region_map_component_secondary.dart';

export 'ct_region_map_game_camera.dart';
export 'ct_region_map_game_fields.dart';

// ignore_for_file: deprecated_member_use

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
