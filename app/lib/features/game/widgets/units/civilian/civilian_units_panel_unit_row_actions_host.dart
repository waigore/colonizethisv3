/// Row action buttons and cancel confirmation for civilian unit rows.
/// SPEC/ui/civilian-units-panel.md.
library;

import 'dart:async';

import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:flutter/material.dart';

import '../../../../../core/services/app_event_bus_panel_nav.dart';
import '../shared/units_entity_action_row.dart';
import 'civilian_units_panel_support_unit_row_actions.dart';
import 'civilian_units_panel_unit_row_pending.dart';
import 'civilian_units_panel_unit_row_shortcuts.dart';

import 'package:colonizethis_models/colonizethis_models.dart';

Future<void> confirmCancelCivilianUnitsPanelUnitRowWork({
  required BuildContext context,
  required AppEventBus bus,
  required String humanPlayerId,
  required Unit unit,
  required CivilianUnitsPanelUnitRowPending pending,
}) async {
  final completer = Completer<bool>();
  bus.emit(
    ConfirmDialogEvent(
      title: 'Cancel work order?',
      message:
          'This will cancel the current or pending work for this unit. Materials are not refunded.',
      confirmLabel: 'Yes',
      cancelLabel: 'No',
      onResult: completer.complete,
    ),
  );
  final confirmed = await completer.future;
  if (!confirmed || !context.mounted) return;
  final pendingMove = pending.pendingMoveOrder;
  if (pendingMove != null) {
    bus.emit(
      RemovePendingCivilianMoveRequestedEvent(
        playerId: humanPlayerId,
        unitId: unit.id,
      ),
    );
    return;
  }
  final idx = pending.pendingIndex;
  if (idx != null) {
    bus.emit(
      RemovePendingWorkOrderRequestedEvent(
        playerId: humanPlayerId,
        index: idx,
      ),
    );
  } else if (unit.currentWork != null) {
    bus.emit(CancelInProgressCivilianWorkRequestedEvent(unitId: unit.id));
  }
}

List<UnitsEntityAction> buildCivilianUnitsPanelUnitRowActions({
  required AppLocalizations l10n,
  required BuildContext context,
  required AppEventBus bus,
  required Unit unit,
  required String humanPlayerId,
  required CivilianUnitsPanelUnitRowPending pending,
  required bool readOnly,
  required bool showActions,
  required bool inExplorerShortcutMode,
  required List<String> availableWorkTargetIds,
  required String? tileKeyForLocate,
  required String? regionIdForLocate,
  required String? prospectShortcutTargetTileKey,
  required String? exploreShortcutTargetTileKey,
  required String? buildImprovementShortcutTargetTileKey,
  required String? buildRoadShortcutTargetTileKey,
}) {
  if (readOnly) {
    return const <UnitsEntityAction>[];
  }
  final canLocate =
      tileKeyForLocate != null &&
      tileKeyForLocate.isNotEmpty &&
      regionIdForLocate != null;
  return [
    if (showActions && pending.canRelocateSpy)
      UnitsEntityAction(
        tooltip: l10n.civilian_units_relocate,
        icon: Icons.directions_walk,
        label: l10n.civilian_units_relocate,
        onPressed: () {
          bus.closePanelThenEmit(
            StartCivilianRelocateSelectionEvent(unitId: unit.id),
          );
        },
      ),
    if (showActions && pending.isIdleNoPending && !pending.hasPendingWorkOnly)
      UnitsEntityAction(
        tooltip: l10n.civilian_units_assign,
        icon: Icons.playlist_add,
        label: l10n.civilian_units_assign,
        onPressed: !pending.isSpy && inExplorerShortcutMode
            ? () => startCivilianUnitsPanelUnitRowShortcutAssign(
                bus: bus,
                unit: unit,
                humanPlayerId: humanPlayerId,
                pending: pending,
                availableWorkTargetIds: availableWorkTargetIds,
                prospectShortcutTargetTileKey: prospectShortcutTargetTileKey,
                exploreShortcutTargetTileKey: exploreShortcutTargetTileKey,
                buildImprovementShortcutTargetTileKey:
                    buildImprovementShortcutTargetTileKey,
                buildRoadShortcutTargetTileKey: buildRoadShortcutTargetTileKey,
              )
            : () => showCivilianUnitsPanelOrderMenu(
                context,
                bus: bus,
                unit: unit,
                availableWorkTargetIds: availableWorkTargetIds,
              ),
      ),
    if (showActions && pending.hasWork)
      UnitsEntityAction(
        tooltip: l10n.common_cancel,
        icon: Icons.cancel_outlined,
        label: l10n.common_cancel,
        variant: UnitsEntityActionVariant.danger,
        onPressed: () => confirmCancelCivilianUnitsPanelUnitRowWork(
          context: context,
          bus: bus,
          humanPlayerId: humanPlayerId,
          unit: unit,
          pending: pending,
        ),
      ),
    UnitsEntityAction(
      tooltip: l10n.common_locate,
      icon: Icons.my_location,
      label: l10n.common_locate,
      iconOnly: true,
      onPressed: canLocate
          ? () {
              bus.emit(
                LocateMapTileEvent(
                  tileKey: tileKeyForLocate,
                  regionId: regionIdForLocate,
                ),
              );
            }
          : null,
    ),
  ];
}
