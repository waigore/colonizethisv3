import 'package:colonizethis_economy/colonizethis_economy.dart'
    show ProvinceImprovableCommodityCount;
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;
import 'package:colonizethis_world/colonizethis_world.dart';
import 'package:flutter/material.dart';

import '../map_state/game_map_area_province_action_states_establish_consulate.dart';
import '../map_state/game_map_area_province_action_states_establish_embassy.dart';
import '../map_state/game_map_area_province_action_states_grant_subsidy.dart';
import '../map_state/game_map_area_province_action_states_offer_peace.dart';
import '../map_state/province_action_state_calculator.dart';
import '../map_state/province_detach_and_sail_overlay_controls.dart';
import '../map_state/province_naval_mission_action_state.dart';
import '../map_state/province_overlay_sail_move_overlay_controls.dart';
import '../map_state/province_transfer_to_home_fleet_overlay_controls.dart';
import '../map_state/province_naval_combine_overlay_controls.dart';
import '../../widgets/province_overlay/province_sea_zone_detail_overlay.dart';
import '../../widgets/province_overlay/province_sea_zone_detail_overlay_grant_subsidy_props.dart';
import '../../widgets/province_overlay/province_sea_zone_detail_overlay_support.dart';
import 'province_detail_overlay_host_support_army_combine.dart';
import 'province_detail_overlay_host_support_army_move.dart';
import 'province_detail_overlay_host_support_shortcuts.dart';
import 'province_detail_overlay_host_support_tile_connectivity.dart';
import 'province_detail_overlay_host_support_train_military.dart';

