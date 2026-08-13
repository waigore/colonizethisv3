
import 'package:colonizethis_data/colonizethis_data.dart' show MapTopology;
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;

import '../../../../core/services/game_service/game_service.dart'
    show GameMapData;
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_world/colonizethis_world.dart';
import 'package:flutter/material.dart';

import '../caches/per_player_army_move_picker_cache.dart';
import '../caches/per_player_work_target_selection_cache.dart';
import '../map_state/province_action_state_calculator.dart';
import '../map_state/province_army_move_action_state.dart';
import '../map_state/game_map_area_state_logic.dart';
import '../../widgets/province_overlay/province_sea_zone_detail_overlay.dart';
import '../../widgets/province_overlay/province_sea_zone_detail_overlay_support.dart'
    show isProvinceSeaZoneOverlaySeaZone;
import '../../widgets/unit_orders/overlay_army_move_flow.dart';
import 'province_detail_overlay_host_support_bonus.dart';
import 'province_detail_overlay_host_support_display.dart';
import 'province_detail_overlay_host_support_shortcuts.dart';
import 'province_detail_overlay_host_support_tile_connectivity.dart';

/// Builds the shared [ProvinceSeaZoneDetailOverlay] wiring used by wide and
/// narrow panel hosts. Hosts own layout / E2E only. Refs #4018.
ProvinceSeaZoneDetailOverlay buildProvinceSeaZoneDetailOverlayForPanel({
  required BuildContext context,
  required ct_models.Game game,
  required RegionMapViewData region,
  required String humanPlayerId,
  required PlayerView playerView,
  required PerPlayerWorkTargetSelectionCache workTargetSelectionCache,
  PerPlayerArmyMovePickerCache? armyMovePickerCache,
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
  final buildPortState = actionStates.buildPort;
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
    buildPortEnabled: buildPortState.enabled,
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
  final isSeaZone = isProvinceSeaZoneOverlaySeaZone(region, displayId);
  final armyCache = armyMovePickerCache ?? PerPlayerArmyMovePickerCache();
  final provinceTileKeys =
      game.worldState.tileKeysByRegionAndProvince[region.regionId]?[displayId] ??
      const <String>[];
  final showsFullMilitaryIntel =
      omniscientDetail ||
      provincePanelShowsFullTileDerivedIntel(
        game: game,
        view: playerView,
        humanPlayerId: humanPlayerId,
        provinceId: displayId,
        provinceTileKeys: provinceTileKeys,
      );
  final armyMoveState = computeProvinceArmyMoveActionState(
    game: game,
    humanPlayerId: humanPlayerId,
    provinceId: displayId,
    topology: mapData?.combinedTopology ?? const MapTopology(),
    armyMovePickerCache: armyCache,
    showsFullMilitaryIntel: showsFullMilitaryIntel,
    isSeaZoneContext: isSeaZone,
  );
  // L10n for tooltips — hosts always build under MaterialApp with l10n;
  // AppLocalizationsEn is the contract default for factory without BuildContext l10n.
  final l10n = appL10n(context);
  String moveTooltip() {
    switch (armyMoveState.moveDisabledReason) {
      case ProvinceArmyMoveDisabledReason.homeArmyCannotLeave:
        return l10n.provinceOverlay_moveArmyDisabledHomeArmyTooltip;
      case ProvinceArmyMoveDisabledReason.noDestinations:
        return l10n.provinceOverlay_moveArmyDisabledNoDestinationsTooltip;
      case ProvinceArmyMoveDisabledReason.cannotReach:
      case ProvinceArmyMoveDisabledReason.none:
        return l10n.provinceOverlay_moveArmyAction;
    }
  }

  String invadeTooltip() {
    switch (armyMoveState.invadeDisabledReason) {
      case ProvinceArmyMoveDisabledReason.cannotReach:
        return l10n.provinceOverlay_invadeArmyDisabledCannotReachTooltip;
      case ProvinceArmyMoveDisabledReason.homeArmyCannotLeave:
      case ProvinceArmyMoveDisabledReason.noDestinations:
      case ProvinceArmyMoveDisabledReason.none:
        return l10n.provinceOverlay_invadeArmyAction(
          game.worldState.allProvincesById[displayId]?.displayName ??
              displayId,
        );
    }
  }

  VoidCallback? moveTap;
  if (canMutateViaUi && armyMoveState.moveEnabled) {
    moveTap = () {
      showOverlayArmyMoveFlow(
        context: context,
        game: game,
        topology: mapData?.combinedTopology ?? const MapTopology(),
        humanPlayerId: humanPlayerId,
        draftOrders: draftOrders,
        bus: bus,
        armyIds: armyMoveState.eligibleMoveArmyIds,
        playerView: playerView,
      );
    };
  }
  VoidCallback? invadeTap;
  if (canMutateViaUi && armyMoveState.invadeEnabled) {
    invadeTap = () {
      showOverlayArmyMoveFlow(
        context: context,
        game: game,
        topology: mapData?.combinedTopology ?? const MapTopology(),
        humanPlayerId: humanPlayerId,
        draftOrders: draftOrders,
        bus: bus,
        armyIds: armyMoveState.eligibleInvadeArmyIds,
        playerView: playerView,
        initialDestinationProvinceId: displayId,
      );
    };
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
    showBuildPortActionIcon: canMutateViaUi && buildPortState.showIcon,
    buildPortActionEnabled: canMutateViaUi && buildPortState.enabled,
    buildPortActionHasEngineerUnits: buildPortState.hasEngineerUnits,
    showPurchaseLandActionIcon: canMutateViaUi && purchaseLandState.showIcon,
    purchaseLandActionEnabled: canMutateViaUi && purchaseLandState.enabled,
    purchaseLandActionHasMerchantUnits: purchaseLandState.hasMerchantUnits,
    omniscientDetail: omniscientDetail,
    onExploreWithExplorerTap: shortcuts.onExploreWithExplorerTap,
    onProspectWithExplorerTap: shortcuts.onProspectWithExplorerTap,
    onBuildImprovementTap: shortcuts.onBuildImprovementTap,
    onBuildRoadTap: shortcuts.onBuildRoadTap,
    onBuildFortTap: shortcuts.onBuildFortTap,
    onBuildPortTap: shortcuts.onBuildPortTap,
    onPurchaseLandTap: shortcuts.onPurchaseLandTap,
    showUpgradeTownControl:
        canMutateViaUi && upgradeTownState.showControl,
    upgradeTownEnabled: canMutateViaUi && upgradeTownState.enabled,
    upgradeTownHasBuilderUnits: upgradeTownState.hasBuilderUnits,
    upgradeTownTargetTileKey: upgradeTownState.townTileKey,
    onUpgradeTownTap: shortcuts.onUpgradeTownTap,
    showMoveArmyControl: canMutateViaUi && armyMoveState.showMove,
    moveArmyEnabled: canMutateViaUi && armyMoveState.moveEnabled,
    moveArmyTooltip: moveTooltip(),
    onMoveArmyTap: moveTap,
    showInvadeArmyControl: canMutateViaUi && armyMoveState.showInvade,
    invadeArmyEnabled: canMutateViaUi && armyMoveState.invadeEnabled,
    invadeArmyTooltip: invadeTooltip(),
    onInvadeArmyTap: invadeTap,
  );
}
