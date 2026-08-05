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
}) =>
    (prospectShortcutTargetTileKey != null &&
        prospectShortcutTargetTileKey.isNotEmpty) ||
    (exploreShortcutTargetTileKey != null &&
        exploreShortcutTargetTileKey.isNotEmpty) ||
    (buildImprovementShortcutTargetTileKey != null &&
        buildImprovementShortcutTargetTileKey.isNotEmpty) ||
    (buildRoadShortcutTargetTileKey != null &&
        buildRoadShortcutTargetTileKey.isNotEmpty);

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
  final targetTileKey = hasBuildRoadShortcut
      ? buildRoadShortcutTargetTileKey
      : hasBuildImprovementShortcut
      ? buildImprovementShortcutTargetTileKey
      : hasExploreShortcut
      ? exploreShortcutTargetTileKey
      : hasProspectShortcut
      ? prospectShortcutTargetTileKey
      : null;
  if (targetTileKey == null || targetTileKey.isEmpty) return;
  final workTarget = hasBuildRoadShortcut
      ? kWorkTargetBuildRoad
      : hasBuildImprovementShortcut
      ? kWorkTargetBuildImprovement
      : hasExploreShortcut
      ? kWorkTargetExplore
      : kWorkTargetProspect;
  if (!pending.isIdleNoPending || !availableWorkTargetIds.contains(workTarget)) {
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
