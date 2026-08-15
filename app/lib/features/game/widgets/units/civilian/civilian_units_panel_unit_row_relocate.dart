/// Spy Relocate from UNIT10001, including MAP20001 Station spy shortcut.
/// SPEC/ui/civilian-units-panel.md (Refs #4439).
library;

import 'dart:async';

import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_logic/civilian_intel_api.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import '../../../../../core/services/app_event_bus_panel_nav.dart';
import '../../../flame/map_state/province_station_spy_action_state.dart';
import 'civilian_units_panel_unit_row_pending.dart';

Future<void> onCivilianUnitsPanelRelocatePressed({
  required BuildContext context,
  required AppEventBus bus,
  required Game game,
  required Unit unit,
  required String humanPlayerId,
  required CivilianUnitsPanelUnitRowPending pending,
  required String? relocateShortcutTargetTileKey,
}) async {
  final shortcut = relocateShortcutTargetTileKey;
  if (shortcut == null || shortcut.isEmpty) {
    bus.closePanelThenEmit(
      StartCivilianRelocateSelectionEvent(unitId: unit.id),
    );
    return;
  }
  if (!stationSpyUnitIsEligibleRelocator(
    game: game,
    orders: pending.currentOrders,
    humanPlayerId: humanPlayerId,
    unit: unit,
    selectedTileKey: shortcut,
  )) {
    return;
  }
  final needsWarning = spyLeaveIntelWarningNeeded(
    game: game,
    orders: pending.currentOrders,
    humanPlayerId: humanPlayerId,
    spyUnitId: unit.id,
    newDestinationTileKey: shortcut,
  );
  if (needsWarning) {
    final l10n = appL10n(context);
    final completer = Completer<bool>();
    bus.emit(
      ConfirmDialogEvent(
        title: l10n.map_relocate_leaveIntel_title,
        message: l10n.map_relocate_leaveIntel_message,
        confirmLabel: l10n.map_relocate_leaveIntel_confirm,
        cancelLabel: l10n.map_relocate_leaveIntel_cancel,
        onResult: completer.complete,
      ),
    );
    final confirmed = await completer.future;
    if (!confirmed || !context.mounted) return;
  }
  bus.closePanelThenEmit(
    CivilianMoveRequestedEvent(
      humanPlayerId: humanPlayerId,
      moveOrder: MoveOrder(unitId: unit.id, destinationTileKey: shortcut),
    ),
  );
}
