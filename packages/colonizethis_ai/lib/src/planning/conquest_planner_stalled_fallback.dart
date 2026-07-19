/// Stalled frontier army-move fallback helpers (Refs #4079 Slice C).
library;

import 'package:colonizethis_logic/order_suggestion_api.dart';

import 'conquest_move_scoring_context.dart';
import 'conquest_planner.dart' show selectFeedstockBiasedBestArmyMove;
import 'conquest_planner_destination_scoring.dart';
import 'planning_imports.dart';
import 'planner_context.dart';

final conquestPlannerLog = packageLogger();

Orders applyStalledArmyMovesForAllFieldArmies({
  required PlannerContext ctx,
  required ConquestMoveScoringContext scoringCtx,
  required List<ArmyMoveOrder> filtered,
  required String? feedstockConquestTarget,
}) {
  final armiesWithOrders = <String>{
    for (final m
        in ctx.orders.armyMoveOrdersByPlayerId[ctx.nationId] ?? const [])
      m.armyId,
  };
  final byArmy = <String, List<ArmyMoveOrder>>{};
  for (final move in filtered) {
    if (armiesWithOrders.contains(move.armyId)) continue;
    (byArmy[move.armyId] ??= []).add(move);
  }
  var result = ctx.orders;
  for (final armyId in byArmy.keys.toList()..sort()) {
    final candidates = byArmy[armyId]!;
    final best = selectFeedstockBiasedBestArmyMove(
      candidates: candidates,
      feedstockConquestTarget: feedstockConquestTarget,
      score: (move) => scoreArmyMoveDestination(scoringCtx, move),
    );
    if (best == null) continue;
    if (conquestPlannerLog.infoEnabled) {
      conquestPlannerLog.i(
        'conquest army move stalled multi nationId=${ctx.nationId} '
        'armyId=${best.armyId} destinationProvinceId=${best.destinationProvinceId}',
      );
    }
    result = applyArmyMoveOrderForPlayer(result, ctx.nationId, best);
    armiesWithOrders.add(best.armyId);
  }
  return result;
}

Orders runStalledFrontierArmyMoveFallback({
  required PlannerContext ctx,
  required ConquestMoveScoringContext scoringCtx,
  required String? feedstockConquestTarget,
}) {
  final playerOwnedFullProvinceIds = <String>{
    for (final e in ctx.view.provincesById.entries)
      if (e.value.ownerId == ctx.nationId) e.key,
  };
  final validator = IncrementalCandidateValidator.forPlayer(
    game: ctx.game,
    topology: ctx.topology,
    playerId: ctx.nationId,
    basePrefix: ctx.orders,
    factionMembership: DiplomacyFactionMembership.from(ctx.game),
    resolution: orderResolutionContextFromView(ctx.view, ctx.game),
  );
  final armiesWithOrders = <String>{
    for (final m
        in ctx.orders.armyMoveOrdersByPlayerId[ctx.nationId] ?? const [])
      m.armyId,
  };
  final acceptedCandidates = <ArmyMoveOrder>[];
  for (final army in ctx.game.worldState.armies) {
    if (army.ownerId != ctx.nationId || army.isHomeArmy) continue;
    if (armiesWithOrders.contains(army.id)) continue;
    final destIds = armyMoveCandidateDestinationProvinceIds(
      game: ctx.game,
      topology: ctx.topology,
      playerId: ctx.nationId,
      army: army,
      playerOwnedFullProvinceIds: playerOwnedFullProvinceIds,
    );
    for (final destinationProvinceId in destIds) {
      final candidate = ArmyMoveOrder(
        armyId: army.id,
        destinationProvinceId: destinationProvinceId,
      );
      if (!validator.isArmyMoveAccepted(candidate)) continue;
      acceptedCandidates.add(candidate);
    }
  }
  final best = selectFeedstockBiasedBestArmyMove(
    candidates: acceptedCandidates,
    feedstockConquestTarget: feedstockConquestTarget,
    score: (candidate) => scoreArmyMoveDestination(scoringCtx, candidate),
  );
  if (best == null) {
    return ctx.orders;
  }
  if (conquestPlannerLog.infoEnabled) {
    conquestPlannerLog.i(
      'conquest army move stalled fallback nationId=${ctx.nationId} '
      'armyId=${best.armyId} destinationProvinceId=${best.destinationProvinceId}',
    );
  }
  return applyArmyMoveOrderForPlayer(ctx.orders, ctx.nationId, best);
}
