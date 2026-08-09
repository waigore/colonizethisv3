import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'debug_set_diplomacy_common.dart';

DebugDiplomacyActionOutcome applyDebugDiplomacyAlliance(
  Game game,
  String factionA,
  String factionB,
  int turn,
) {
  if (!isGreatPower(game, factionA) || !isGreatPower(game, factionB)) {
    return (
      game: null,
      message: null,
      error: '$kDebugSetDiplomacyPrefix rejected: alliance requires both factions to be '
          'Great Powers.',
    );
  }
  final rel = getRelation(game, factionA, factionB);
  if (rel?.atWar ?? false) {
    return (
      game: null,
      message: null,
      error: '$kDebugSetDiplomacyPrefix rejected: cannot form an alliance while $factionA and '
          '$factionB are at war.',
    );
  }
  final nextRelations = upsertRelation(
    game.diplomacyRelations,
    factionA,
    factionB,
    (existing) =>
        (existing ?? DiplomacyRelation(factionId1: factionA, factionId2: factionB))
            .copyWith(formalAlliance: true, sinceTurn: turn),
  );
  final nextGame = appendDebugDiplomacyEvents(
    game.copyWith(diplomacyRelations: nextRelations),
    turn,
    [(type: DiplomaticEventType.allianceFormed, from: factionA, to: factionB)],
  );
  return (
    game: nextGame,
    message: 'Formal alliance set between $factionA and $factionB.',
    error: null,
  );
}
