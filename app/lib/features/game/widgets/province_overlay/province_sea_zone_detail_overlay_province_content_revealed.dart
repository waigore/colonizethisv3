import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:colonizethis_app/features/game/flame/overlays/province_detail_overlay_host_support_tile_connectivity.dart'
    show ProvinceTileConnectivityDisplay;
import 'package:colonizethis_app/features/game/flame/map_state/province_action_state_calculator.dart';
import 'package:colonizethis_app/features/game/flame/map_state/province_detach_and_sail_overlay_controls.dart'
    show ProvinceDetachAndSailOverlayControls;
import 'package:colonizethis_app/features/game/flame/map_state/province_transfer_to_home_fleet_overlay_controls.dart'
    show ProvinceTransferToHomeFleetOverlayControls;
import 'package:colonizethis_app/features/game/flame/map_state/province_naval_combine_overlay_controls.dart'
    show ProvinceNavalCombineOverlayControls;
import 'package:colonizethis_app/features/game/flame/map_state/province_overlay_sail_move_overlay_controls.dart'
    show ProvinceOverlaySailMoveOverlayControls;
import 'package:colonizethis_app/features/game/flame/map_state/province_naval_mission_action_state.dart'
    show ProvinceNavalMissionOverlayControls;
import 'package:colonizethis_app/features/game/flame/overlays/province_blockade_status_support.dart'
    show ProvinceBlockadeStatus;
import 'province_sea_zone_detail_overlay_grant_subsidy_props.dart';
import 'province_sea_zone_detail_overlay_province_content_revealed_context.dart';
import 'province_sea_zone_detail_overlay_province_content_revealed_political.dart';
import 'province_sea_zone_detail_overlay_province_content_revealed_tabs.dart';
import 'province_sea_zone_detail_overlay_support.dart';
import 'province_sea_zone_detail_overlay_tile_section.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart'
    show ProvinceImprovableCommodityCount;
import 'package:colonizethis_world/colonizethis_world.dart' show PlayerView;

