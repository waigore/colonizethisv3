part of 'ct_region_map_game.dart';

extension _CtRegionMapGameLifecycle on CtRegionMapGame {
  Future<void> onLoadRegionMapBody() async {
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

  void updateRegionMapGame(double dt) {
    if (_mapLoaded) {
      final z = camera.viewfinder.zoom;
      _mapComponent.cameraZoom = z.isFinite && z > 0 ? z : 1.0;
    }
  }

  void handleRegionMapGameResize(Vector2 size, Vector2? previousSize) {
    _lastCanvasSize = size.clone();
    _handleGameResize(size, previousSize);
  }

  void handleRegionMapTapUp(TapUpInfo info) {
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
