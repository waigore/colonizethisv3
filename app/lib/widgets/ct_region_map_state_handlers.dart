import 'package:colonizethis_models/colonizethis_models.dart';

import '../core/services/region_map/region_map_widget_bindings.dart';
import 'ct_region_map_state.dart';

void attachCtRegionMapMinimapCameraBusSubscriptions(CtRegionMapState state) {
  state.subscriptions.cancelAll();
  final b = state.widget.bus;
  if (b == null) return;
  state.subscriptions.track(
    b.on<RequestRegionMapCameraCenterWorldEvent>().listen((e) {
      if (!state.mounted || e.regionId != state.widget.region.regionId) return;
      state.game.setCameraCenterWorld(e.worldCenterX, e.worldCenterY);
    }),
  );
  state.subscriptions.track(
    b.on<RequestRegionMapCameraPanWorldDeltaEvent>().listen((e) {
      if (!state.mounted || e.regionId != state.widget.region.regionId) return;
      state.game.panCameraWorld(e.worldDx, e.worldDy);
    }),
  );
  state.subscriptions.track(
    b.on<RequestRegionMapSetZoomMultiplierEvent>().listen((e) {
      if (!state.mounted || e.regionId != state.widget.region.regionId) return;
      state.game.setZoomMultiplierAbsolute(e.zoomMultiplier);
    }),
  );
}

CtRegionMapGame buildCtRegionMapGame(CtRegionMapState state) {
  return defaultCreateCtRegionMapGame(
    region: state.widget.region,
    cellSizePx: state.widget.cellSizePx,
    showPoliticalOverlay: state.widget.showPoliticalOverlay,
    showProvinceOverlay: state.widget.showProvinceOverlay,
    showProvinceOwnershipTint: state.widget.showProvinceOwnershipTint,
    showProvinceNamesLayer: state.widget.showProvinceNamesLayer,
    showCapitalLinkDisconnectedHighlight:
        state.widget.showCapitalLinkDisconnectedHighlight,
    visibilityMode: state.widget.visibilityMode,
    baseLayerDisplayMode:
        state.widget.baseLayerDisplayMode ??
        BaseLayerDisplayMode.terrainAndResourcesImprovementsRoads,
    onProvinceSelected: state.widget.onProvinceSelected,
    onMapTileTappedForDetail: state.widget.onMapTileTappedForDetail,
    onRegionViewChanged: state.widget.onRegionViewChanged,
    onProvinceHovered: state.widget.onProvinceHovered,
    onTileHovered: state.widget.onTileHovered,
    onCivilianTileTapped: (tileKey) => handleCtRegionMapCivilianTileTapped(
      state,
      tileKey,
    ),
    onFleetMarkerTapped: (locationScopeKey, fleetIds, markerTileKey) =>
        handleCtRegionMapFleetMarkerTapped(
          state,
          locationScopeKey,
          fleetIds,
          markerTileKey,
        ),
    onCivilianTileSelectionCleared: state.widget.onCivilianTileSelectionCleared,
    selectedTileKey: state.widget.selectedTileKey,
    selectedCivilianTileKey: state.widget.selectedCivilianTileKey,
    secondaryHighlightTileKey: state.widget.secondaryHighlightTileKey,
    secondaryHighlightTileKeys: state.widget.secondaryHighlightTileKeys,
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
    showPlayerTerritoryOutline: state.widget.showPlayerTerritoryOutline,
    playerTerritoryTileKeys: state.widget.playerTerritoryTileKeys,
  );
}

void handleCtRegionMapCivilianTileTapped(
  CtRegionMapState state,
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

void handleCtRegionMapFleetMarkerTapped(
  CtRegionMapState state,
  String locationScopeKey,
  List<String> fleetIds,
  String markerTileKey,
) {
  if (fleetIds.isEmpty) return;
  state.widget.bus?.emit(
    OpenNavalMissionMenuEvent(
      locationScopeKey: locationScopeKey,
      fleetIds: fleetIds,
      initialSelectedFleetId: fleetIds.first,
      tileScopeTileKey: markerTileKey,
    ),
  );
}