ProvinceSeaZoneDetailOverlay assembleProvinceSeaZoneDetailOverlay({
  required ct_models.Game game,
  required RegionMapViewData region,
  required String displayId,
  required String? selectedTileKey,
  required String humanPlayerId,
  required PlayerView playerView,
  required ct_models.Orders draftOrders,
  required Map<String, int> townProductionBonus,
  required Map<String, int> nextTownProductionBonus,
  required ct_models.ProvinceExtractionSnapshot? extractionSnapshot,
  required Map<String, ProvinceImprovableCommodityCount> availableByCommodity,
  required ProvinceTileConnectivityDisplay? tileConnectivity,
  required void Function(String?) onHighlightTile,
  required void Function(Iterable<String>?) onHighlightTiles,
  required VoidCallback onClose,
  required ProvinceActionStates gatedInlineActions,
  required ProvinceDetailShortcutCallbacks shortcuts,
  required bool omniscientDetail,
  required bool canMutateViaUi,
  required ({
    bool showControl,
    bool enabled,
    bool hasBuilderUnits,
    String? townTileKey,
  })
  upgradeTownState,
  required ProvinceArmyMoveOverlayControls armyMove,
  required ProvinceArmyCombineOverlayControls armyCombine,
  required ProvinceTrainMilitaryOverlayControls trainMilitary,
  required ProvinceNavalMissionOverlayControls navalMission,
  required ProvinceDetachAndSailOverlayControls detachAndSail,
  required ProvinceTransferToHomeFleetOverlayControls transferToHomeFleet,
  required ProvinceNavalCombineOverlayControls navalCombine,
  required ProvinceOverlaySailMoveOverlayControls sailMove,
  required ProvinceOverlayStationSpyProps stationSpy,
  required ProvinceOverlayCounterEspionageProps counterEspionage,
  required ProvinceEstablishConsulateActionState establishConsulateState,
  required ProvinceEstablishEmbassyActionState establishEmbassyState,
  required ProvinceOwnerStandingOfferPeaceState offerPeaceState,
  required ProvinceGrantSubsidyActionState grantAidState,
  required ProvinceGrantSubsidyActionState setSubsidyState,
}) {
  return ProvinceSeaZoneDetailOverlay(
    key: ValueKey<String>(displayId),
    game: game,
    region: region,
    displayId: displayId,
    selectedTileKey: selectedTileKey,
    humanPlayerId: humanPlayerId,
    playerView: playerView,
    draftOrders: draftOrders,
    townProductionBonusByCommodity: townProductionBonus,
    nextTownProductionBonusByCommodity: nextTownProductionBonus,
    extractionSnapshot: extractionSnapshot,
    availableByCommodity: availableByCommodity,
    tileConnectivity: tileConnectivity,
    onHighlightTile: onHighlightTile,
    onHighlightTiles: onHighlightTiles,
    onClose: onClose,
    civilianInlineActions: gatedInlineActions,
    inlineActionCallbacks: (
      onExploreWithExplorerTap: shortcuts.onExploreWithExplorerTap,
      onProspectWithExplorerTap: shortcuts.onProspectWithExplorerTap,
      onBuildImprovementTap: shortcuts.onBuildImprovementTap,
      onBuildRoadTap: shortcuts.onBuildRoadTap,
      onBuildFortTap: shortcuts.onBuildFortTap,
      onBuildPortTap: shortcuts.onBuildPortTap,
      onBuildRailroadTap: shortcuts.onBuildRailroadTap,
      onPurchaseLandTap: shortcuts.onPurchaseLandTap,
      onTrainCivilianTap: canMutateViaUi ? shortcuts.onTrainCivilianTap : null,
    ),
    omniscientDetail: omniscientDetail,
    showUpgradeTownControl: canMutateViaUi && upgradeTownState.showControl,
    upgradeTownEnabled: canMutateViaUi && upgradeTownState.enabled,
    upgradeTownHasBuilderUnits: upgradeTownState.hasBuilderUnits,
    upgradeTownTargetTileKey: upgradeTownState.townTileKey,
    onUpgradeTownTap: shortcuts.onUpgradeTownTap,
    showMoveArmyControl: armyMove.showMove,
    moveArmyEnabled: armyMove.moveEnabled,
    moveArmyTooltip: armyMove.moveTooltip,
    onMoveArmyTap: armyMove.onMoveTap,
    showInvadeArmyControl: armyMove.showInvade,
    invadeArmyEnabled: armyMove.invadeEnabled,
    invadeArmyTooltip: armyMove.invadeTooltip,
    onInvadeArmyTap: armyMove.onInvadeTap,
    showCombineArmiesControl: armyCombine.show,
    combineArmiesEnabled: armyCombine.enabled,
    combineArmiesTooltip: armyCombine.tooltip,
    onCombineArmiesTap: armyCombine.onTap,
    showTrainMilitaryControl: trainMilitary.show,
    onTrainMilitaryTap: trainMilitary.onTap,
    navalMission: navalMission,
    detachAndSail: detachAndSail,
    transferToHomeFleet: transferToHomeFleet,
    navalCombine: navalCombine,
    sailMove: sailMove,
    blockadeStatus: navalMission.blockadeStatus,
    stationSpy: stationSpy,
    counterEspionage: counterEspionage,
    showEstablishConsulateControl:
        canMutateViaUi && establishConsulateState.showControl,
    establishConsulateEnabled:
        canMutateViaUi && establishConsulateState.enabled,
    establishConsulatePending: establishConsulateState.pending,
    establishConsulateRejectionReason: establishConsulateState.rejectionReason,
    onEstablishConsulateTap: shortcuts.onEstablishConsulateTap,
    showEstablishEmbassyControl:
        canMutateViaUi && establishEmbassyState.showControl,
    establishEmbassyEnabled: canMutateViaUi && establishEmbassyState.enabled,
    establishEmbassyPending: establishEmbassyState.pending,
    establishEmbassyRejectionReason: establishEmbassyState.rejectionReason,
    onEstablishEmbassyTap: shortcuts.onEstablishEmbassyTap,
    showOwnerStanding: offerPeaceState.showStanding,
    ownerStandingAtWar: offerPeaceState.atWar,
    showOwnerAllianceBadge: offerPeaceState.showAllianceBadge,
    showOfferPeaceControl:
        canMutateViaUi && offerPeaceState.showOfferPeaceControl,
    offerPeaceEnabled: canMutateViaUi && offerPeaceState.offerPeaceEnabled,
    offerPeacePending: offerPeaceState.offerPeacePending,
    offerPeaceRejectionReason: offerPeaceState.rejectionReason,
    onOfferPeaceTap: shortcuts.onOfferPeaceTap,
    grantSubsidy: bindProvinceOverlayGrantSubsidyProps(
      canMutateViaUi: canMutateViaUi,
      grantAidState: grantAidState,
      setSubsidyState: setSubsidyState,
      onGrantAidTap: shortcuts.onGrantAidTap,
      onSetSubsidyTap: shortcuts.onSetSubsidyTap,
    ),
  );
}

/// Observe / `canMutateViaUi == false` hides both Grant Aid and Set Subsidy
/// even when the Embassy-held probe would otherwise show them (Refs #4761).
ProvinceOverlayGrantSubsidyProps bindProvinceOverlayGrantSubsidyProps({
  required bool canMutateViaUi,
  required ProvinceGrantSubsidyActionState grantAidState,
  required ProvinceGrantSubsidyActionState setSubsidyState,
  VoidCallback? onGrantAidTap,
  VoidCallback? onSetSubsidyTap,
}) => (
  showGrantAid: canMutateViaUi && grantAidState.showControl,
  grantAidEnabled: canMutateViaUi && grantAidState.enabled,
  grantAidPending: grantAidState.pending,
  grantAidRejectionReason: grantAidState.rejectionReason,
  onGrantAidTap: onGrantAidTap,
  showSetSubsidy: canMutateViaUi && setSubsidyState.showControl,
  setSubsidyEnabled: canMutateViaUi && setSubsidyState.enabled,
  setSubsidyPending: setSubsidyState.pending,
  setSubsidyRejectionReason: setSubsidyState.rejectionReason,
  onSetSubsidyTap: onSetSubsidyTap,
);
