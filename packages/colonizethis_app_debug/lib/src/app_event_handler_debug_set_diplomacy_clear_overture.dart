import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'debug_set_diplomacy_common.dart';

DebugDiplomacyActionOutcome applyDebugDiplomacyClearOverture(
  Game game,
  String factionA,
  String factionB,
) {
  final existing = getOverture(game, factionA, factionB);
  if (existing == null || existing.stage == OvertureStage.none) {
    return (
      game: game,
      message: 'No overture to clear from $factionA toward $factionB '
          '(no change).',
      error: null,
    );
  }
  final nextOvertures = game.overtureStates
      .where((o) => !(o.gpId == factionA && o.targetId == factionB))
      .toList(growable: false);
  return (
    game: game.copyWith(overtureStates: nextOvertures),
    message: 'Overture cleared from $factionA toward $factionB.',
    error: null,
  );
}
