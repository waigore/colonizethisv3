import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'debug_set_diplomacy_common.dart';

DebugDiplomacyActionOutcome applyDebugDiplomacyPeace(
  Game game,
  String factionA,
  String factionB,
  int turn,
) {
  final rel = getRelation(game, factionA, factionB);
  if (rel == null || rel.atPeace) {
    return (
      game: null,
      message: null,
      error:
          '$kDebugSetDiplomacyPrefix rejected: $factionA and $factionB are already at peace.',
    );
  }
  final nextRelations = upsertRelation(
    game.diplomacyRelations,
    factionA,
    factionB,
    (existing) =>
        (existing ?? DiplomacyRelation(factionId1: factionA, factionId2: factionB))
            .copyWith(state: RelationState.atPeace, sinceTurn: turn),
  );
  final nextGame = appendDebugDiplomacyEvents(
    game.copyWith(diplomacyRelations: nextRelations),
    turn,
    [(type: DiplomaticEventType.peace, from: factionA, to: factionB)],
  );
  return (
    game: nextGame,
    message: 'Peace set between $factionA and $factionB.',
    error: null,
  );
}
