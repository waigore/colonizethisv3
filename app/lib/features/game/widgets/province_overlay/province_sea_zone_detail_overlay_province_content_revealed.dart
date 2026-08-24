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
import 'package:colonizethis_app/features/game/flame/map_state/province_naval_mission_action_state.dart'
    show ProvinceNavalMissionOverlayControls;
import 'package:colonizethis_app/features/game/flame/overlays/province_blockade_status_support.dart'
    show ProvinceBlockadeStatus;
import 'package:colonizethis_app/core/utils/prefixed_id.dart';

import 'package:colonizethis_app/features/game/widgets/units/civilian/work_order_afford_overlay_tooltips.dart';

import 'province_overlay_unit_partition.dart';
import 'province_sea_zone_detail_overlay_designation.dart';
import 'province_sea_zone_detail_overlay_province_content_intel.dart';
import 'province_sea_zone_detail_overlay_province_content_tabs.dart';
import 'province_sea_zone_detail_overlay_province_content_unit_sections.dart';
import 'province_sea_zone_detail_overlay_sections_political.dart';
import 'province_sea_zone_detail_overlay_support.dart';
import 'province_sea_zone_detail_overlay_tile_section.dart';
import 'package:colonizethis_app/features/game/flame/controls/map_tile_sight.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart'
    show ProvinceImprovableCommodityCount;
import 'package:colonizethis_world/colonizethis_world.dart'
    show
        PlayerView,
        fleetsInPortAtProvince,
        kRegionNewWorld,
        provincePanelShowsFullTileDerivedIntel;

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
  required ProvinceOverlayStationSpyProps stationSpy,
  required ProvinceOverlayCounterEspionageProps counterEspionage,
  required ProvinceBlockadeStatus blockadeStatus,
  required bool showEstablishConsulateControl,
  required bool establishConsulateEnabled,
  required bool establishConsulatePending,
  required String? establishConsulateRejectionReason,
  VoidCallback? onEstablishConsulateTap,
  required bool showOwnerStanding,
  required bool ownerStandingAtWar,
  required bool showOwnerAllianceBadge,
  required bool showOfferPeaceControl,
  required bool offerPeaceEnabled,
  required bool offerPeacePending,
  String? offerPeaceRejectionReason,
  VoidCallback? onOfferPeaceTap,
  required bool isNarrow,
  required bool omniscientDetail,
  required Map<String, int> townProductionBonusByCommodity,
  ProvinceExtractionSnapshot? extractionSnapshot,
  required Map<String, ProvinceImprovableCommodityCount> availableByCommodity,
  void Function(Iterable<String>?)? onHighlightTiles,
  ProvinceTileConnectivityDisplay? tileConnectivity,
}) {
  final regionId = prefixedIdRegionSegment(provinceId) ?? region.regionId;
  final province = findProvinceForSeaZoneOverlay(game, provinceId);
  final regionData = provinceId.startsWith(kRegionNewWorld)
      ? game.worldState.newWorld
      : game.worldState.oldWorld;
  final partitioned = partitionProvinceOverlayUnits(
    regionUnits: regionData.units,
    provinceId: provinceId,
    humanPlayerId: humanPlayerId,
    playerView: playerView,
  );
  final military = partitioned.military;
  final civilian = partitioned.civilian;
  final visibleCivilianCount = partitioned.visibleCivilianCount;
  final fleetsInPort = fleetsInPortAtProvince(game.worldState, provinceId);
  final tileKeys =
      game.worldState.tileKeysByRegionAndProvince[region
          .regionId]?[provinceId] ??
      [];
  final showsFullIntel =
      omniscientDetail ||
      provincePanelShowsFullTileDerivedIntel(
        game: game,
        view: playerView,
        humanPlayerId: humanPlayerId,
        provinceId: provinceId,
        provinceTileKeys: tileKeys,
      );
  final tileIntel = aggregateProvinceTileIntel(
    l10n: l10n,
    game: game,
    region: region,
    provinceId: provinceId,
    humanPlayerId: humanPlayerId,
    playerView: playerView,
    tileKeys: tileKeys,
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
    civilianCount: visibleCivilianCount,
    selectedTileKey: selectedTileKey,
    civilianInlineActions: civilianInlineActions,
    inlineActionCallbacks: inlineActionCallbacks,
    currentOrders: draftOrders,
    tileConnectivity: tileConnectivity,
    blockadeStatus: blockadeStatus,
  );
  final political = buildPoliticalSection(
    l10n: l10n,
    name: province?.displayName ?? provinceId,
    ownerName: ownerNameForProvinceOverlay(l10n, game, province?.ownerId),
    sightPhrase: mapTileSightPhraseForSelectedTile(
      l10n: l10n,
      region: region,
      selectedTileKey: selectedTileKey,
    ),
    regionLabel: provinceOverlayRegionLabel(l10n, regionId),
    isCapital: provinceOverlayIsCapital(game, provinceId),
    townDevelopmentLevel:
        province?.townDevelopmentLevel ?? kTownDevelopmentLevelMin,
    showUpgradeTownControl: showUpgradeTownControl,
    upgradeTownEnabled: upgradeTownEnabled,
    upgradeTownTooltip: upgradeTownTargetTileKey == null
        ? ''
        : provinceOverlayPoliticalUpgradeTownTooltip(
            l10n: l10n,
            game: game,
            humanPlayerId: humanPlayerId,
            currentOrders: draftOrders,
            townTileKey: upgradeTownTargetTileKey,
            enabled: upgradeTownEnabled,
            hasBuilderUnits: upgradeTownHasBuilderUnits,
          ),
    onUpgradeTownTap: onUpgradeTownTap,
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
  );
  final buildFort = civilianInlineActions.buildFort;
  final unitSections = buildProvinceIntelGatedUnitSections(
    l10n: l10n,
    game: game,
    showsFullIntel: showsFullIntel,
    humanPlayerId: humanPlayerId,
    provinceId: provinceId,
    draftOrders: draftOrders,
    playerView: playerView,
    military: military,
    civilian: civilian,
    fleetsInPort: fleetsInPort,
    fortLevel: province?.fortLevel ?? 0,
    buildFortAction: buildFort,
    onBuildFortTap: inlineActionCallbacks.onBuildFortTap,
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
    blockadeStatus: blockadeStatus,
    stationSpy: stationSpy,
    counterEspionage: counterEspionage,
    provinceDisplayName: province?.displayName,
    onHighlightTile: onHighlightTile,
    onHighlightTiles: onHighlightTiles,
    extractionSnapshot: extractionSnapshot,
    availableByCommodity: availableByCommodity,
    townProductionBonusByCommodity: townProductionBonusByCommodity,
    byResImproved: tileIntel.byResImproved,
    byResImprovable: tileIntel.byResImprovable,
    resourceKeysSorted: tileIntel.resourceKeysSorted,
    selectedTileKey: selectedTileKey,
  );
  return assembleProvinceOverlayTabContent(
    l10n: l10n,
    political: political,
    tileSection: tileSection,
    economic: unitSections.economic,
    militarySection: unitSections.military,
    civilianSection: unitSections.civilian,
    naval: unitSections.naval,
  );
}
