import 'package:colonizethis_logic/order_suggestion_api.dart';

import 'candidate_selector.dart';
import 'goal_manager.dart';
import 'planner_context.dart';
import 'planning_imports.dart';
import '../util/orders_extensions.dart';

final _log = packageLogger();

Orders runMovePlanner({required PlannerContext ctx}) {
  final moveCandidates = ctx.suggestionAPI.suggestMoveOrders(
    ctx.view,
    ctx.game,
    ctx.topology,
    ctx.orders,
  );
  if (moveCandidates.isEmpty) return ctx.orders;
  final filtered = filterMoveOrdersByDiplomacy(
    ctx.game,
    ctx.nationId,
    moveCandidates,
  );
  if (filtered.isEmpty) return ctx.orders;
  final weight = ctx.resolveWeightForDomain();
  _log.d(
    'move eval nationId=${ctx.nationId} weight=$weight '
    'filteredCount=${filtered.length}',
  );
  if (weight < 20) {
    _log.d('move skipped nationId=${ctx.nationId} weight < 20');
    return ctx.orders;
  }
  final provinceOwner = ctx.provinceOwner;
  final selected = selectWeightedCandidate<MoveOrder>(
    candidates: filtered,
    scorer: (list) => list.map((m) {
      final destProv = Unit.provinceIdFromTileKey(m.destinationTileKey);
      final destOwner = destProv != null ? provinceOwner[destProv] : null;
      if (destOwner == null || destOwner == ctx.nationId) return 1.0;
      final rel = getRelation(ctx.game, ctx.nationId, destOwner);
      final atWar = rel != null && rel.atWar;
      return 1.0 + (atWar ? kMovePreferEnemyTerritoryBonus.toDouble() : 0);
    }).toList(),
    seed: ctx.seeds.militarySeed,
  );
  if (selected == null) return ctx.orders;
  _log.i(
    'move chosen nationId=${ctx.nationId} '
    'unitId=${selected.unitId} destinationTileKey=${selected.destinationTileKey}',
  );
  return ctx.orders.appendMoveOrders(ctx.nationId, [selected]);
}

Orders runArmyMovePlanner({
  required PlannerContext ctx,
  int provincesToVictory = 0,
}) {
  final armyMoveCandidates = ctx.suggestionAPI.suggestArmyMoveOrders(
    ctx.view,
    ctx.game,
    ctx.topology,
    ctx.orders,
  );
  if (armyMoveCandidates.isEmpty) {
    _log.d('army move eval nationId=${ctx.nationId} candidatesCount=0');
    return ctx.orders;
  }
  final filtered = filterArmyMoveOrdersByDiplomacy(
    ctx.game,
    ctx.nationId,
    armyMoveCandidates,
  );
  if (filtered.isEmpty) {
    _log.d('army move filtered empty nationId=${ctx.nationId}');
    return ctx.orders;
  }
  final weight = ctx.resolveWeightForDomain();
  final minWeight =
      ctx.primaryGoal == StrategicGoal.conquer || provincesToVictory > 10
      ? 10
      : 20;
  if (weight < minWeight) {
    _log.d(
      'army move skipped nationId=${ctx.nationId} weight=$weight < $minWeight',
    );
    return ctx.orders;
  }
  _log.d(
    'army move eval nationId=${ctx.nationId} weight=$weight '
    'filteredCount=${filtered.length}',
  );
  final provinceOwner = ctx.provinceOwner;
  final selected = selectWeightedCandidate<ArmyMoveOrder>(
    candidates: filtered,
    scorer: (list) => list.map((m) {
      final destOwner = provinceOwner[m.destinationProvinceId];
      if (destOwner == null || destOwner == ctx.nationId) return 1.0;
      final rel = getRelation(ctx.game, ctx.nationId, destOwner);
      final atWar = rel != null && rel.atWar;
      return 1.0 + (atWar ? kMovePreferEnemyTerritoryBonus.toDouble() : 0);
    }).toList(),
    seed: ctx.seeds.militarySeed + 2000,
  );
  if (selected == null) return ctx.orders;
  _log.i(
    'army move chosen nationId=${ctx.nationId} '
    'armyId=${selected.armyId} destinationProvinceId=${selected.destinationProvinceId}',
  );
  return applyArmyMoveOrderForPlayer(ctx.orders, ctx.nationId, selected);
}
