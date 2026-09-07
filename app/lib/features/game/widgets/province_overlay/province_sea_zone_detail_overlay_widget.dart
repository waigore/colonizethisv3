import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import '../../../../config/constants.dart';
import '../../../../config/ui_screen_ids.dart';
import '../../flame/overlays/province_detail_overlay_host_support_tile_connectivity.dart'
    show ProvinceTileConnectivityDisplay;
import '../../flame/overlays/province_blockade_status_support.dart'
    show ProvinceBlockadeStatus;
import '../../flame/map_state/province_action_state_calculator.dart';
import '../../flame/map_state/province_detach_and_sail_overlay_controls.dart'
    show ProvinceDetachAndSailOverlayControls;
import '../../flame/map_state/province_transfer_to_home_fleet_overlay_controls.dart'
    show ProvinceTransferToHomeFleetOverlayControls;
import '../../flame/map_state/province_naval_combine_overlay_controls.dart'
    show ProvinceNavalCombineOverlayControls;
import '../../flame/map_state/province_naval_mission_action_state.dart'
    show ProvinceNavalMissionOverlayControls;
import '../../flame/map_state/province_overlay_sail_move_overlay_controls.dart'
    show ProvinceOverlaySailMoveOverlayControls;
import 'province_sea_zone_detail_overlay_chrome.dart';
import 'province_sea_zone_detail_overlay_support.dart';
import 'province_sea_zone_detail_overlay_widget_content.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart'
    show ProvinceImprovableCommodityCount;
import 'package:colonizethis_world/colonizethis_world.dart' show PlayerView;

class ProvinceSeaZoneDetailOverlay extends StatelessWidget {
  /// SPEC/ui/province-sea-zone-detail-overlay.md — [UiScreenIds.provinceSeaZoneOverlay].
  static const screenId = UiScreenIds.provinceSeaZoneOverlay;

  const ProvinceSeaZoneDetailOverlay({
    super.key,
    required this.game,
    required this.region,
    required this.displayId,
    required this.selectedTileKey,
    required this.humanPlayerId,
    required this.playerView,
    this.draftOrders = const Orders(),
    this.onHighlightTile,
    this.onClose,
    this.civilianInlineActions = kHiddenProvinceActionStates,
    this.inlineActionCallbacks = kEmptyProvinceInlineActionCallbacks,
    this.showUpgradeTownControl = false,
    this.upgradeTownEnabled = false,
    this.upgradeTownHasBuilderUnits = false,
    this.upgradeTownTargetTileKey,
    this.onUpgradeTownTap,
    this.showMoveArmyControl = false,
    this.moveArmyEnabled = false,
    this.moveArmyTooltip = '',
    this.onMoveArmyTap,
    this.showInvadeArmyControl = false,
    this.invadeArmyEnabled = false,
    this.invadeArmyTooltip = '',
    this.onInvadeArmyTap,
    this.showCombineArmiesControl = false,
    this.combineArmiesEnabled = false,
    this.combineArmiesTooltip = '',
    this.onCombineArmiesTap,
    this.navalMission = ProvinceNavalMissionOverlayControls.hidden,
    this.detachAndSail = ProvinceDetachAndSailOverlayControls.hidden,
    this.transferToHomeFleet =
        ProvinceTransferToHomeFleetOverlayControls.hidden,
    this.navalCombine = ProvinceNavalCombineOverlayControls.hidden,
    this.sailMove = ProvinceOverlaySailMoveOverlayControls.hidden,
    this.blockadeStatus = ProvinceBlockadeStatus.none,
    this.stationSpy = kProvinceOverlayStationSpyHidden,
    this.counterEspionage = kProvinceOverlayCounterEspionageHidden,
    this.showEstablishConsulateControl = false,
    this.establishConsulateEnabled = false,
    this.establishConsulatePending = false,
    this.establishConsulateRejectionReason,
    this.onEstablishConsulateTap,
    this.showEstablishEmbassyControl = false,
    this.establishEmbassyEnabled = false,
    this.establishEmbassyPending = false,
    this.establishEmbassyRejectionReason,
    this.onEstablishEmbassyTap,
    this.showOwnerStanding = false,
    this.ownerStandingAtWar = false,
    this.showOwnerAllianceBadge = false,
    this.showOfferPeaceControl = false,
    this.offerPeaceEnabled = false,
    this.offerPeacePending = false,
    this.offerPeaceRejectionReason,
    this.onOfferPeaceTap,
    this.omniscientDetail = false,
    this.townProductionBonusByCommodity = const {},
    this.extractionSnapshot,
    this.availableByCommodity = const {},
    this.tileConnectivity,
    this.onHighlightTiles,
  });

