/// Explorer/prospect/improvement shortcut assign for civilian unit rows.
/// SPEC/ui/civilian-units-panel.md.
library;

import 'package:colonizethis_orders/colonizethis_orders.dart';

import 'package:colonizethis_models/colonizethis_models.dart';

import '../../../../../core/services/app_event_bus_panel_nav.dart';
import 'civilian_units_panel_unit_row_pending.dart';

bool civilianUnitsPanelUnitRowInExplorerShortcutMode({
  required String? prospectShortcutTargetTileKey,
  required String? exploreShortcutTargetTileKey,
  required String? buildImprovementShortcutTargetTileKey,
  required String? buildRoadShortcutTargetTileKey,
  required String? buildFortShortcutTargetTileKey,
  required String? buildPortShortcutTargetTileKey,
  required String? buildRailShortcutTargetTileKey,
  required String? purchaseLandShortcutTargetTileKey,
  required String? upgradeTownShortcutTargetTileKey,
}) =>
    (prospectShortcutTargetTileKey != null &&
        prospectShortcutTargetTileKey.isNotEmpty) ||
    (exploreShortcutTargetTileKey != null &&
        exploreShortcutTargetTileKey.isNotEmpty) ||
    (buildImprovementShortcutTargetTileKey != null &&
        buildImprovementShortcutTargetTileKey.isNotEmpty) ||
    (buildRoadShortcutTargetTileKey != null &&
        buildRoadShortcutTargetTileKey.isNotEmpty) ||
    (buildFortShortcutTargetTileKey != null &&
        buildFortShortcutTargetTileKey.isNotEmpty) ||
    (buildPortShortcutTargetTileKey != null &&
        buildPortShortcutTargetTileKey.isNotEmpty) ||
    (buildRailShortcutTargetTileKey != null &&
        buildRailShortcutTargetTileKey.isNotEmpty) ||
    (purchaseLandShortcutTargetTileKey != null &&
        purchaseLandShortcutTargetTileKey.isNotEmpty) ||
    (upgradeTownShortcutTargetTileKey != null &&
        upgradeTownShortcutTargetTileKey.isNotEmpty);

void startCivilianUnitsPanelUnitRowShortcutAssign({
  required AppEventBus bus,
  required Unit unit,
  required String humanPlayerId,
  required CivilianUnitsPanelUnitRowPending pending,
  required List<String> availableWorkTargetIds,
  required String? prospectShortcutTargetTileKey,
  required String? exploreShortcutTargetTileKey,
  required String? buildImprovementShortcutTargetTileKey,
  required String? buildRoadShortcutTargetTileKey,
  required String? buildFortShortcutTargetTileKey,
  required String? buildPortShortcutTargetTileKey,
  required String? buildRailShortcutTargetTileKey,
  required String? purchaseLandShortcutTargetTileKey,
  required String? upgradeTownShortcutTargetTileKey,
}) {
  final hasExploreShortcut =
      exploreShortcutTargetTileKey != null &&
      exploreShortcutTargetTileKey.isNotEmpty;
  final hasProspectShortcut =
      prospectShortcutTargetTileKey != null &&
      prospectShortcutTargetTileKey.isNotEmpty;
  final hasBuildImprovementShortcut =
      buildImprovementShortcutTargetTileKey != null &&
      buildImprovementShortcutTargetTileKey.isNotEmpty;
  final hasBuildRoadShortcut =
      buildRoadShortcutTargetTileKey != null &&
      buildRoadShortcutTargetTileKey.isNotEmpty;
  final hasBuildFortShortcut =
      buildFortShortcutTargetTileKey != null &&
      buildFortShortcutTargetTileKey.isNotEmpty;
  final hasBuildPortShortcut =
      buildPortShortcutTargetTileKey != null &&
      buildPortShortcutTargetTileKey.isNotEmpty;
  final hasBuildRailShortcut =
      buildRailShortcutTargetTileKey != null &&
      buildRailShortcutTargetTileKey.isNotEmpty;
  final hasPurchaseLandShortcut =
      purchaseLandShortcutTargetTileKey != null &&
      purchaseLandShortcutTargetTileKey.isNotEmpty;
  final hasUpgradeTownShortcut =
      upgradeTownShortcutTargetTileKey != null &&
      upgradeTownShortcutTargetTileKey.isNotEmpty;
  final targetTileKey = hasPurchaseLandShortcut
      ? purchaseLandShortcutTargetTileKey
      : hasBuildRoadShortcut
      ? buildRoadShortcutTargetTileKey
      : hasBuildFortShortcut
      ? buildFortShortcutTargetTileKey
      : hasBuildPortShortcut
      ? buildPortShortcutTargetTileKey
      : hasBuildRailShortcut
      ? buildRailShortcutTargetTileKey
      : hasUpgradeTownShortcut
      ? upgradeTownShortcutTargetTileKey
      : hasBuildImprovementShortcut
      ? buildImprovementShortcutTargetTileKey
      : hasExploreShortcut
      ? exploreShortcutTargetTileKey
      : hasProspectShortcut
      ? prospectShortcutTargetTileKey
      : null;
  if (targetTileKey == null || targetTileKey.isEmpty) return;
  final workTarget = hasPurchaseLandShortcut
      ? kWorkTargetPurchaseLand
      : hasBuildRoadShortcut
      ? kWorkTargetBuildRoad
      : hasBuildFortShortcut
      ? kWorkTargetBuildFort
      : hasBuildPortShortcut
      ? kWorkTargetBuildPort
      : hasBuildRailShortcut
      ? kWorkTargetBuildRail
      : hasUpgradeTownShortcut
      ? kWorkTargetUpgradeTown
      : hasBuildImprovementShortcut
      ? kWorkTargetBuildImprovement
      : hasExploreShortcut
      ? kWorkTargetExplore
      : kWorkTargetProspect;
  if (!pending.isIdleNoPending ||
      !availableWorkTargetIds.contains(workTarget)) {
    return;
  }
  bus.closePanelThenEmit(
    UpsertPendingCivilianWorkOrderRequestedEvent(
      playerId: humanPlayerId,
      workOrder: WorkOrder(
        unitId: unit.id,
        target: workTarget,
        targetTileKey: targetTileKey,
      ),
    ),
  );
}
