part of 'ct_region_map.dart';

class _CtRegionMapState extends State<CtRegionMap> with _CtRegionMapViewportMixin {
  late CtRegionMapGame _game;
  final SubscriptionTracker _subscriptions = SubscriptionTracker();
  double _scaleGestureStartMultiplier = 1.0;

  @override
  CtRegionMapGame get regionMapGame => _game;

  @override
  double get scaleGestureStartMultiplier => _scaleGestureStartMultiplier;

  @override
  set scaleGestureStartMultiplier(double value) =>
      _scaleGestureStartMultiplier = value;

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
    return buildRegionMapViewport();
  }
}