OverlayContent provinceContentRevealed({
  required BuildContext context,
  required AppLocalizations l10n,
  required Game game,
  required RegionMapViewData region,
  required String provinceId,
  required String humanPlayerId,
  required PlayerView playerView,
  required Orders draftOrders,
  String? selectedTileKey,
  void Function(String?)? onHighlightTile,
  required ProvinceActionStates civilianInlineActions,
  required ProvinceInlineActionCallbacks inlineActionCallbacks,
  required bool showUpgradeTownControl,
  required bool upgradeTownEnabled,
  required bool upgradeTownHasBuilderUnits,
  required String? upgradeTownTargetTileKey,
  VoidCallback? onUpgradeTownTap,
  required bool showMoveArmyControl,
  required bool moveArmyEnabled,
  required String moveArmyTooltip,
  VoidCallback? onMoveArmyTap,
  required bool showInvadeArmyControl,
  required bool invadeArmyEnabled,
  required String invadeArmyTooltip,
  VoidCallback? onInvadeArmyTap,
  bool showCombineArmiesControl = false,
  bool combineArmiesEnabled = false,
  String combineArmiesTooltip = '',
  VoidCallback? onCombineArmiesTap,
  required ProvinceNavalMissionOverlayControls navalMission,
  required ProvinceDetachAndSailOverlayControls detachAndSail,
  required ProvinceTransferToHomeFleetOverlayControls transferToHomeFleet,
  required ProvinceNavalCombineOverlayControls navalCombine,
  required ProvinceOverlaySailMoveOverlayControls sailMove,
  required ProvinceOverlayStationSpyProps stationSpy,
  required ProvinceOverlayCounterEspionageProps counterEspionage,
  required ProvinceBlockadeStatus blockadeStatus,
  required bool showEstablishConsulateControl,
  required bool establishConsulateEnabled,
  required bool establishConsulatePending,
  required String? establishConsulateRejectionReason,
  VoidCallback? onEstablishConsulateTap,
  bool showEstablishEmbassyControl = false,
  bool establishEmbassyEnabled = false,
  bool establishEmbassyPending = false,
  String? establishEmbassyRejectionReason,
  VoidCallback? onEstablishEmbassyTap,
  required bool showOwnerStanding,
  required bool ownerStandingAtWar,
  required bool showOwnerAllianceBadge,
  required bool showOfferPeaceControl,
  required bool offerPeaceEnabled,
  required bool offerPeacePending,
  String? offerPeaceRejectionReason,
  VoidCallback? onOfferPeaceTap,
  ProvinceOverlayGrantSubsidyProps grantSubsidy =
      kProvinceOverlayGrantSubsidyHidden,
  required bool isNarrow,
  required bool omniscientDetail,
  required Map<String, int> townProductionBonusByCommodity,
  Map<String, int> nextTownProductionBonusByCommodity = const {},
  ProvinceExtractionSnapshot? extractionSnapshot,
  required Map<String, ProvinceImprovableCommodityCount> availableByCommodity,
  void Function(Iterable<String>?)? onHighlightTiles,
  ProvinceTileConnectivityDisplay? tileConnectivity,
}) {
  final revealed = resolveRevealedProvinceOverlayContext(
    l10n: l10n,
    game: game,
    region: region,
    provinceId: provinceId,
    humanPlayerId: humanPlayerId,
    playerView: playerView,
    omniscientDetail: omniscientDetail,
  );
  final tileSection = buildTileSection(
    context: context,
    l10n: l10n,
    game: game,
    region: region,
    provinceId: provinceId,
    humanPlayerId: humanPlayerId,
    playerView: playerView,
    civilianCount: revealed.visibleCivilianCount,
    selectedTileKey: selectedTileKey,
    civilianInlineActions: civilianInlineActions,
    inlineActionCallbacks: inlineActionCallbacks,
    currentOrders: draftOrders,
    tileConnectivity: tileConnectivity,
    blockadeStatus: blockadeStatus,
  );
  final political = buildRevealedProvincePoliticalSection(
    l10n: l10n,
    game: game,
    region: region,
    provinceId: provinceId,
    regionId: revealed.regionId,
    humanPlayerId: humanPlayerId,
    draftOrders: draftOrders,
    province: revealed.province,
    selectedTileKey: selectedTileKey,
    showUpgradeTownControl: showUpgradeTownControl,
    upgradeTownEnabled: upgradeTownEnabled,
    upgradeTownHasBuilderUnits: upgradeTownHasBuilderUnits,
    upgradeTownTargetTileKey: upgradeTownTargetTileKey,
    townProductionBonusByCommodity: townProductionBonusByCommodity,
    nextTownProductionBonusByCommodity: nextTownProductionBonusByCommodity,
    onUpgradeTownTap: onUpgradeTownTap,
    onTrainCivilianTap: inlineActionCallbacks.onTrainCivilianTap,
    showEstablishConsulateControl: showEstablishConsulateControl,
    establishConsulateEnabled: establishConsulateEnabled,
    establishConsulatePending: establishConsulatePending,
    establishConsulateRejectionReason: establishConsulateRejectionReason,
    onEstablishConsulateTap: onEstablishConsulateTap,
    showEstablishEmbassyControl: showEstablishEmbassyControl,
    establishEmbassyEnabled: establishEmbassyEnabled,
    establishEmbassyPending: establishEmbassyPending,
    establishEmbassyRejectionReason: establishEmbassyRejectionReason,
    onEstablishEmbassyTap: onEstablishEmbassyTap,
    showOwnerStanding: showOwnerStanding,
    ownerStandingAtWar: ownerStandingAtWar,
    showOwnerAllianceBadge: showOwnerAllianceBadge,
    showOfferPeaceControl: showOfferPeaceControl,
    offerPeaceEnabled: offerPeaceEnabled,
    offerPeacePending: offerPeacePending,
    offerPeaceRejectionReason: offerPeaceRejectionReason,
    onOfferPeaceTap: onOfferPeaceTap,
    grantSubsidy: grantSubsidy,
    isNarrow: isNarrow,
  );
  return assembleRevealedProvinceUnitTabContent(
    l10n: l10n,
    game: game,
    showsFullIntel: revealed.showsFullIntel,
    humanPlayerId: humanPlayerId,
    provinceId: provinceId,
    draftOrders: draftOrders,
    playerView: playerView,
    military: revealed.military,
    civilian: revealed.civilian,
    fleetsInPort: revealed.fleetsInPort,
    fortLevel: revealed.province?.fortLevel ?? 0,
    buildFortAction: civilianInlineActions.buildFort,
    onBuildFortTap: inlineActionCallbacks.onBuildFortTap,
    onTrainCivilianTap: inlineActionCallbacks.onTrainCivilianTap,
    showMoveArmyControl: showMoveArmyControl,
    moveArmyEnabled: moveArmyEnabled,
    moveArmyTooltip: moveArmyTooltip,
    onMoveArmyTap: onMoveArmyTap,
    showInvadeArmyControl: showInvadeArmyControl,
    invadeArmyEnabled: invadeArmyEnabled,
    invadeArmyTooltip: invadeArmyTooltip,
    onInvadeArmyTap: onInvadeArmyTap,
    showCombineArmiesControl: showCombineArmiesControl,
    combineArmiesEnabled: combineArmiesEnabled,
    combineArmiesTooltip: combineArmiesTooltip,
    onCombineArmiesTap: onCombineArmiesTap,
    navalMission: navalMission,
    detachAndSail: detachAndSail,
    transferToHomeFleet: transferToHomeFleet,
    navalCombine: navalCombine,
    sailMove: sailMove,
    blockadeStatus: blockadeStatus,
    stationSpy: stationSpy,
    counterEspionage: counterEspionage,
    provinceDisplayName: revealed.province?.displayName,
    onHighlightTile: onHighlightTile,
    onHighlightTiles: onHighlightTiles,
    extractionSnapshot: extractionSnapshot,
    availableByCommodity: availableByCommodity,
    townProductionBonusByCommodity: townProductionBonusByCommodity,
    byResImproved: revealed.tileIntel.byResImproved,
    byResImprovable: revealed.tileIntel.byResImprovable,
    resourceKeysSorted: revealed.tileIntel.resourceKeysSorted,
    selectedTileKey: selectedTileKey,
    political: () => political,
    tileSection: () => tileSection,
  );
}
