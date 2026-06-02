import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/ai_api.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'goal_manager.dart';

/// Total regiment slots across Home and field armies for [playerId].
int regimentCountForPlayer(Game game, String playerId) {
  var count = 0;
  for (final army in game.worldState.armies) {
    if (army.ownerId == playerId) {
      count += army.regimentUnitIds.length;
    }
  }
  return count;
}

Army? _homeArmyForPlayer(Game game, String nationId) {
  final homeId = homeArmyIdFor(nationId);
  for (final a in game.worldState.armies) {
    if (a.id == homeId && a.ownerId == nationId) return a;
  }
  return null;
}

/// Splits regiments from the Home Army into a field army at the capital when
/// the AI is pursuing conquest and all regiments are stuck in the Home Army
/// (which cannot march). SPEC/game/military-armies.md;
/// SPEC/ai/phase-planner-architecture.md § AI conquest-prep auto-split.
///
/// Mutates [game] in place via [applyArmySplit] so subsequent suggestion and
/// validation see the field army id.
///
/// Under stalled Old World expansion (`isStalledOldWorldExpansion`), the
/// sole-regiment Home Army is also split — the single regiment moves into a
/// new field army at the capital and the Home Army is left with zero
/// regiments (SPEC-permitted: Home Army is never deleted when empty).
/// Refs #2925.
Game prepareConquestFieldArmy({
  required Game game,
  required String nationId,
  required int provincesToVictory,
  required int oldWorldProvincesOwned,
  required StrategicGoal primaryGoal,
}) {
  final stalled = isStalledOldWorldExpansion(oldWorldProvincesOwned);
  final shouldPrep = primaryGoal == StrategicGoal.conquer ||
      provincesToVictory > kBuildRegimentVictoryPaceThreshold ||
      stalled;
  if (!shouldPrep) return game;

  final homeArmy = _homeArmyForPlayer(game, nationId);
  if (homeArmy == null || homeArmy.regimentUnitIds.isEmpty) {
    return game;
  }
  if (!stalled && homeArmy.regimentUnitIds.length < 2) {
    return game;
  }

  final capital = homeArmy.stationedProvinceId;
  var fieldArmiesAtCapital = 0;
  for (final a in game.worldState.armies) {
    if (a.ownerId == nationId &&
        !a.isHomeArmy &&
        a.stationedProvinceId == capital &&
        a.regimentUnitIds.isNotEmpty) {
      fieldArmiesAtCapital++;
    }
  }
  if (!stalled && fieldArmiesAtCapital > 0) {
    return game;
  }

  if (stalled) {
    // Sole-regiment case (Refs #2925): peel the single regiment out of the
    // Home Army into a new non-Home field army at the capital so subsequent
    // army-move suggestions (which always skip `isHomeArmy`) can issue moves
    // from the new id. The Home Army is left with zero regiments
    // (SPEC-permitted: never deleted when empty). This is a one-shot split;
    // the multi-split loop below is for the `>= 2` distribution path.
    if (homeArmy.regimentUnitIds.length == 1) {
      return applyArmySplit(
        game: game,
        playerId: nationId,
        sourceArmyId: homeArmy.id,
        unitIdsToMove: [...homeArmy.regimentUnitIds],
      );
    }
    var planningGame = game;
    for (var i = fieldArmiesAtCapital;
        i < kStalledConquestFieldArmySplitCap;
        i++) {
      final currentHome = _homeArmyForPlayer(planningGame, nationId);
      if (currentHome == null || currentHome.regimentUnitIds.length < 2) {
        break;
      }
      final sortedRegs = [...currentHome.regimentUnitIds]..sort();
      final maxToMove = sortedRegs.length - 1;
      final moveCount = (sortedRegs.length ~/ 2).clamp(1, maxToMove);
      planningGame = applyArmySplit(
        game: planningGame,
        playerId: nationId,
        sourceArmyId: currentHome.id,
        unitIdsToMove: sortedRegs.take(moveCount).toList(),
      );
    }
    return planningGame;
  }

  final sortedRegs = [...homeArmy.regimentUnitIds]..sort();
  final maxToMove = sortedRegs.length - 1;
  final moveCount = (sortedRegs.length ~/ 2).clamp(1, maxToMove);
  final unitIds = sortedRegs.take(moveCount).toList();

  return applyArmySplit(
    game: game,
    playerId: nationId,
    sourceArmyId: homeArmy.id,
    unitIdsToMove: unitIds,
  );
}
