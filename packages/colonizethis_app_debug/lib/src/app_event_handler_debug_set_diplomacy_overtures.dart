import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'debug_set_diplomacy_common.dart';

DebugDiplomacyActionOutcome applyDebugDiplomacyOverture(
  Game game,
  String factionA,
  String factionB,
  int turn,
  OvertureStage stage,
) {
  final rel = getRelation(game, factionA, factionB);
  if (rel?.atWar ?? false) {
    return (
      game: null,
      message: null,
      error: '$kDebugSetDiplomacyPrefix rejected: cannot set an overture while $factionA and '
          '$factionB are at war.',
    );
  }
  final existing = getOverture(game, factionA, factionB);
  final List<OvertureState> nextOvertures;
  if (existing == null) {
    nextOvertures = [
      ...game.overtureStates,
      OvertureState(
        gpId: factionA,
        targetId: factionB,
        stage: stage,
        sinceTurn: turn,
      ),
    ];
  } else {
    nextOvertures = game.overtureStates
        .map(
          (o) => o.gpId == factionA && o.targetId == factionB
              ? o.copyWith(stage: stage, sinceTurn: turn)
              : o,
        )
        .toList(growable: false);
  }
  return (
    game: game.copyWith(overtureStates: nextOvertures),
    message: 'Overture ${stage.name} set from $factionA toward $factionB.',
    error: null,
  );
}
