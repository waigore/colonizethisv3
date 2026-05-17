import 'package:colonizethis_ai/package_logger.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/ai_api.dart';
import 'package:colonizethis_logic/order_suggestion_api.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'goal_manager.dart';
import '../perception/perception_snapshot.dart';
import '../util/ai_random_utils.dart';
import '../util/orders_extensions.dart';
import 'diplomatic_candidate_scoring.dart';
import 'diplomacy_planner_result.dart';

export 'diplomatic_candidate_scoring.dart' show computeDiplomaticCandidateScores;
export 'war_desire_calculator.dart' show computeWarDesireScore;
export 'diplomacy_planner_result.dart'
    show DiplomacyPlannerPass, DiplomacyPlannerResult;

final _log = packageLogger();

Orders runDiplomacyPlanner({
  required String nationId,
  required PlayerView view,
  required Game game,
  required MapTopology topology,
  required Orders orders,
  required AIWorldSnapshot snapshot,
  required AIConfig config,
  required StrategicGoal primaryGoal,
  required AISeedBundle seeds,
  required OrderSuggestionAPI suggestionAPI,
}) =>
    runDiplomacyPlannerWithResult(
      nationId: nationId,
      view: view,
      game: game,
      topology: topology,
      orders: orders,
      snapshot: snapshot,
      config: config,
      primaryGoal: primaryGoal,
      seeds: seeds,
      suggestionAPI: suggestionAPI,
    ).orders;

DiplomacyPlannerResult runDiplomacyPlannerWithResult({
  required String nationId,
  required PlayerView view,
  required Game game,
  required MapTopology topology,
  required Orders orders,
  required AIWorldSnapshot snapshot,
  required AIConfig config,
  required StrategicGoal primaryGoal,
  required AISeedBundle seeds,
  required OrderSuggestionAPI suggestionAPI,
  DiplomacyPlannerPass pass = DiplomacyPlannerPass.all,
}) {
  final domainWeights = getDomainWeightsForLeader(config.personalityId);
  var weight =
      primaryGoal == StrategicGoal.diplomacy ||
          primaryGoal == StrategicGoal.conquer ||
          primaryGoal == StrategicGoal.trade
      ? domainWeights.diplomacy
      : 40;
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
  if (weight < 25) {
    _log.d('diplomacy skipped nationId=$nationId weight=$weight < 25');
    return DiplomacyPlannerResult(orders: orders);
  }

  var diploCandidates = pass == DiplomacyPlannerPass.declareWarOnly
      ? suggestionAPI.suggestDeclareWarOrders(
          view,
          game,
          topology,
          orders,
        )
      : suggestionAPI.suggestDiplomaticOrders(
          view,
          game,
          topology,
          orders,
        );
  if (diploCandidates.isEmpty) {
    return DiplomacyPlannerResult(orders: orders);
  }

  final declaredThisTurn = <String>{
    for (final o in orders.diplomaticOrdersByPlayerId[nationId] ?? const [])
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
    return DiplomacyPlannerResult(orders: orders);
  }

  final scores = computeDiplomaticCandidateScores(
    candidates: diploCandidates,
    nationId: nationId,
    game: game,
    snapshot: snapshot,
    config: config,
    primaryGoal: primaryGoal,
  );

  final candidateDesc = diploCandidates
      .map(
        (o) =>
            '${o.type.name}${o.type == DiplomaticOrderType.declareWar ? ":${o.targetFactionId}" : ""}',
      )
      .toList();
  _log.d(
    'diplomacy eval nationId=$nationId hiddenAgendaId=${config.hiddenAgendaId} '
    'candidates=$candidateDesc scores=$scores',
  );

  final idx = pickWeightedIndex(scores, seeds.diplomacySeed);
  if (idx == null) return DiplomacyPlannerResult(orders: orders);
  final chosen = diploCandidates[idx];
  _log.i(
    'diplomacy chosen nationId=$nationId '
    'type=${chosen.type}${chosen.type == DiplomaticOrderType.declareWar ? " targetFactionId=${chosen.targetFactionId}" : ""} score=${scores[idx]}',
  );
  final nextOrders = orders.appendDiplomaticOrders(nationId, [chosen]);
  final declaredTarget = chosen.type == DiplomaticOrderType.declareWar
      ? chosen.targetFactionId
      : null;
  return DiplomacyPlannerResult(
    orders: nextOrders,
    declaredWarTargetFactionId: declaredTarget,
  );
}
