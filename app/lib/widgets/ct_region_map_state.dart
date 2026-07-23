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
    _game = _buildCtRegionMapGame(this);
    _attachMinimapCameraBusSubscriptions(this);
  }

  @override
  void dispose() {
    _subscriptions.cancelAll();
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
        secondaryHighlightTileKeys: widget.secondaryHighlightTileKeys,
        clearSecondaryHighlightTileKeys:
            widget.secondaryHighlightTileKeys == null,
        validTileKeys: widget.validTileKeys,
        clearValidTileKeys:
            widget.validTileKeys == null && oldWidget.validTileKeys != null,
        onTileSelected: widget.onTileSelected,
        onWorkTargetSelectionCancelled: widget.onWorkTargetSelectionCancelled,
        onCivilianTileTapped: (tileKey) =>
            _handleCtRegionMapCivilianTileTapped(this, tileKey),
        onFleetMarkerTapped: (locationScopeKey, initialFleetId, markerTileKey) =>
            _handleCtRegionMapFleetMarkerTapped(
              this,
              locationScopeKey,
              initialFleetId,
              markerTileKey,
            ),
        onCivilianTileSelectionCleared: widget.onCivilianTileSelectionCleared,
        playerViewForResources: widget.playerViewForResources,
        onViewportSnapshotChanged: widget.onViewportSnapshotChanged,
        zoomMultiplier: widget.zoomMultiplier,
      );
    }
    if (widget.bus != oldWidget.bus) {
      _attachMinimapCameraBusSubscriptions(this);
    }
    if (widget.centerOnTileKey != null &&
        widget.centerOnTileKey != oldWidget.centerOnTileKey) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _game.centerOnTileKey(widget.centerOnTileKey!);
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