  final Game game;
  final RegionMapViewData region;
  final PlayerView playerView;
  final String displayId;
  final String? selectedTileKey;
  final String humanPlayerId;
  final Orders draftOrders;
  final void Function(String? tileKey)? onHighlightTile;
  final void Function(Iterable<String>? tileKeys)? onHighlightTiles;
  final VoidCallback? onClose;
  final ProvinceActionStates civilianInlineActions;
  final ProvinceInlineActionCallbacks inlineActionCallbacks;
  final bool showUpgradeTownControl;
  final bool upgradeTownEnabled;
  final bool upgradeTownHasBuilderUnits;
  final String? upgradeTownTargetTileKey;
  final VoidCallback? onUpgradeTownTap;
  final bool showMoveArmyControl;
  final bool moveArmyEnabled;
  final String moveArmyTooltip;
  final VoidCallback? onMoveArmyTap;
  final bool showInvadeArmyControl;
  final bool invadeArmyEnabled;
  final String invadeArmyTooltip;
  final VoidCallback? onInvadeArmyTap;
  final bool showCombineArmiesControl;
  final bool combineArmiesEnabled;
  final String combineArmiesTooltip;
  final VoidCallback? onCombineArmiesTap;
  final ProvinceNavalMissionOverlayControls navalMission;
  final ProvinceDetachAndSailOverlayControls detachAndSail;
  final ProvinceTransferToHomeFleetOverlayControls transferToHomeFleet;
  final ProvinceNavalCombineOverlayControls navalCombine;
  final ProvinceOverlaySailMoveOverlayControls sailMove;
  final ProvinceBlockadeStatus blockadeStatus;
  final ProvinceOverlayStationSpyProps stationSpy;
  final ProvinceOverlayCounterEspionageProps counterEspionage;
  final bool showEstablishConsulateControl;
  final bool establishConsulateEnabled;
  final bool establishConsulatePending;
  final String? establishConsulateRejectionReason;
  final VoidCallback? onEstablishConsulateTap;
  final bool showEstablishEmbassyControl;
  final bool establishEmbassyEnabled;
  final bool establishEmbassyPending;
  final String? establishEmbassyRejectionReason;
  final VoidCallback? onEstablishEmbassyTap;
  final bool showOwnerStanding;
  final bool ownerStandingAtWar;
  final bool showOwnerAllianceBadge;
  final bool showOfferPeaceControl;
  final bool offerPeaceEnabled;
  final bool offerPeacePending;
  final String? offerPeaceRejectionReason;
  final VoidCallback? onOfferPeaceTap;
  final bool omniscientDetail;
  final Map<String, int> townProductionBonusByCommodity;
  final ProvinceExtractionSnapshot? extractionSnapshot;
  final Map<String, ProvinceImprovableCommodityCount> availableByCommodity;
  final ProvinceTileConnectivityDisplay? tileConnectivity;

  @override
  Widget build(BuildContext context) {
    final isNarrow = MediaQuery.sizeOf(context).width < kNarrowBreakpoint;
    final content = resolveOverlayContent(context, isNarrow: isNarrow);
    return LayoutBuilder(
      builder: (context, constraints) =>
          buildResponsivePanel(context, constraints, isNarrow, content),
    );
  }
}
