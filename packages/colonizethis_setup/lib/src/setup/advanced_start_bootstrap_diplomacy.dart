// Advanced-start diplomacy bootstrap (step 7). SPEC/game/advanced-starts.md.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

/// Pre-establishes consulates (50-turn) or embassies (100-turn) with every OW
/// minor and with tribes encountered during NW exploration.
Game applyAdvancedStartDiplomacy({
  required Game game,
  required AdvancedStartType startType,
  required Set<String> encounteredTribeIds,
}) {
  final stage = advancedStartDiplomacyOvertureStage(startType);
  if (stage == OvertureStage.none) return game;

  final sinceTurn = startType.startTurnNumber;
  final existingKeys = {
    for (final o in game.overtureStates) '${o.gpId}|${o.targetId}',
  };
  final additions = <OvertureState>[];

  for (final player in game.players) {
    for (final minor in game.minorNations) {
      final key = '${player.id}|${minor.id}';
      if (existingKeys.contains(key)) continue;
      existingKeys.add(key);
      additions.add(
        OvertureState(
          gpId: player.id,
          targetId: minor.id,
          stage: stage,
          sinceTurn: sinceTurn,
        ),
      );
    }
    for (final tribeId in encounteredTribeIds) {
      final key = '${player.id}|$tribeId';
      if (existingKeys.contains(key)) continue;
      existingKeys.add(key);
      additions.add(
        OvertureState(
          gpId: player.id,
          targetId: tribeId,
          stage: stage,
          sinceTurn: sinceTurn,
        ),
      );
    }
  }

  if (additions.isEmpty) return game;

  return game.copyWith(
    overtureStates: [...game.overtureStates, ...additions],
  );
}

/// Returns true when [game] has [stage] overtures from every GP to every minor.
bool advancedStartHasMinorOverturesForAllGps({
  required Game game,
  required OvertureStage stage,
}) {
  for (final player in game.players) {
    for (final minor in game.minorNations) {
      final overture = getOverture(game, player.id, minor.id);
      if (overture == null || overture.stage != stage) return false;
    }
  }
  return true;
}
