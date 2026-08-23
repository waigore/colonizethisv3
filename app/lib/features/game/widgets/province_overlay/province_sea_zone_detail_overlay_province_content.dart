/// Province tab content assembly for [ProvinceSeaZoneDetailOverlay].
library;

import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:flutter/material.dart';

import 'package:colonizethis_app/features/game/flame/overlays/province_detail_overlay_host_support_tile_connectivity.dart'
    show ProvinceTileConnectivityDisplay;
import 'package:colonizethis_app/features/game/flame/map_state/province_action_state_calculator.dart';
import 'package:colonizethis_app/features/game/flame/map_state/province_detach_and_sail_overlay_controls.dart'
    show ProvinceDetachAndSailOverlayControls;
import 'package:colonizethis_app/features/game/flame/map_state/province_naval_mission_action_state.dart'
    show ProvinceNavalMissionOverlayControls;
import 'package:colonizethis_app/features/game/flame/overlays/province_blockade_status_support.dart'
    show ProvinceBlockadeStatus;
import 'package:colonizethis_economy/colonizethis_economy.dart'
    show ProvinceImprovableCommodityCount;
import 'package:colonizethis_world/colonizethis_world.dart' show PlayerView;

import 'province_sea_zone_detail_overlay_province_content_revealed.dart';
import 'province_sea_zone_detail_overlay_province_content_unrevealed.dart';
import 'province_sea_zone_detail_overlay_support.dart';

OverlayContent provinceContent({
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
  bool showMoveArmyControl = false,
  bool moveArmyEnabled = false,
  String moveArmyTooltip = '',
  VoidCallback? onMoveArmyTap,
  bool showInvadeArmyControl = false,
  bool invadeArmyEnabled = false,
  String invadeArmyTooltip = '',
  VoidCallback? onInvadeArmyTap,
  ProvinceNavalMissionOverlayControls navalMission =
      ProvinceNavalMissionOverlayControls.hidden,
  ProvinceDetachAndSailOverlayControls detachAndSail =
      ProvinceDetachAndSailOverlayControls.hidden,
  ProvinceOverlayStationSpyProps stationSpy = kProvinceOverlayStationSpyHidden,
  ProvinceOverlayCounterEspionageProps counterEspionage =
      kProvinceOverlayCounterEspionageHidden,
  ProvinceBlockadeStatus blockadeStatus = ProvinceBlockadeStatus.none,
  required bool showEstablishConsulateControl,
  required bool establishConsulateEnabled,
  required bool establishConsulatePending,
  required String? establishConsulateRejectionReason,
  VoidCallback? onEstablishConsulateTap,
  bool showOwnerStanding = false,
  bool ownerStandingAtWar = false,
  bool showOwnerAllianceBadge = false,
  bool showOfferPeaceControl = false,
  bool offerPeaceEnabled = false,
  bool offerPeacePending = false,
  String? offerPeaceRejectionReason,
  VoidCallback? onOfferPeaceTap,
  required bool isNarrow,
  bool omniscientDetail = false,
  Map<String, int> townProductionBonusByCommodity = const {},
  ProvinceExtractionSnapshot? extractionSnapshot,
  Map<String, ProvinceImprovableCommodityCount> availableByCommodity = const {},
  void Function(Iterable<String>?)? onHighlightTiles,
  ProvinceTileConnectivityDisplay? tileConnectivity,
}) {
  if (provinceContentIsFullyUnrevealed(
    region: region,
    provinceId: provinceId,
    omniscientDetail: omniscientDetail,
  )) {
    return provinceContentUnrevealed(l10n: l10n);
  }
  return provinceContentRevealed(
    context: context,
    l10n: l10n,
    game: game,
    region: region,
    provinceId: provinceId,
    humanPlayerId: humanPlayerId,
    playerView: playerView,
    draftOrders: draftOrders,
    selectedTileKey: selectedTileKey,
    onHighlightTile: onHighlightTile,
    civilianInlineActions: civilianInlineActions,
    inlineActionCallbacks: inlineActionCallbacks,
    showUpgradeTownControl: showUpgradeTownControl,
    upgradeTownEnabled: upgradeTownEnabled,
    upgradeTownHasBuilderUnits: upgradeTownHasBuilderUnits,
    upgradeTownTargetTileKey: upgradeTownTargetTileKey,
    onUpgradeTownTap: onUpgradeTownTap,
    showMoveArmyControl: showMoveArmyControl,
    moveArmyEnabled: moveArmyEnabled,
    moveArmyTooltip: moveArmyTooltip,
    onMoveArmyTap: onMoveArmyTap,
    showInvadeArmyControl: showInvadeArmyControl,
    invadeArmyEnabled: invadeArmyEnabled,
    invadeArmyTooltip: invadeArmyTooltip,
    onInvadeArmyTap: onInvadeArmyTap,
    navalMission: navalMission,
    detachAndSail: detachAndSail,
    stationSpy: stationSpy,
    counterEspionage: counterEspionage,
    blockadeStatus: blockadeStatus,
    showEstablishConsulateControl: showEstablishConsulateControl,
    establishConsulateEnabled: establishConsulateEnabled,
    establishConsulatePending: establishConsulatePending,
    establishConsulateRejectionReason: establishConsulateRejectionReason,
    onEstablishConsulateTap: onEstablishConsulateTap,
    showOwnerStanding: showOwnerStanding,
    ownerStandingAtWar: ownerStandingAtWar,
    showOwnerAllianceBadge: showOwnerAllianceBadge,
    showOfferPeaceControl: showOfferPeaceControl,
    offerPeaceEnabled: offerPeaceEnabled,
    offerPeacePending: offerPeacePending,
    offerPeaceRejectionReason: offerPeaceRejectionReason,
    onOfferPeaceTap: onOfferPeaceTap,
    isNarrow: isNarrow,
    omniscientDetail: omniscientDetail,
    townProductionBonusByCommodity: townProductionBonusByCommodity,
    extractionSnapshot: extractionSnapshot,
    availableByCommodity: availableByCommodity,
    onHighlightTiles: onHighlightTiles,
    tileConnectivity: tileConnectivity,
  );
}
