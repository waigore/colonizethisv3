part of 'ct_region_map.dart';

void _attachMinimapCameraBusSubscriptions(_CtRegionMapState state) {
  state._subscriptions.cancelAll();
  final b = state.widget.bus;
  if (b == null) return;
  state._subscriptions.track(
    b.on<RequestRegionMapCameraCenterWorldEvent>().listen((e) {
      if (!state.mounted || e.regionId != state.widget.region.regionId) return;
      state._game.setCameraCenterWorld(e.worldCenterX, e.worldCenterY);
    }),
  );
  state._subscriptions.track(
    b.on<RequestRegionMapCameraPanWorldDeltaEvent>().listen((e) {
      if (!state.mounted || e.regionId != state.widget.region.regionId) return;
      state._game.panCameraWorld(e.worldDx, e.worldDy);
    }),
  );
  state._subscriptions.track(
    b.on<RequestRegionMapSetZoomMultiplierEvent>().listen((e) {
      if (!state.mounted || e.regionId != state.widget.region.regionId) return;
      state._game.setZoomMultiplierAbsolute(e.zoomMultiplier);
    }),
  );
}

CtRegionMapGame _buildCtRegionMapGame(_CtRegionMapState state) {
  return defaultCreateCtRegionMapGame(
    region: state.widget.region,
    cellSizePx: state.widget.cellSizePx,
    showPoliticalOverlay: state.widget.showPoliticalOverlay,
    showProvinceOverlay: state.widget.showProvinceOverlay,
    showProvinceOwnershipTint: state.widget.showProvinceOwnershipTint,
    showProvinceNamesLayer: state.widget.showProvinceNamesLayer,
    visibilityMode: state.widget.visibilityMode,
    baseLayerDisplayMode:
        state.widget.baseLayerDisplayMode ??
        BaseLayerDisplayMode.terrainAndResourcesImprovementsRoads,
    onProvinceSelected: state.widget.onProvinceSelected,
    onMapTileTappedForDetail: state.widget.onMapTileTappedForDetail,
    onRegionViewChanged: state.widget.onRegionViewChanged,
    onProvinceHovered: state.widget.onProvinceHovered,
    onTileHovered: state.widget.onTileHovered,
    onCivilianTileTapped: (tileKey) => _handleCtRegionMapCivilianTileTapped(
      state,
      tileKey,
    ),
    onFleetMarkerTapped: (locationScopeKey, initialFleetId, markerTileKey) =>
        _handleCtRegionMapFleetMarkerTapped(
          state,
          locationScopeKey,
          initialFleetId,
          markerTileKey,
        ),
    onCivilianTileSelectionCleared: state.widget.onCivilianTileSelectionCleared,
    selectedTileKey: state.widget.selectedTileKey,
    selectedCivilianTileKey: state.widget.selectedCivilianTileKey,
    secondaryHighlightTileKey: state.widget.secondaryHighlightTileKey,
    validTileKeys: state.widget.validTileKeys,
    onTileSelected: state.widget.onTileSelected,
    onWorkTargetSelectionCancelled:
        state.widget.onWorkTargetSelectionCancelled,
    onTownIconTapped: state.widget.bus != null
        ? (provinceId) {
            state.widget.bus!.emit(OpenProvinceDetailPanelEvent(provinceId));
          }
        : null,
    playerViewForResources: state.widget.playerViewForResources,
    onViewportSnapshotChanged: state.widget.onViewportSnapshotChanged,
    initialZoomMultiplier: state.widget.zoomMultiplier ?? 1.0,
  );
}

void _handleCtRegionMapCivilianTileTapped(
  _CtRegionMapState state,
  String tileKey,
) {
  state.widget.onCivilianTileStateChanged?.call(tileKey);
  final bus = state.widget.bus;
  if (bus == null) {
    return;
  }
  String? initialSelectedUnitId;
  for (final marker in state.widget.region.civilianTileMarkers) {
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

void _handleCtRegionMapFleetMarkerTapped(
  _CtRegionMapState state,
  String locationScopeKey,
  String? initialFleetId,
  String markerTileKey,
) {
  state.widget.bus?.emit(
    OpenNavalUnitsPanelEvent(
      locationScopeKey: locationScopeKey,
      initialSelectedFleetId: initialFleetId,
      tileScopeTileKey: markerTileKey,
    ),
  );
}
