/// Pending-work and shortcut gist lines for civilian unit rows.
/// SPEC/ui/civilian-units-panel.md.
library;

import 'package:colonizethis_app/core/services/game_service/game_service.dart'
    show GameMapData;
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/colonizethis_orders.dart';
import 'package:flutter/material.dart';

import 'build_improvement_next_yield_copy.dart';
import 'build_improvement_next_yield_gist_line.dart';
import 'purchase_land_payoff_copy.dart';
import 'purchase_land_payoff_gist_line.dart';

List<Widget> civilianUnitsPanelPendingWorkGistChildren({
  required AppLocalizations l10n,
  required Game game,
  required String humanPlayerId,
  required WorkOrder pendingWork,
  required bool readOnly,
  GameMapData? mapData,
}) {
  return [
    if (pendingWork.target == kWorkTargetPurchaseLand)
      Builder(
        builder: (context) {
          final payoff = purchaseLandPayoffCopyForTile(
            l10n: l10n,
            game: game,
            tileKey: pendingWork.targetTileKey,
            enabled: true,
            canMutateViaUi: !readOnly,
          );
          if (payoff == null) return const SizedBox.shrink();
          return PurchaseLandPayoffGistLine(text: payoff.gist);
        },
      ),
    if (pendingWork.target == kWorkTargetBuildImprovement)
      Builder(
        builder: (context) {
          final gist = buildImprovementNextYieldGistForTile(
            l10n: l10n,
            game: game,
            humanPlayerId: humanPlayerId,
            tileKey: pendingWork.targetTileKey,
            enabled: true,
            mapData: mapData,
            canMutateViaUi: !readOnly,
          );
          if (gist == null) return const SizedBox.shrink();
          return BuildImprovementYieldGistLine(text: gist);
        },
      ),
  ];
}

Widget wrapCivilianUnitsPanelAssignedWithShortcutGists({
  required Widget assigned,
  required AppLocalizations l10n,
  required Game game,
  required String humanPlayerId,
  required bool readOnly,
  GameMapData? mapData,
  String? buildImprovementShortcutTargetTileKey,
  String? purchaseLandShortcutTargetTileKey,
}) {
  if (readOnly) return assigned;
  final gist =
      (buildImprovementShortcutTargetTileKey != null &&
          buildImprovementShortcutTargetTileKey.isNotEmpty)
      ? buildImprovementNextYieldGistForTile(
          l10n: l10n,
          game: game,
          humanPlayerId: humanPlayerId,
          tileKey: buildImprovementShortcutTargetTileKey,
          enabled: true,
          mapData: mapData,
          canMutateViaUi: !readOnly,
        )
      : null;
  final payoff =
      (purchaseLandShortcutTargetTileKey != null &&
          purchaseLandShortcutTargetTileKey.isNotEmpty)
      ? purchaseLandPayoffCopyForTile(
          l10n: l10n,
          game: game,
          tileKey: purchaseLandShortcutTargetTileKey,
          enabled: true,
          canMutateViaUi: !readOnly,
        )
      : null;
  if (gist == null && payoff == null) return assigned;
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      assigned,
      if (gist != null) BuildImprovementYieldGistLine(text: gist),
      if (payoff != null) PurchaseLandPayoffGistLine(text: payoff.gist),
    ],
  );
}
