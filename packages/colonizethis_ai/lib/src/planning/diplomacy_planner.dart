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

export 'diplomatic_candidate_scoring.dart' show computeDiplomaticCandidateScores;
export 'war_desire_calculator.dart' show computeWarDesireScore;

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
}) {
  final domainWeights = getDomainWeightsForLeader(config.personalityId);
  final weight =
      primaryGoal == StrategicGoal.diplomacy ||
          primaryGoal == StrategicGoal.conquer ||
          primaryGoal == StrategicGoal.trade
      ? domainWeights.diplomacy
      : 40;
  if (weight < 25) {
    _log.d('diplomacy skipped nationId=$nationId weight=$weight < 25');
    return orders;
  }

  final diploCandidates = suggestionAPI.suggestDiplomaticOrders(
    view,
    game,
    topology,
    orders,
  );
  if (diploCandidates.isEmpty) return orders;

  final scores = computeDiplomaticCandidateScores(
    candidates: diploCandidates,
    nationId: nationId,
    game: game,
    snapshot: snapshot,
    config: config,
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
  if (idx == null) return orders;
  final chosen = diploCandidates[idx];
  _log.i(
    'diplomacy chosen nationId=$nationId '
    'type=${chosen.type}${chosen.type == DiplomaticOrderType.declareWar ? " targetFactionId=${chosen.targetFactionId}" : ""} score=${scores[idx]}',
  );
  return orders.appendDiplomaticOrders(nationId, [chosen]);
}
