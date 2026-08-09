import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'debug_set_diplomacy_common.dart';

DebugDiplomacyActionOutcome applyDebugDiplomacyNoAlliance(
  Game game,
  String factionA,
  String factionB,
  int turn,
) {
  final rel = getRelation(game, factionA, factionB);
  if (!(rel?.formalAlliance ?? false)) {
    return (
      game: game,
      message: 'No alliance to break between $factionA and $factionB '
          '(no change).',
      error: null,
    );
  }
  final nextRelations = upsertRelation(
    game.diplomacyRelations,
    factionA,
    factionB,
    (existing) => existing!.copyWith(formalAlliance: false, sinceTurn: turn),
  );
  final nextGame = appendDebugDiplomacyEvents(
    game.copyWith(diplomacyRelations: nextRelations),
    turn,
    [(type: DiplomaticEventType.allianceBroken, from: factionA, to: factionB)],
  );
  return (
    game: nextGame,
    message: 'Formal alliance broken between $factionA and $factionB.',
    error: null,
  );
}
