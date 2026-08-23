import 'package:colonizethis_economy/colonizethis_economy.dart'
    show ProvinceImprovableCommodityCount;
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;
import 'package:colonizethis_world/colonizethis_world.dart';
import 'package:flutter/material.dart';

import '../map_state/game_map_area_province_action_states_establish_consulate.dart';
import '../map_state/game_map_area_province_action_states_offer_peace.dart';
import '../map_state/province_action_state_calculator.dart';
import '../map_state/province_detach_and_sail_overlay_controls.dart';
import '../map_state/province_naval_mission_action_state.dart';
import '../../widgets/province_overlay/province_sea_zone_detail_overlay.dart';
import '../../widgets/province_overlay/province_sea_zone_detail_overlay_support.dart';
import 'province_detail_overlay_host_support_army_move.dart';
import 'province_detail_overlay_host_support_shortcuts.dart';
import 'province_detail_overlay_host_support_tile_connectivity.dart';

ProvinceSeaZoneDetailOverlay assembleProvinceSeaZoneDetailOverlay({
  required ct_models.Game game,
  required RegionMapViewData region,
  required String displayId,
  required String? selectedTileKey,
  required String humanPlayerId,
  required PlayerView playerView,
  required ct_models.Orders draftOrders,
  required Map<String, int> townProductionBonus,
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
  required ProvinceNavalMissionOverlayControls navalMission,
  required ProvinceDetachAndSailOverlayControls detachAndSail,
  required ProvinceOverlayStationSpyProps stationSpy,
  required ProvinceOverlayCounterEspionageProps counterEspionage,
  required ProvinceEstablishConsulateActionState establishConsulateState,
  required ProvinceOwnerStandingOfferPeaceState offerPeaceState,
}) {
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
    navalMission: navalMission,
    detachAndSail: detachAndSail,
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
    showOwnerStanding: offerPeaceState.showStanding,
    ownerStandingAtWar: offerPeaceState.atWar,
    showOwnerAllianceBadge: offerPeaceState.showAllianceBadge,
    showOfferPeaceControl:
        canMutateViaUi && offerPeaceState.showOfferPeaceControl,
    offerPeaceEnabled: canMutateViaUi && offerPeaceState.offerPeaceEnabled,
    offerPeacePending: offerPeaceState.offerPeacePending,
    offerPeaceRejectionReason: offerPeaceState.rejectionReason,
    onOfferPeaceTap: shortcuts.onOfferPeaceTap,
  );
}
