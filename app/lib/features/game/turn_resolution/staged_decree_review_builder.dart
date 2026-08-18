/// Builds [StagedDecreeReview] from the human slice of [Orders].
/// SPEC: SPEC/ui/components/staged-decree-review.md
library;

import 'package:colonizethis_app/features/game/turn_resolution/staged_decree_review.dart';
import 'package:colonizethis_app/features/game/turn_resolution/staged_decree_review_builder_families.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

/// Human-player draft review. Research rows require a tech id and funding
/// other than [ResearchFundingLevel.none]. Idle Spies and empty seats are
/// never synthesized.
StagedDecreeReview buildStagedDecreeReview({
  required Orders orders,
  required String humanPlayerId,
  required AppLocalizations l10n,
  Game? game,
}) {
  final families = <StagedDecreeFamilyGroup>[
    stagedDecreeWorkFamily(orders, humanPlayerId, l10n, game),
    stagedDecreeRelocateFamily(orders, humanPlayerId, l10n, game),
    stagedDecreeArmyFamily(orders, humanPlayerId, l10n, game),
    stagedDecreeFleetFamily(orders, humanPlayerId, l10n, game),
    stagedDecreeTrainFamily(orders, humanPlayerId, l10n),
    stagedDecreeLabourFamily(orders, humanPlayerId, l10n),
    stagedDecreeDiplomacyFamily(orders, humanPlayerId, l10n, game),
    stagedDecreeTradeFamily(orders, humanPlayerId, l10n),
    stagedDecreeResearchFamily(orders, humanPlayerId, l10n),
  ].where((g) => g.rows.isNotEmpty).toList();
  if (families.isEmpty) {
    return StagedDecreeReview.empty;
  }
  return StagedDecreeReview(families: families);
}
