/// Pending-work gist lines for civilian unit rows.
/// SPEC/ui/civilian-units-panel.md.
library;

import 'package:colonizethis_app/core/services/game_service/game_service.dart'
    show GameMapData;
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/colonizethis_orders.dart';
import 'package:flutter/material.dart';

import 'build_fort_payoff_copy.dart';
import 'build_fort_payoff_gist_line.dart';
import 'build_improvement_next_yield_copy.dart';
import 'build_improvement_next_yield_gist_line.dart';
import 'explore_payoff_copy.dart';
import 'explore_payoff_gist_line.dart';
import 'prospect_payoff_copy.dart';
import 'purchase_land_payoff_copy.dart';
import 'purchase_land_payoff_gist_line.dart';
import 'transport_step_yield_copy.dart';
import 'transport_step_yield_gist_line.dart';
import 'upgrade_town_payoff_copy.dart';

export 'civilian_units_panel_unit_row_shortcut_gists.dart';

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
    if (pendingWork.target == kWorkTargetBuildRoad ||
        pendingWork.target == kWorkTargetBuildPort ||
        pendingWork.target == kWorkTargetBuildRail)
      Builder(
        builder: (context) {
          final gist = transportStepYieldGistForTile(
            l10n: l10n,
            game: game,
            humanPlayerId: humanPlayerId,
            tileKey: pendingWork.targetTileKey,
            workTarget: pendingWork.target,
            enabled: true,
            mapData: mapData,
            canMutateViaUi: !readOnly,
          );
          if (gist == null) return const SizedBox.shrink();
          return TransportStepYieldGistLine(text: gist);
        },
      ),
    if (pendingWork.target == kWorkTargetBuildFort)
      Builder(
        builder: (context) {
          final gist = buildFortPayoffGistForTile(
            l10n: l10n,
            game: game,
            humanPlayerId: humanPlayerId,
            tileKey: pendingWork.targetTileKey,
            enabled: true,
            canMutateViaUi: !readOnly,
          );
          if (gist == null) return const SizedBox.shrink();
          return BuildFortPayoffGistLine(text: gist);
        },
      ),
    if (pendingWork.target == kWorkTargetExplore)
      Builder(
        builder: (context) {
          final gist = explorePayoffGistForTile(
            l10n: l10n,
            game: game,
            tileKey: pendingWork.targetTileKey,
            enabled: true,
            canMutateViaUi: !readOnly,
          );
          if (gist == null) return const SizedBox.shrink();
          return ExplorePayoffGistLine(text: gist);
        },
      ),
    ...prospectPayoffPendingGistChildren(l10n, game, pendingWork, readOnly),
    ...upgradeTownPayoffPendingGistChildren(
      l10n: l10n,
      game: game,
      humanPlayerId: humanPlayerId,
      pendingWork: pendingWork,
      readOnly: readOnly,
      mapData: mapData,
    ),
  ];
}
