import 'goal_manager.dart';
import 'planning_imports.dart';
import '../perception/perception_snapshot.dart';
import 'colonial_pressure.dart';
import 'planner_context.dart';
import '../util/ai_random_utils.dart';

final _log = packageLogger();

/// Invasion army moves after same-turn declare war. SPEC/ai/ai-architecture.md.
Orders runConquestArmyMovePlanner({
  required PlannerContext ctx,
  required AIWorldSnapshot snapshot,
  String? declaredWarTargetFactionId,
}) {
  final armyMoveCandidates = ctx.suggestionAPI.suggestArmyMoveOrders(
    ctx.view,
    ctx.game,
    ctx.topology,
    ctx.orders,
  );
  if (armyMoveCandidates.isEmpty) {
    _log.d('conquest army move nationId=${ctx.nationId} candidatesCount=0');
    return ctx.orders;
  }
  final filtered = filterArmyMoveOrdersByDiplomacy(
    ctx.game,
    ctx.nationId,
    armyMoveCandidates,
    draftOrders: ctx.orders,
  );
  if (filtered.isEmpty) {
    _log.d('conquest army move filtered empty nationId=${ctx.nationId}');
    return ctx.orders;
  }
  var weight = ctx.resolveMilitaryEconomyWeight();
  final provincesToVictory = snapshot.conquest.provincesToVictory;
  if (ctx.primaryGoal == StrategicGoal.conquer || provincesToVictory > 10) {
    weight = weight < 10 ? 10 : weight;
  }
  if (provincesToVictory > kConquerScoreFloorProvincesToVictoryThreshold &&
      weight < 10) {
    weight = 10;
  }
  final stalledExpansion = snapshot.conquest.oldWorldProvincesOwned <=
      kStalledOldWorldProvinceThreshold;
  final atWarWithInvadableTarget = snapshot.conquest.invadableProvinceIdsSorted
      .isNotEmpty &&
      snapshot.threats.atWarWith.isNotEmpty;
  if (stalledExpansion &&
      snapshot.conquest.invadableProvinceIdsSorted.isNotEmpty &&
      weight < 90) {
    weight = 90;
  } else if (stalledExpansion && atWarWithInvadableTarget && weight < 80) {
    weight = 80;
  }
  if (hasColonialAcquisitionTargets(snapshot.colonial) &&
      weight < kConquestArmyMoveMinWeightWhenColonialPressure) {
    weight = kConquestArmyMoveMinWeightWhenColonialPressure;
  }
  if (weight < 10) {
    _log.d('conquest army move skipped nationId=${ctx.nationId} weight=$weight');
    return ctx.orders;
  }
  final invadable = {
    ...snapshot.conquest.invadableProvinceIdsSorted,
    ...snapshot.colonial.invadableNewWorldProvinceIdsSorted,
  };
  final selected = selectWeightedCandidate(
    candidates: filtered,
    seed: ctx.seeds.militarySeed + 4000,
    score: (m) {
      final destOwner = ctx.provinceOwner[m.destinationProvinceId] ?? '';
      var score = 1.0;
      if (declaredWarTargetFactionId != null &&
          destOwner == declaredWarTargetFactionId) {
        score += 50;
      } else {
        final rel = getRelation(ctx.game, ctx.nationId, destOwner);
        if (rel != null && rel.atWar) {
          score += kMovePreferEnemyTerritoryBonus.toDouble();
        }
      }
      if (invadable.contains(m.destinationProvinceId)) {
        score += 10;
      }
      if (snapshot.colonial.invadableNewWorldProvinceIdsSorted
          .contains(m.destinationProvinceId)) {
        score += kConquestArmyMoveNwInvadableBonus;
      }
      if (snapshot.conquest.adjacentOwnerFactionIdsSorted.contains(destOwner)) {
        score += 8;
      }
      return score;
    },
  );
  if (selected == null) return ctx.orders;
  _log.i(
    'conquest army move chosen nationId=${ctx.nationId} '
    'armyId=${selected.armyId} destinationProvinceId=${selected.destinationProvinceId} '
    'declaredWarTarget=$declaredWarTargetFactionId',
  );
  return applyArmyMoveOrderForPlayer(ctx.orders, ctx.nationId, selected);
}
