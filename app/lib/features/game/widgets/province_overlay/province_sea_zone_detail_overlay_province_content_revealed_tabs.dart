import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart'
    show ProvinceImprovableCommodityCount;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart' show PlayerView;
import 'package:flutter/material.dart';

import 'package:colonizethis_app/features/game/flame/map_state/province_action_state_calculator.dart';
import 'package:colonizethis_app/features/game/flame/map_state/province_detach_and_sail_overlay_controls.dart'
    show ProvinceDetachAndSailOverlayControls;
import 'package:colonizethis_app/features/game/flame/map_state/province_naval_mission_action_state.dart'
    show ProvinceNavalMissionOverlayControls;
import 'package:colonizethis_app/features/game/flame/map_state/province_transfer_to_home_fleet_overlay_controls.dart'
    show ProvinceTransferToHomeFleetOverlayControls;
import 'package:colonizethis_app/features/game/flame/map_state/province_naval_combine_overlay_controls.dart'
    show ProvinceNavalCombineOverlayControls;
import 'package:colonizethis_app/features/game/flame/overlays/province_blockade_status_support.dart'
    show ProvinceBlockadeStatus;
import 'package:colonizethis_app/features/game/widgets/units/civilian/work_order_afford_preview_ui.dart';

import 'province_sea_zone_detail_overlay_province_content_tabs.dart';
import 'province_sea_zone_detail_overlay_province_content_unit_sections.dart';
import 'province_sea_zone_detail_overlay_support.dart';

OverlayContent assembleRevealedProvinceUnitTabContent({
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
  VoidCallback? onBuildFortTap,
  required bool showMoveArmyControl,
  required bool moveArmyEnabled,
  required String moveArmyTooltip,
  VoidCallback? onMoveArmyTap,
  required bool showInvadeArmyControl,
  required bool invadeArmyEnabled,
  required String invadeArmyTooltip,
  VoidCallback? onInvadeArmyTap,
  required bool showCombineArmiesControl,
  required bool combineArmiesEnabled,
  required String combineArmiesTooltip,
  VoidCallback? onCombineArmiesTap,
  required ProvinceNavalMissionOverlayControls navalMission,
  required ProvinceDetachAndSailOverlayControls detachAndSail,
  required ProvinceTransferToHomeFleetOverlayControls transferToHomeFleet,
  required ProvinceNavalCombineOverlayControls navalCombine,
  required ProvinceBlockadeStatus blockadeStatus,
  required ProvinceOverlayStationSpyProps stationSpy,
  required ProvinceOverlayCounterEspionageProps counterEspionage,
  String? provinceDisplayName,
  void Function(String?)? onHighlightTile,
  void Function(Iterable<String>?)? onHighlightTiles,
  ProvinceExtractionSnapshot? extractionSnapshot,
  required Map<String, ProvinceImprovableCommodityCount> availableByCommodity,
  required Map<String, int> townProductionBonusByCommodity,
  required Map<String, List<({String tileKey, String terrain, String impBase})>>
  byResImproved,
  required Map<String, List<({String tileKey, String terrain})>>
  byResImprovable,
  required List<String> resourceKeysSorted,
  String? selectedTileKey,
  required Widget Function() political,
  required Widget Function() tileSection,
}) {
  ({
    Widget economic,
    Widget military,
    Widget civilian,
    Widget naval,
  })? cachedUnitSections;

  ({
    Widget economic,
    Widget military,
    Widget civilian,
    Widget naval,
  }) unitSections() {
    return cachedUnitSections ??= buildProvinceIntelGatedUnitSections(
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
      fortLevel: fortLevel,
      buildFortAction: buildFortAction,
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
      navalMission: navalMission,
      detachAndSail: detachAndSail,
      transferToHomeFleet: transferToHomeFleet,
      navalCombine: navalCombine,
      blockadeStatus: blockadeStatus,
      stationSpy: stationSpy,
      counterEspionage: counterEspionage,
      provinceDisplayName: provinceDisplayName,
      onHighlightTile: onHighlightTile,
      onHighlightTiles: onHighlightTiles,
      extractionSnapshot: extractionSnapshot,
      availableByCommodity: availableByCommodity,
      townProductionBonusByCommodity: townProductionBonusByCommodity,
      byResImproved: byResImproved,
      byResImprovable: byResImprovable,
      resourceKeysSorted: resourceKeysSorted,
      selectedTileKey: selectedTileKey,
    );
  }

  return assembleProvinceOverlayTabContent(
    l10n: l10n,
    political: political,
    tileSection: tileSection,
    economic: () => unitSections().economic,
    militarySection: () => unitSections().military,
    civilianSection: () => unitSections().civilian,
    naval: () => unitSections().naval,
  );
}
