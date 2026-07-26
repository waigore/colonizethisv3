import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/ux_settings_keys.dart';
import '../../../providers/app_event_bus_provider.dart';
import '../../../providers/games_provider.dart';
import '../../../providers/settings_provider.dart';
import '../widgets/shell/shell_player_context.dart';
import '../flame/overlays/next_turn_confirmation_dialog.dart';
import 'civilians_missing_work_orders.dart';

/// Shared end-turn confirmation for map and Flame-canvas entry points.
Future<bool> confirmNextTurnWithIdleCivilianWarning({
  required BuildContext context,
  required WidgetRef ref,
  required Game game,
  required int currentTurn,
}) async {
  final shell = ref.read(shellPlayerContextProvider);
  final humanPlayerId = shell.mapPlayerIdFor(game);
  final orders = ref.read(currentOrdersProvider);
  final settings = ref.read(settingsProvider);
  final warnEnabled =
      settings[UxSettingsKeys.warnIdleCiviliansOnEndTurn] as bool? ?? true;
  final missing = findCiviliansMissingWorkOrders(
    game: game,
    orders: orders,
    humanPlayerId: humanPlayerId,
  );
  final bus = ref.read(appEventBusProvider);
  final result = await showNextTurnConfirmationDialog(
    context,
    currentTurn: currentTurn,
    civiliansMissingWork: warnEnabled ? missing : const [],
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
    ref
        .read(settingsProvider.notifier)
        .setValue(UxSettingsKeys.warnIdleCiviliansOnEndTurn, false);
  }
  return true;
}
