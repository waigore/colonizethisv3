
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;
import 'package:flutter/widgets.dart';

import '../../../../core/services/game_service/game_service.dart'
    show GameMapData;
import '../caches/per_player_work_target_selection_cache.dart';
import '../map_state/province_action_state_calculator.dart';
import '../map_state/game_map_area_state_logic.dart';
import '../../widgets/province_overlay/province_sea_zone_detail_overlay.dart';
import '../../widgets/province_overlay/province_sea_zone_detail_overlay_support.dart'
    show isProvinceSeaZoneOverlaySeaZone;
import 'province_detail_overlay_host_support_bonus.dart';
import 'province_detail_overlay_host_support_display.dart';
import 'province_detail_overlay_host_support_shortcuts.dart';
import 'province_detail_overlay_host_support_tile_connectivity.dart';
import 'package:colonizethis_world/colonizethis_world.dart' show PlayerView;

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
  final buildRoadState = actionStates.buildRoad;
  final buildFortState = actionStates.buildFort;
  final purchaseLandState = actionStates.purchaseLand;
  final upgradeTownState = GameMapAreaStateLogic.provinceUpgradeTownActionState(
    game: game,
    humanPlayerId: humanPlayerId,
    provinceId: displayId,
    playerView: playerView,
    workTargetSelectionCache: workTargetSelectionCache,
    topology: mapData?.combinedTopology,
    currentOrders: draftOrders,
    tileMapByRegion: mapData?.tileMapByRegion,
  );
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
    buildRoadEnabled: buildRoadState.enabled,
    buildFortEnabled: buildFortState.enabled,
    purchaseLandEnabled: purchaseLandState.enabled,
    provinceId: displayId,
    upgradeTownEnabled: upgradeTownState.enabled,
    upgradeTownTargetTileKey: upgradeTownState.townTileKey,
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
  ProvinceTileConnectivityDisplay? tileConnectivity;
  if (selectedTileKey != null) {
    final coords = tryParseProvinceOverlayTileCoords(
      regionId: region.regionId,
      regionWidth: region.width,
      regionHeight: region.height,
      selectedTileKey: selectedTileKey,
    );
    if (coords != null) {
      final cell = region.cellAt(coords.x, coords.y);
      final connectivityForHuman = humanConnectivityPreview(
        game: game,
        humanPlayerId: humanPlayerId,
        mapData: mapData,
      );
      tileConnectivity = provinceTileConnectivityDisplayPreview(
        game: game,
        humanPlayerId: humanPlayerId,
        provinceId: displayId,
        selectedTileKey: selectedTileKey,
        mapData: mapData,
        isSeaZoneContext: isProvinceSeaZoneOverlaySeaZone(region, displayId),
        tileIsSea: cell.isSea,
        tileRevealed: cell.visibility != TileVisibility.unrevealed,
        connectivityForHuman: connectivityForHuman,
      );
    }
  }
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
    tileConnectivity: tileConnectivity,
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
    buildImprovementActionHasBuilderUnits:
        buildImprovementState.hasBuilderUnits,
    showBuildRoadActionIcon: canMutateViaUi && buildRoadState.showIcon,
    buildRoadActionEnabled: canMutateViaUi && buildRoadState.enabled,
    buildRoadActionHasEngineerUnits: buildRoadState.hasEngineerUnits,
    showBuildFortActionIcon: canMutateViaUi && buildFortState.showIcon,
    buildFortActionEnabled: canMutateViaUi && buildFortState.enabled,
    buildFortActionHasEngineerUnits: buildFortState.hasEngineerUnits,
    showPurchaseLandActionIcon: canMutateViaUi && purchaseLandState.showIcon,
    purchaseLandActionEnabled: canMutateViaUi && purchaseLandState.enabled,
    purchaseLandActionHasMerchantUnits: purchaseLandState.hasMerchantUnits,
    omniscientDetail: omniscientDetail,
    onExploreWithExplorerTap: shortcuts.onExploreWithExplorerTap,
    onProspectWithExplorerTap: shortcuts.onProspectWithExplorerTap,
    onBuildImprovementTap: shortcuts.onBuildImprovementTap,
    onBuildRoadTap: shortcuts.onBuildRoadTap,
    onBuildFortTap: shortcuts.onBuildFortTap,
    onPurchaseLandTap: shortcuts.onPurchaseLandTap,
    showUpgradeTownControl:
        canMutateViaUi && upgradeTownState.showControl,
    upgradeTownEnabled: canMutateViaUi && upgradeTownState.enabled,
    upgradeTownHasBuilderUnits: upgradeTownState.hasBuilderUnits,
    upgradeTownTargetTileKey: upgradeTownState.townTileKey,
    onUpgradeTownTap: shortcuts.onUpgradeTownTap,
  );
}
