import 'package:flutter/material.dart';

import '../core/services/region_map/region_map_widget_bindings.dart';
import '../core/services/subscription_tracker.dart';
import 'ct_region_map.dart';
import 'ct_region_map_state_handlers.dart';
import 'ct_region_map_viewport.dart';

class CtRegionMapState extends State<CtRegionMap>
    with CtRegionMapViewportMixin {
  late CtRegionMapGame game;
  final SubscriptionTracker subscriptions = SubscriptionTracker();
  double _scaleGestureStartMultiplier = 1.0;

  @override
  CtRegionMapGame get regionMapGame => game;

  @override
  double get scaleGestureStartMultiplier => _scaleGestureStartMultiplier;

  @override
  set scaleGestureStartMultiplier(double value) =>
      _scaleGestureStartMultiplier = value;

  @override
  void initState() {
    super.initState();
    game = buildCtRegionMapGame(this);
    attachCtRegionMapMinimapCameraBusSubscriptions(this);
  }

  @override
  void dispose() {
    subscriptions.cancelAll();
    super.dispose();
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
        widget.mapBaseLayerFlags != oldWidget.mapBaseLayerFlags ||
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
        widget.secondaryHighlightTileKeys !=
            oldWidget.secondaryHighlightTileKeys ||
        widget.onTileSelected != oldWidget.onTileSelected ||
        widget.onWorkTargetSelectionCancelled !=
            oldWidget.onWorkTargetSelectionCancelled ||
        widget.playerViewForResources != oldWidget.playerViewForResources ||
        widget.showPlayerTerritoryOutline !=
            oldWidget.showPlayerTerritoryOutline ||
        widget.playerTerritoryTileKeys != oldWidget.playerTerritoryTileKeys ||
        widget.onViewportSnapshotChanged !=
            oldWidget.onViewportSnapshotChanged ||
        widget.zoomMultiplier != oldWidget.zoomMultiplier) {
      game.updateProps(
        region: widget.region,
        showPoliticalOverlay: widget.showPoliticalOverlay,
        showProvinceOverlay: widget.showProvinceOverlay,
        showProvinceOwnershipTint: widget.showProvinceOwnershipTint,
        showProvinceNamesLayer: widget.showProvinceNamesLayer,
        visibilityMode: widget.visibilityMode,
        mapBaseLayerFlags: resolveMapBaseLayerFlags(
          flags: widget.mapBaseLayerFlags,
          mode: widget.baseLayerDisplayMode,
        ),
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
        secondaryHighlightTileKeys: widget.secondaryHighlightTileKeys,
        clearSecondaryHighlightTileKeys:
            widget.secondaryHighlightTileKeys == null,
        validTileKeys: widget.validTileKeys,
        clearValidTileKeys:
            widget.validTileKeys == null && oldWidget.validTileKeys != null,
        onTileSelected: widget.onTileSelected,
        onWorkTargetSelectionCancelled: widget.onWorkTargetSelectionCancelled,
        onCivilianTileTapped: (tileKey) =>
            handleCtRegionMapCivilianTileTapped(this, tileKey),
        onFleetMarkerTapped: (locationScopeKey, fleetIds, markerTileKey) =>
            handleCtRegionMapFleetMarkerTapped(
              this,
              locationScopeKey,
              fleetIds,
              markerTileKey,
            ),
        onCivilianTileSelectionCleared: widget.onCivilianTileSelectionCleared,
        playerViewForResources: widget.playerViewForResources,
        onViewportSnapshotChanged: widget.onViewportSnapshotChanged,
        zoomMultiplier: widget.zoomMultiplier,
        showPlayerTerritoryOutline: widget.showPlayerTerritoryOutline,
        playerTerritoryTileKeys: widget.playerTerritoryTileKeys,
      );
    }
    if (widget.bus != oldWidget.bus) {
      attachCtRegionMapMinimapCameraBusSubscriptions(this);
    }
    if (widget.centerOnTileKey != null &&
        widget.centerOnTileKey != oldWidget.centerOnTileKey) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        game.centerOnTileKey(widget.centerOnTileKey!);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    assertCtMapPlayerViewRequired(
      visibilityMode: widget.visibilityMode,
      playerViewForResources: widget.playerViewForResources,
    );
    return buildRegionMapViewport();
  }
}
