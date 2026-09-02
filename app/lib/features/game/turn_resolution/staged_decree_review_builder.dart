/// Builds [StagedDecreeReview] from the human slice of [Orders].
/// SPEC: SPEC/ui/components/staged-decree-review.md
library;

import 'package:colonizethis_app/features/game/turn_resolution/staged_decree_review.dart';
import 'package:colonizethis_app/features/game/turn_resolution/staged_decree_review_builder_compact.dart';
import 'package:colonizethis_app/features/game/turn_resolution/staged_decree_review_builder_families.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

/// Human-player draft review for `DLG60001` first paint.
///
/// Returns compact family counts only — per-decree row labels are built on
/// **Review decrees** via [expandStagedDecreeReview] (Refs #4715).
StagedDecreeReview buildStagedDecreeReview({
  required Orders orders,
  required String humanPlayerId,
  required AppLocalizations l10n,
  Game? game,
}) {
  final families = <StagedDecreeFamilyGroup>[
    ?stagedDecreeWorkFamilyCompact(orders, humanPlayerId, l10n),
    ?stagedDecreeRelocateFamilyCompact(orders, humanPlayerId, l10n),
    ?stagedDecreeArmyFamilyCompact(orders, humanPlayerId, l10n),
    ?stagedDecreeFleetFamilyCompact(orders, humanPlayerId, l10n),
    ?stagedDecreeTrainFamilyCompact(orders, humanPlayerId, l10n),
    ?stagedDecreeLabourFamilyCompact(orders, humanPlayerId, l10n),
    ?stagedDecreeDiplomacyFamilyCompact(orders, humanPlayerId, l10n),
    ?stagedDecreeTradeFamilyCompact(orders, humanPlayerId, l10n),
    ?stagedDecreeResearchFamilyCompact(orders, humanPlayerId, l10n),
  ];
  if (families.isEmpty) {
    return StagedDecreeReview.empty;
  }
  return StagedDecreeReview(families: families);
}

/// Fills per-decree row labels for every family in [compact].
StagedDecreeReview expandStagedDecreeReview({
  required StagedDecreeReview compact,
  required Orders orders,
  required String humanPlayerId,
  required AppLocalizations l10n,
  Game? game,
}) {
  if (compact.isEmpty) {
    return StagedDecreeReview.empty;
  }
  final families = [
    for (final group in compact.families)
      _expandStagedDecreeFamily(
        family: group.family,
        orders: orders,
        humanPlayerId: humanPlayerId,
        l10n: l10n,
        game: game,
      ),
  ];
  return StagedDecreeReview(families: families);
}

StagedDecreeFamilyGroup _expandStagedDecreeFamily({
  required StagedDecreeFamily family,
  required Orders orders,
  required String humanPlayerId,
  required AppLocalizations l10n,
  Game? game,
}) {
  return switch (family) {
    StagedDecreeFamily.civilianWork => stagedDecreeWorkFamily(
      orders,
      humanPlayerId,
      l10n,
      game,
    ),
    StagedDecreeFamily.spyRelocate => stagedDecreeRelocateFamily(
      orders,
      humanPlayerId,
      l10n,
      game,
    ),
    StagedDecreeFamily.armyMoves => stagedDecreeArmyFamily(
      orders,
      humanPlayerId,
      l10n,
      game,
    ),
    StagedDecreeFamily.fleet => stagedDecreeFleetFamily(
      orders,
      humanPlayerId,
      l10n,
      game,
    ),
    StagedDecreeFamily.trainingBuilds => stagedDecreeTrainFamily(
      orders,
      humanPlayerId,
      l10n,
    ),
    StagedDecreeFamily.labourRecruit => stagedDecreeLabourFamily(
      orders,
      humanPlayerId,
      l10n,
    ),
    StagedDecreeFamily.diplomacy => stagedDecreeDiplomacyFamily(
      orders,
      humanPlayerId,
      l10n,
      game,
    ),
    StagedDecreeFamily.trade => stagedDecreeTradeFamily(
      orders,
      humanPlayerId,
      l10n,
    ),
    StagedDecreeFamily.research => stagedDecreeResearchFamily(
      orders,
      humanPlayerId,
      l10n,
    ),
  };
}
