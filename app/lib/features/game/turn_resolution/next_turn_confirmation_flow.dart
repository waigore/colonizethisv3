import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import '../flame/overlays/next_turn_confirmation_dialog.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/civilian_intel_api.dart'
    show findCiviliansMissingWorkOrders;
import 'package:colonizethis_app_l10n/l10n/l10n.dart';

import 'staged_decree_go_to.dart';
import 'staged_decree_review_builder.dart';

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
  MapTopology? topology,
}) async {
  final missing = findCiviliansMissingWorkOrders(
    game: game,
    orders: orders,
    humanPlayerId: humanPlayerId,
  );
  final stagedReview = buildStagedDecreeReview(
    orders: orders,
    humanPlayerId: humanPlayerId,
    l10n: appL10n(context),
    game: game,
  );
  final result = await showNextTurnConfirmationDialog(
    context,
    currentTurn: currentTurn,
    civiliansMissingWork: warnIdleCiviliansEnabled ? missing : const [],
    stagedReview: stagedReview,
    onGoToCivilian: (entry) {
      bus.emit(
        LocateMapTileEvent(tileKey: entry.tileKey, regionId: entry.regionId),
      );
      bus.emit(
        OpenCivilianUnitsPanelEvent(initialSelectedUnitId: entry.unitId),
      );
    },
    onGoToStagedFamily: (family) {
      emitStagedDecreeGoTo(
        bus: bus,
        game: game,
        humanPlayerId: humanPlayerId,
        orders: orders,
        family: family,
        topology: topology,
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
