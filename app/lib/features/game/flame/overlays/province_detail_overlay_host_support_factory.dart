import 'package:colonizethis_logic/colonizethis_logic.dart' show PlayerView;
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;
import 'package:flutter/widgets.dart';

import '../../../../core/services/game_service/game_service.dart'
    show GameMapData;
import '../caches/per_player_work_target_selection_cache.dart';
import '../map_state/province_action_state_calculator.dart';
import '../../widgets/province_overlay/province_sea_zone_detail_overlay.dart';
import 'province_detail_overlay_host_support_bonus.dart';
import 'province_detail_overlay_host_support_display.dart';
import 'province_detail_overlay_host_support_shortcuts.dart';
import 'province_detail_overlay_host_support_tile_capital_link.dart';

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
  final isLandTile = selectedTileKey != null &&
      !cellAtTileKeyIsSea(region: region, tileKey: selectedTileKey);
  final tileCapitalLinkPreview = provinceTileCapitalLinkPreview(
    game: game,
    humanPlayerId: humanPlayerId,
    selectedTileKey: selectedTileKey,
    isLandTile: isLandTile,
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
    tileCapitalLinkPreview: tileCapitalLinkPreview,
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
