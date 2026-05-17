import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/ai_api.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'goal_manager.dart';

/// Splits regiments from the Home Army into a field army at the capital when
/// the AI is pursuing conquest and all regiments are stuck in the Home Army
/// (which cannot march). SPEC/game/military-armies.md; SPEC/ai/ai-architecture.md.
///
/// Mutates [game] in place via [applyArmySplit] so subsequent suggestion and
/// validation see the field army id.
Game prepareConquestFieldArmy({
  required Game game,
  required String nationId,
  required int provincesToVictory,
  required StrategicGoal primaryGoal,
}) {
  final shouldPrep = primaryGoal == StrategicGoal.conquer ||
      provincesToVictory > kBuildRegimentVictoryPaceThreshold;
  if (!shouldPrep) return game;

  final homeId = homeArmyIdFor(nationId);
  Army? homeArmy;
  for (final a in game.worldState.armies) {
    if (a.id == homeId && a.ownerId == nationId) {
      homeArmy = a;
      break;
    }
  }
  if (homeArmy == null || homeArmy.regimentUnitIds.length < 2) {
    return game;
  }

  final capital = homeArmy.stationedProvinceId;
  for (final a in game.worldState.armies) {
    if (a.ownerId == nationId &&
        !a.isHomeArmy &&
        a.stationedProvinceId == capital &&
        a.regimentUnitIds.isNotEmpty) {
      return game;
    }
  }

  final sortedRegs = [...homeArmy.regimentUnitIds]..sort();
  final maxToMove = sortedRegs.length - 1;
  final moveCount = (sortedRegs.length ~/ 2).clamp(1, maxToMove);
  final unitIds = sortedRegs.take(moveCount).toList();

  return applyArmySplit(
    game: game,
    playerId: nationId,
    sourceArmyId: homeId,
    unitIdsToMove: unitIds,
  );
}
