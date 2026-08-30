import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;

import '../../../../core/services/game_service/game_service.dart'
    show GameMapData;
import '../../../../providers/home_fleet_cargo_provider.dart';
import 'package:colonizethis_world/colonizethis_world.dart';
import 'package:flutter/material.dart';

import '../caches/per_player_army_move_picker_cache.dart';
import '../caches/per_player_work_target_selection_cache.dart';
import '../map_state/province_action_state_calculator.dart';
import '../map_state/game_map_area_state_logic.dart';
import '../../widgets/province_overlay/province_sea_zone_detail_overlay.dart';
import '../../widgets/province_overlay/province_sea_zone_detail_overlay_support.dart'
    show isProvinceSeaZoneOverlaySeaZone;
import 'province_detail_overlay_host_support_bonus.dart';
import 'province_detail_overlay_host_support_display.dart';
import 'province_detail_overlay_host_support_factory_missions.dart';
import 'province_detail_overlay_host_support_shortcuts.dart';
import 'province_detail_overlay_host_support_factory_overlay.dart';
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
  HomeFleetCargoSummary homeFleetCargo = const HomeFleetCargoSummary(
    used: 0,
    capacity: 0,
  ),
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
  final upgradeTownState =
      GameMapAreaStateLogicProvinceActions.provinceUpgradeTownActionState(
        game: game,
        humanPlayerId: humanPlayerId,
        provinceId: displayId,
        playerView: playerView,
        workTargetSelectionCache: workTargetSelectionCache,
        topology: mapData?.combinedTopology,
        currentOrders: draftOrders,
        tileMapByRegion: mapData?.tileMapByRegion,
      );
  final establishConsulateState =
      GameMapAreaStateLogicProvinceActions.provinceEstablishConsulateActionState(
        game: game,
        humanPlayerId: humanPlayerId,
        provinceId: displayId,
        topology: mapData?.combinedTopology,
        currentOrders: draftOrders,
      );
  final establishConsulateTargetName = resolveProvinceDetailFactionDisplayName(
    game,
    establishConsulateState.ownerId,
  );
  final isSeaZone = isProvinceSeaZoneOverlaySeaZone(region, displayId);
  final offerPeaceState =
      GameMapAreaStateLogicProvinceActions.provinceOfferPeaceActionState(
        game: game,
        humanPlayerId: humanPlayerId,
        provinceId: displayId,
        topology: mapData?.combinedTopology,
        currentOrders: draftOrders,
        isSeaZone: isSeaZone,
      );
  final offerPeaceTargetName = resolveProvinceDetailFactionDisplayName(
    game,
    offerPeaceState.ownerId,
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
    exploreEnabled: actionStates.explore.enabled,
    prospectEnabled: actionStates.prospect.enabled,
    buildImprovementEnabled: actionStates.buildImprovement.enabled,
    buildRoadEnabled: actionStates.buildRoad.enabled,
    buildFortEnabled: actionStates.buildFort.enabled,
    buildPortEnabled: actionStates.buildPort.enabled,
    buildRailEnabled: actionStates.buildRail.enabled,
    purchaseLandEnabled: actionStates.purchaseLand.enabled,
    provinceId: displayId,
    upgradeTownEnabled: upgradeTownState.enabled,
    upgradeTownTargetTileKey: upgradeTownState.townTileKey,
    establishConsulateEnabled: establishConsulateState.enabled,
    establishConsulatePending: establishConsulateState.pending,
    establishConsulateOrder: establishConsulateState.order,
    establishConsulateTargetName: establishConsulateTargetName,
    isSeaZone: isSeaZone,
    offerPeaceEnabled: offerPeaceState.offerPeaceEnabled,
    offerPeacePending: offerPeaceState.offerPeacePending,
    offerPeaceOrder: offerPeaceState.order,
    offerPeaceTargetName: offerPeaceTargetName,
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
  final tileConnectivity = resolveProvinceDetailTileConnectivity(
    game: game,
    region: region,
    humanPlayerId: humanPlayerId,
    displayId: displayId,
    selectedTileKey: selectedTileKey,
    mapData: mapData,
    isSeaZone: isSeaZone,
  );
  final missions = buildProvinceDetailMissionOverlayControls(
    context: context,
    game: game,
    region: region,
    humanPlayerId: humanPlayerId,
    playerView: playerView,
    displayId: displayId,
    selectedTileKey: selectedTileKey,
    draftOrders: draftOrders,
    mapData: mapData,
    canMutateViaUi: canMutateViaUi,
    omniscientDetail: omniscientDetail,
    isSeaZone: isSeaZone,
    armyMovePickerCache: armyMovePickerCache,
    bus: bus,
    cargo: homeFleetCargo,
  );
  final armyMove = missions.armyMove;
  final armyCombine = missions.armyCombine;
  final navalMission = missions.navalMission;
  final detachAndSail = missions.detachAndSail;
  final transferToHomeFleet = missions.transferToHomeFleet;
  final navalCombine = missions.navalCombine;
  final stationSpy = missions.stationSpy;
  final counterEspionage = missions.counterEspionage;

  final gatedInlineActions = gateProvinceInlineActionsForUi(
    states: actionStates,
    canMutateViaUi: canMutateViaUi,
  );

  return assembleProvinceSeaZoneDetailOverlay(
    game: game,
    region: region,
    displayId: displayId,
    selectedTileKey: selectedTileKey,
    humanPlayerId: humanPlayerId,
    playerView: playerView,
    draftOrders: draftOrders,
    townProductionBonus: townProductionBonus,
    extractionSnapshot: extractionSnapshot,
    availableByCommodity: availableByCommodity,
    tileConnectivity: tileConnectivity,
    onHighlightTile: onHighlightTile,
    onHighlightTiles: onHighlightTiles,
    onClose: onClose,
    gatedInlineActions: gatedInlineActions,
    shortcuts: shortcuts,
    omniscientDetail: omniscientDetail,
    canMutateViaUi: canMutateViaUi,
    upgradeTownState: upgradeTownState,
    armyMove: armyMove,
    armyCombine: armyCombine,
    navalMission: navalMission,
    detachAndSail: detachAndSail,
    transferToHomeFleet: transferToHomeFleet,
    navalCombine: navalCombine,
    stationSpy: stationSpy,
    counterEspionage: counterEspionage,
    establishConsulateState: establishConsulateState,
    offerPeaceState: offerPeaceState,
  );
}
