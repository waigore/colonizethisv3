import 'candidate_selector.dart';
import 'colonial_pressure.dart';
import 'diplomatic_candidate_scoring.dart';
import 'diplomacy_planner_result.dart';
import 'planner_context.dart';
import 'planning_imports.dart';
import '../util/orders_extensions.dart';

export 'diplomatic_candidate_scoring.dart' show computeDiplomaticCandidateScores;
export 'war_desire_calculator.dart' show computeWarDesireScore;
export 'diplomacy_planner_result.dart'
    show DiplomacyPlannerPass, DiplomacyPlannerResult;

final _log = packageLogger();

Orders runDiplomacyPlanner({required PlannerContext ctx}) =>
    runDiplomacyPlannerWithResult(ctx: ctx).orders;

DiplomacyPlannerResult runDiplomacyPlannerWithResult({
  required PlannerContext ctx,
  DiplomacyPlannerPass pass = DiplomacyPlannerPass.all,
}) {
  final snapshot = ctx.snapshot;
  if (snapshot == null) {
    return DiplomacyPlannerResult(orders: ctx.orders);
  }
  var weight = ctx.resolveWeightForDomain(
    kind: DomainWeightKind.diplomacyOrBase,
    base: 40,
  );
  if (pass == DiplomacyPlannerPass.declareWarOnly &&
      snapshot.conquest.provincesToVictory >
          kConquerScoreFloorProvincesToVictoryThreshold &&
      weight < 25) {
    weight = 25;
  }
  if (pass == DiplomacyPlannerPass.declareWarOnly &&
      snapshot.conquest.oldWorldProvincesOwned <=
          kStalledOldWorldProvinceThreshold &&
      weight < kDiplomacyDeclareWarMinWeightWhenStalled) {
    weight = kDiplomacyDeclareWarMinWeightWhenStalled;
  }
  if (pass == DiplomacyPlannerPass.declareWarOnly &&
      hasColonialAcquisitionTargets(snapshot.colonial) &&
      weight < kDiplomacyDeclareWarMinWeightWhenColonialPressure) {
    weight = kDiplomacyDeclareWarMinWeightWhenColonialPressure;
  }
  if (weight < 25) {
    _log.d('diplomacy skipped nationId=${ctx.nationId} weight=$weight < 25');
    return DiplomacyPlannerResult(orders: ctx.orders);
  }

  var diploCandidates = pass == DiplomacyPlannerPass.declareWarOnly
      ? ctx.suggestionAPI.suggestDeclareWarOrders(
          ctx.view,
          ctx.game,
          ctx.topology,
          ctx.orders,
        )
      : ctx.suggestionAPI.suggestDiplomaticOrders(
          ctx.view,
          ctx.game,
          ctx.topology,
          ctx.orders,
        );
  if (diploCandidates.isEmpty) {
    return DiplomacyPlannerResult(orders: ctx.orders);
  }

  final declaredThisTurn = <String>{
    for (final o in ctx.orders.diplomaticOrdersByPlayerId[ctx.nationId] ??
        const [])
      if (o.type == DiplomaticOrderType.declareWar) o.targetFactionId,
  };

  switch (pass) {
    case DiplomacyPlannerPass.declareWarOnly:
      break;
    case DiplomacyPlannerPass.nonDeclareWarOnly:
      diploCandidates = diploCandidates
          .where(
            (o) =>
                o.type != DiplomaticOrderType.declareWar &&
                !declaredThisTurn.contains(o.targetFactionId),
          )
          .toList();
      break;
    case DiplomacyPlannerPass.all:
      break;
  }
  if (diploCandidates.isEmpty) {
    return DiplomacyPlannerResult(orders: ctx.orders);
  }

  final scores = computeDiplomaticCandidateScores(
    candidates: diploCandidates,
    nationId: ctx.nationId,
    game: ctx.game,
    snapshot: snapshot,
    config: ctx.config,
    primaryGoal: ctx.primaryGoal,
  );

  final candidateDesc = diploCandidates
      .map(
        (o) =>
            '${o.type.name}${o.type == DiplomaticOrderType.declareWar ? ":${o.targetFactionId}" : ""}',
      )
      .toList();
  _log.d(
    'diplomacy eval nationId=${ctx.nationId} hiddenAgendaId=${ctx.config.hiddenAgendaId} '
    'candidates=$candidateDesc scores=$scores',
  );

  final chosen = selectWeightedCandidate<DiplomaticOrder>(
    candidates: diploCandidates,
    scorer: (_) => scores,
    seed: ctx.seeds.diplomacySeed,
  );
  if (chosen == null) return DiplomacyPlannerResult(orders: ctx.orders);
  _log.i(
    'diplomacy chosen nationId=${ctx.nationId} '
    'type=${chosen.type}${chosen.type == DiplomaticOrderType.declareWar ? " targetFactionId=${chosen.targetFactionId}" : ""}',
  );
  final nextOrders = ctx.orders.appendDiplomaticOrders(ctx.nationId, [chosen]);
  final declaredTarget = chosen.type == DiplomaticOrderType.declareWar
      ? chosen.targetFactionId
      : null;
  return DiplomacyPlannerResult(
    orders: nextOrders,
    declaredWarTargetFactionId: declaredTarget,
  );
}
