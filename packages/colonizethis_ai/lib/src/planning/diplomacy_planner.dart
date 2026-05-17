import '../perception/perception_snapshot.dart';
import 'planning_imports.dart';
import 'colonial_pressure.dart';
import 'planner_context.dart';
import '../util/ai_random_utils.dart';
import '../util/orders_extensions.dart';
import 'diplomatic_candidate_scoring.dart';
import 'diplomacy_planner_result.dart';

export 'diplomatic_candidate_scoring.dart' show computeDiplomaticCandidateScores;
export 'war_desire_calculator.dart' show computeWarDesireScore;
export 'diplomacy_planner_result.dart'
    show DiplomacyPlannerPass, DiplomacyPlannerResult;

final _log = packageLogger();

/// Strongest at-war GP that owns invadable OW provinces while this GP is stalled.
String? stalledStrongerGpBlockerPeaceTarget({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  if (!isStalledOldWorldExpansion(snapshot.conquest.oldWorldProvincesOwned)) {
    return null;
  }
  final provinceOwner = getProvinceOwnerMap(game);
  String? bestFactionId;
  var bestLead = 0;
  for (final factionId in snapshot.threats.atWarWith) {
    if (game.playerById(factionId) == null) continue;
    final ownsInvadable = snapshot.conquest.invadableProvinceIdsSorted.any(
      (pid) => provinceOwner[pid] == factionId,
    );
    if (!ownsInvadable) continue;
    final lead = provinceCountOwnedBy(game, factionId) -
        snapshot.conquest.oldWorldProvincesOwned;
    if (lead <= 0) continue;
    if (lead > bestLead) {
      bestLead = lead;
      bestFactionId = factionId;
    }
  }
  return bestFactionId;
}

Orders runDiplomacyPlanner({
  required PlannerContext ctx,
  required AIWorldSnapshot snapshot,
}) =>
    runDiplomacyPlannerWithResult(ctx: ctx, snapshot: snapshot).orders;

DiplomacyPlannerResult runDiplomacyPlannerWithResult({
  required PlannerContext ctx,
  required AIWorldSnapshot snapshot,
  DiplomacyPlannerPass pass = DiplomacyPlannerPass.all,
}) {
  var weight = ctx.resolveDiplomacyBaseWeight();
  if (pass == DiplomacyPlannerPass.declareWarOnly &&
      snapshot.conquest.provincesToVictory >
          kConquerScoreFloorProvincesToVictoryThreshold &&
      weight < 25) {
    weight = 25;
  }
  if (pass == DiplomacyPlannerPass.declareWarOnly &&
      isStalledOldWorldExpansion(snapshot.conquest.oldWorldProvincesOwned) &&
      weight < kDiplomacyDeclareWarMinWeightWhenStalled) {
    weight = kDiplomacyDeclareWarMinWeightWhenStalled;
  }
  if (pass == DiplomacyPlannerPass.declareWarOnly &&
      snapshot.conquest.oldWorldProvincesOwned <=
          kStalledOldWorldProvinceThreshold &&
      snapshot.conquest.invadableProvinceIdsSorted.isNotEmpty &&
      weight < kDiplomacyDeclareWarMinWeightWhenStalled + 15) {
    weight = kDiplomacyDeclareWarMinWeightWhenStalled + 15;
  }
  if (pass == DiplomacyPlannerPass.declareWarOnly &&
      hasColonialAcquisitionTargets(snapshot.colonial) &&
      weight < kDiplomacyDeclareWarMinWeightWhenColonialPressure) {
    weight = kDiplomacyDeclareWarMinWeightWhenColonialPressure;
  }
  if (pass != DiplomacyPlannerPass.declareWarOnly &&
      stalledStrongerGpBlockerPeaceTarget(game: ctx.game, snapshot: snapshot) !=
          null &&
      weight < 25) {
    weight = 25;
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
    for (final o
        in ctx.orders.diplomaticOrdersByPlayerId[ctx.nationId] ?? const [])
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

  if (pass != DiplomacyPlannerPass.declareWarOnly) {
    final peaceTarget = stalledStrongerGpBlockerPeaceTarget(
      game: ctx.game,
      snapshot: snapshot,
    );
    if (peaceTarget != null) {
      final peaceIdx = diploCandidates.indexWhere(
        (o) =>
            o.type == DiplomaticOrderType.offerPeace &&
            o.targetFactionId == peaceTarget,
      );
      if (peaceIdx >= 0) {
        final peace = diploCandidates[peaceIdx];
        _log.i(
          'diplomacy forced offerPeace nationId=${ctx.nationId} '
          'targetFactionId=$peaceTarget',
        );
        return DiplomacyPlannerResult(
          orders: ctx.orders.appendDiplomaticOrders(ctx.nationId, [peace]),
        );
      }
    }
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

  final DiplomaticOrder? chosen;
  if (pass == DiplomacyPlannerPass.declareWarOnly &&
      isStalledOldWorldExpansion(snapshot.conquest.oldWorldProvincesOwned) &&
      snapshot.conquest.provincesToVictory >
          kConquerScoreFloorProvincesToVictoryThreshold) {
    final idx = _pickHighestScoreIndex(scores);
    chosen = idx == null ? null : diploCandidates[idx];
  } else {
    chosen = selectWeightedCandidate(
      candidates: diploCandidates,
      scores: scores,
      seed: ctx.seeds.diplomacySeed,
    );
  }
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

/// Deterministic tie-break: lowest candidate index wins equal scores.
int? _pickHighestScoreIndex(List<int> scores) {
  var bestIdx = -1;
  var bestScore = 0;
  for (var i = 0; i < scores.length; i++) {
    final score = scores[i];
    if (score <= 0) continue;
    if (score > bestScore || bestIdx < 0) {
      bestScore = score;
      bestIdx = i;
    }
  }
  return bestIdx < 0 ? null : bestIdx;
}
