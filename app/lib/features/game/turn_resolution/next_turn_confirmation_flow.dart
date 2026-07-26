import 'package:colonizethis_logic/colonizethis_logic.dart'
    show findCiviliansMissingWorkOrders;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import '../flame/overlays/next_turn_confirmation_dialog.dart';

/// Shared end-turn confirmation for map and Flame-canvas entry points.
///
/// Callers read providers in their own scope and pass narrow deps — do not
/// thread [WidgetRef] into this helper (`repo.app_widget_ref_parameter_smell`).
Future<bool> confirmNextTurnWithIdleCivilianWarning({
  required BuildContext context,
  required Game game,
  required int currentTurn,
  required String humanPlayerId,
  required Orders orders,
  required bool warnIdleCiviliansEnabled,
  required AppEventBus bus,
  required void Function() onDisableIdleCivilianWarning,
}) async {
  final missing = findCiviliansMissingWorkOrders(
    game: game,
    orders: orders,
    humanPlayerId: humanPlayerId,
  );
  final result = await showNextTurnConfirmationDialog(
    context,
    currentTurn: currentTurn,
    civiliansMissingWork: warnIdleCiviliansEnabled ? missing : const [],
    onGoToCivilian: (entry) {
      bus.emit(
        LocateMapTileEvent(tileKey: entry.tileKey, regionId: entry.regionId),
      );
      bus.emit(
        OpenCivilianUnitsPanelEvent(initialSelectedUnitId: entry.unitId),
      );
    },
  );
  if (result == null || !result.confirmed) {
    return false;
  }
  if (result.persistDontShowAgain) {
    onDisableIdleCivilianWarning();
  }
  return true;
}
