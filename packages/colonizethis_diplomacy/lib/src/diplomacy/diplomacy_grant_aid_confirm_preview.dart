/// First-order Grant Aid Cost / Effect lines for DIPL20001.
/// SPEC/ui/grant-or-subsidy-dialog.md; Refs #4632.
library;

import 'package:colonizethis_models/colonizethis_models.dart';

import 'diplomacy_relation_lookup.dart';

/// Grant Aid Cost / Effect. Standing modifier is amount-independent.
List<String> grantAidConfirmPreviewLines({
  required Game game,
  required String humanPlayerId,
  required String targetFactionId,
  required String targetDisplayName,
  required int amount,
}) {
  final currentScore =
      getRelation(game, humanPlayerId, targetFactionId)?.score ??
      relationScoreNeutral;
  final nextScore = (currentScore + grantAidRelationScoreDelta).clamp(
    relationScoreMin,
    relationScoreMax,
  );
  final currentWord = relationScoreToDisplayLabel(currentScore);
  final nextWord = relationScoreToDisplayLabel(nextScore);
  final wordLine = currentWord == nextWord
      ? 'Effect: Standing word stays $currentWord.'
      : 'Effect: Standing word becomes $nextWord.';
  return [
    'Cost: £$amount from your treasury when the grant resolves.',
    'Effect: Standing with $targetDisplayName improves when the grant resolves.',
    'Effect: A larger gift this turn does not improve standing further.',
    wordLine,
  ];
}
