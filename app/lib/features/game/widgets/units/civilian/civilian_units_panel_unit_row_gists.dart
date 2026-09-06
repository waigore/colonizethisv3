/// Pending-work and shortcut gist lines for civilian unit rows.
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
import 'purchase_land_payoff_copy.dart';
import 'purchase_land_payoff_gist_line.dart';
import 'spy_research_insight_copy.dart';
import 'spy_research_insight_gist_line.dart';
import 'transport_step_yield_copy.dart';
import 'transport_step_yield_gist_line.dart';

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
  ];
}

Widget wrapCivilianUnitsPanelAssignedWithShortcutGists({
  required Widget assigned,
  required AppLocalizations l10n,
  required Game game,
  required Orders currentOrders,
  required String humanPlayerId,
  required bool readOnly,
  GameMapData? mapData,
  String? buildImprovementShortcutTargetTileKey,
  String? purchaseLandShortcutTargetTileKey,
  String? buildRoadShortcutTargetTileKey,
  String? buildPortShortcutTargetTileKey,
  String? buildRailShortcutTargetTileKey,
  String? buildFortShortcutTargetTileKey,
  String? exploreShortcutTargetTileKey,
  String? relocateShortcutTargetTileKey,
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
  String? transportGistFor(String? tileKey, String workTarget) {
    if (tileKey == null || tileKey.isEmpty) return null;
    return transportStepYieldGistForTile(
      l10n: l10n,
      game: game,
      humanPlayerId: humanPlayerId,
      tileKey: tileKey,
      workTarget: workTarget,
      enabled: true,
      mapData: mapData,
      canMutateViaUi: !readOnly,
    );
  }

  final buildRoadGist = transportGistFor(
    buildRoadShortcutTargetTileKey,
    kWorkTargetBuildRoad,
  );
  final buildPortGist = transportGistFor(
    buildPortShortcutTargetTileKey,
    kWorkTargetBuildPort,
  );
  final buildRailGist = transportGistFor(
    buildRailShortcutTargetTileKey,
    kWorkTargetBuildRail,
  );
  final transportGist = buildRoadGist ?? buildPortGist ?? buildRailGist;
  final buildFortGist =
      (buildFortShortcutTargetTileKey != null &&
          buildFortShortcutTargetTileKey.isNotEmpty)
      ? buildFortPayoffGistForTile(
          l10n: l10n,
          game: game,
          humanPlayerId: humanPlayerId,
          tileKey: buildFortShortcutTargetTileKey,
          enabled: true,
          canMutateViaUi: !readOnly,
        )
      : null;
  final exploreGist =
      (exploreShortcutTargetTileKey != null &&
          exploreShortcutTargetTileKey.isNotEmpty)
      ? explorePayoffGistForTile(
          l10n: l10n,
          game: game,
          tileKey: exploreShortcutTargetTileKey,
          enabled: true,
          canMutateViaUi: !readOnly,
        )
      : null;
  final spyRelocateGist =
      (relocateShortcutTargetTileKey != null &&
          relocateShortcutTargetTileKey.isNotEmpty)
      ? spyResearchInsightGistTextForTile(
          l10n: l10n,
          game: game,
          orders: currentOrders,
          humanPlayerId: humanPlayerId,
          tileKey: relocateShortcutTargetTileKey,
        )
      : null;
  if (gist == null &&
      payoff == null &&
      transportGist == null &&
      buildFortGist == null &&
      exploreGist == null &&
      spyRelocateGist == null) {
    return assigned;
  }
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      assigned,
      if (gist != null) BuildImprovementYieldGistLine(text: gist),
      if (payoff != null) PurchaseLandPayoffGistLine(text: payoff.gist),
      if (transportGist != null) TransportStepYieldGistLine(text: transportGist),
      if (buildFortGist != null) BuildFortPayoffGistLine(text: buildFortGist),
      if (exploreGist != null) ExplorePayoffGistLine(text: exploreGist),
      if (spyRelocateGist != null)
        SpyResearchInsightGistLine(text: spyRelocateGist),
    ],
  );
}
