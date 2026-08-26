/// Intel-gated economic / military / civilian / naval sections for province tabs.
library;

import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart'
    show ProvinceImprovableCommodityCount;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart' show PlayerView;
import 'package:flutter/material.dart';

import 'province_sea_zone_detail_overlay_civilian_naval_sections.dart';
import 'province_sea_zone_detail_overlay_economic_section.dart';
import 'province_sea_zone_detail_overlay_military_section.dart';
import 'province_sea_zone_detail_overlay_support.dart';
import 'package:colonizethis_app/features/game/flame/map_state/province_detach_and_sail_overlay_controls.dart'
    show ProvinceDetachAndSailOverlayControls;
import 'package:colonizethis_app/features/game/flame/map_state/province_transfer_to_home_fleet_overlay_controls.dart'
    show ProvinceTransferToHomeFleetOverlayControls;
import 'package:colonizethis_app/features/game/flame/map_state/province_naval_combine_overlay_controls.dart'
    show ProvinceNavalCombineOverlayControls;
import 'package:colonizethis_app/features/game/flame/map_state/province_naval_mission_action_state.dart'
    show ProvinceNavalMissionOverlayControls;
import 'package:colonizethis_app/features/game/flame/overlays/province_blockade_status_support.dart'
    show ProvinceBlockadeStatus;
import 'package:colonizethis_app/features/game/flame/map_state/province_action_state_calculator.dart';
import 'package:colonizethis_app/features/game/widgets/units/civilian/work_order_afford_preview_ui.dart';

({Widget economic, Widget military, Widget civilian, Widget naval})
buildProvinceIntelGatedUnitSections({
  required AppLocalizations l10n,
  required Game game,
  required bool showsFullIntel,
  required String humanPlayerId,
  required String provinceId,
  required Orders draftOrders,
  required PlayerView playerView,
  required List<Unit> military,
  required List<Unit> civilian,
  required List<Fleet> fleetsInPort,
  required int fortLevel,
  required ProvinceInlineActionState buildFortAction,
  required String? selectedTileKey,
  VoidCallback? onBuildFortTap,
  bool showMoveArmyControl = false,
  bool moveArmyEnabled = false,
  String moveArmyTooltip = '',
  VoidCallback? onMoveArmyTap,
  bool showInvadeArmyControl = false,
  bool invadeArmyEnabled = false,
  String invadeArmyTooltip = '',
  VoidCallback? onInvadeArmyTap,
  bool showCombineArmiesControl = false,
  bool combineArmiesEnabled = false,
  String combineArmiesTooltip = '',
  VoidCallback? onCombineArmiesTap,
  ProvinceNavalMissionOverlayControls navalMission =
      ProvinceNavalMissionOverlayControls.hidden,
  ProvinceDetachAndSailOverlayControls detachAndSail =
      ProvinceDetachAndSailOverlayControls.hidden,
  ProvinceTransferToHomeFleetOverlayControls transferToHomeFleet =
      ProvinceTransferToHomeFleetOverlayControls.hidden,
  ProvinceNavalCombineOverlayControls navalCombine =
      ProvinceNavalCombineOverlayControls.hidden,
  ProvinceOverlayStationSpyProps stationSpy = kProvinceOverlayStationSpyHidden,
  ProvinceOverlayCounterEspionageProps counterEspionage =
      kProvinceOverlayCounterEspionageHidden,
  ProvinceBlockadeStatus blockadeStatus = ProvinceBlockadeStatus.none,
  String? provinceDisplayName,
  void Function(String?)? onHighlightTile,
  void Function(Iterable<String>?)? onHighlightTiles,
  ProvinceExtractionSnapshot? extractionSnapshot,
  Map<String, ProvinceImprovableCommodityCount> availableByCommodity = const {},
  Map<String, int> townProductionBonusByCommodity = const {},
  required Map<String, List<({String tileKey, String terrain, String impBase})>>
  byResImproved,
  required Map<String, List<({String tileKey, String terrain})>>
  byResImprovable,
  required List<String> resourceKeysSorted,
}) {
  final economic = showsFullIntel
      ? buildEconomicSection(
          l10n: l10n,
          resourceKeysSorted: resourceKeysSorted,
          byResImproved: byResImproved,
          byResImprovable: byResImprovable,
          onHighlightTile: onHighlightTile,
          onHighlightTiles: onHighlightTiles,
          extractionSnapshot: extractionSnapshot,
          availableByCommodity: availableByCommodity,
          townProductionBonusByCommodity: townProductionBonusByCommodity,
        )
      : buildOverlaySection(
          l10n.provinceOverlay_sectionEconomic,
          overlayObfuscatedBodyText(l10n.provinceOverlay_unknown),
        );
  final militarySection = showsFullIntel
      ? buildMilitarySectionByOwner(
          l10n: l10n,
          game: game,
          military: military,
          humanPlayerId: humanPlayerId,
          provinceId: provinceId,
          draftOrders: draftOrders,
          fortLevel: fortLevel,
          showBuildFortActionIcon: buildFortAction.showIcon,
          buildFortActionEnabled: buildFortAction.enabled,
          buildFortTooltip: selectedTileKey == null
              ? l10n.provinceOverlay_tileBuildFortDisabledTooltip
              : provinceOverlayBuildFortTooltip(
                  l10n: l10n,
                  game: game,
                  humanPlayerId: humanPlayerId,
                  currentOrders: draftOrders,
                  selectedTileKey: selectedTileKey,
                  enabled: buildFortAction.enabled,
                  hasMatchingUnits: buildFortAction.hasMatchingUnits,
                ),
          onBuildFortTap: onBuildFortTap,
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
          provinceDisplayName: provinceDisplayName,
        )
      : buildOverlaySection(
          l10n.provinceOverlay_sectionMilitary,
          overlayObfuscatedBodyText(l10n.provinceOverlay_unknown),
        );
  final civilianSection = showsFullIntel
      ? buildCivilianSectionFiltered(
          l10n: l10n,
          game: game,
          civilian: civilian,
          humanPlayerId: humanPlayerId,
          playerView: playerView,
          draftOrders: draftOrders,
          stationSpy: stationSpy,
          counterEspionage: counterEspionage,
        )
      : buildOverlaySection(
          l10n.provinceOverlay_sectionCivilian,
          overlayObfuscatedBodyText(l10n.provinceOverlay_unknown),
        );
  final naval = buildNavalSection(
    l10n: l10n,
    game: game,
    fleets: showsFullIntel ? fleetsInPort : const [],
    humanPlayerId: humanPlayerId,
    draftOrders: draftOrders,
    pendingNavalPortProvinceId: showsFullIntel ? provinceId : null,
    rosterObfuscated: !showsFullIntel,
    navalMission: navalMission,
    detachAndSail: detachAndSail,
    transferToHomeFleet: transferToHomeFleet,
    navalCombine: navalCombine,
    blockadeStatus: blockadeStatus,
  );
  return (
    economic: economic,
    military: militarySection,
    civilian: civilianSection,
    naval: naval,
  );
}
