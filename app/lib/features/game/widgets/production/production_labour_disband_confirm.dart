// Confirm-then-apply path for immediate trained-worker Disband.
// SPEC/ui/production-panel.md § Disband (immediate). Refs #4601.

import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import '../../../../widgets/ct_confirm_dialog.dart';
import 'production_labour_recruit_economy_mutations.dart';

/// Player-facing singular rank name for Disband confirm copy.
String labourDisbandConfirmTierName(AppLocalizations l10n, WorkerTier tier) {
  switch (tier) {
    case WorkerTier.peasant:
      return l10n.production_workerSingularPeasant;
    case WorkerTier.apprentice:
      return l10n.production_workerSingularApprentice;
    case WorkerTier.journeyman:
      return l10n.production_workerSingularJourneyman;
    case WorkerTier.master:
      return l10n.production_workerSingularMaster;
  }
}

/// Shows the Disband confirm. Peasant is invalid and returns false.
Future<bool> showImmediateLabourDisbandConfirm({
  required BuildContext context,
  required WorkerTier tier,
}) async {
  if (tier == WorkerTier.peasant) return false;
  final l10n = appL10n(context);
  final name = labourDisbandConfirmTierName(l10n, tier);
  return showCtConfirmDialog(
    context,
    title: l10n.production_labourDisbandConfirmTitle(name),
    message: l10n.production_labourDisbandConfirmBody(name),
    confirmLabel: l10n.production_labourDisband,
    cancelLabel: l10n.common_cancel,
    useRootNavigator: false,
  );
}

/// Confirm, then apply [gameWithImmediateDisband]. No-ops when dismissed.
Future<void> confirmAndApplyImmediateLabourDisband({
  required BuildContext context,
  required WorkerTier tier,
  required bool canEdit,
  required Game Function() readGame,
  required void Function(Game game) writeGame,
  required String playerId,
}) async {
  if (!canEdit) return;
  final confirmed = await showImmediateLabourDisbandConfirm(
    context: context,
    tier: tier,
  );
  if (!confirmed) return;
  if (!context.mounted) return;
  final nextGame = gameWithImmediateDisband(
    game: readGame(),
    playerId: playerId,
    tier: tier,
  );
  if (nextGame == null) return;
  writeGame(nextGame);
}
