part of 'province_detail_overlay_host_support.dart';

/// Builds the shared [ProvinceSeaZoneDetailOverlay] wiring used by wide and
/// narrow panel hosts. Hosts own layout / E2E only. Refs #4018.
ProvinceSeaZoneDetailOverlay buildProvinceSeaZoneDetailOverlayForPanel({
  required ct_models.Game game,
  required RegionMapViewData region,
  required String humanPlayerId,
  required PlayerView playerView,
  required PerPlayerWorkTargetSelectionCache workTargetSelectionCache,
  required String? selectedTileKey,
  required ct_models.Orders draftOrders,
  required GameMapData? mapData,
  required bool canMutateViaUi,
  required bool omniscientDetail,
  required void Function(String?) onHighlightTile,
  required void Function(Iterable<String>?) onHighlightTiles,
  required VoidCallback onClose,
  required ct_models.AppEventBus bus,
}) {
  final displayId = resolveProvinceDetailDisplayId(
    region: region,
    tileKey: selectedTileKey,
  );
  final actionStates = ProvinceActionStateCalculator.compute(
    game: game,
    humanPlayerId: humanPlayerId,
    selectedTileKey: selectedTileKey,
    region: region,
    playerView: playerView,
    currentOrders: draftOrders,
    workTargetSelectionCache: workTargetSelectionCache,
    mapData: mapData,
  );
  final exploreState = actionStates.explore;
  final prospectState = actionStates.prospect;
  final buildImprovementState = actionStates.buildImprovement;
  final shortcuts = buildProvinceDetailShortcutCallbacks(
    game: game,
    humanPlayerId: humanPlayerId,
    region: region,
    playerView: playerView,
    workTargetSelectionCache: workTargetSelectionCache,
    draftOrders: draftOrders,
    mapData: mapData,
    selectedTileKey: selectedTileKey,
    exploreEnabled: exploreState.enabled,
    prospectEnabled: prospectState.enabled,
    buildImprovementEnabled: buildImprovementState.enabled,
    bus: bus,
  );
  final townProductionBonus = provinceTownProductionBonusPreview(
    game: game,
    provinceId: displayId,
    mapData: mapData,
  );
  final extractionSnapshot = provinceExtractionSnapshotPreview(
    game: game,
    provinceId: displayId,
    mapData: mapData,
  );
  final availableByCommodity = provinceAvailableResourceCountsPreview(
    game: game,
    provinceId: displayId,
    mapData: mapData,
  );
  return ProvinceSeaZoneDetailOverlay(
    game: game,
    region: region,
    displayId: displayId,
    selectedTileKey: selectedTileKey,
    humanPlayerId: humanPlayerId,
    playerView: playerView,
    draftOrders: draftOrders,
    townProductionBonusByCommodity: townProductionBonus,
    extractionSnapshot: extractionSnapshot,
    availableByCommodity: availableByCommodity,
    onHighlightTile: onHighlightTile,
    onHighlightTiles: onHighlightTiles,
    onClose: onClose,
    showProspectActionIcon: canMutateViaUi && prospectState.showIcon,
    prospectActionEnabled: canMutateViaUi && prospectState.enabled,
    showExploreActionIcon: canMutateViaUi && exploreState.showIcon,
    exploreActionEnabled: canMutateViaUi && exploreState.enabled,
    showBuildImprovementActionIcon:
        canMutateViaUi && buildImprovementState.showIcon,
    buildImprovementActionEnabled:
        canMutateViaUi && buildImprovementState.enabled,
    omniscientDetail: omniscientDetail,
    onExploreWithExplorerTap: shortcuts.onExploreWithExplorerTap,
    onProspectWithExplorerTap: shortcuts.onProspectWithExplorerTap,
    onBuildImprovementTap: shortcuts.onBuildImprovementTap,
  );
}
