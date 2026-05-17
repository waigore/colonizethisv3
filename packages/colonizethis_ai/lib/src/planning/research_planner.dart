import 'dart:math' as math;

import 'package:colonizethis_ai/package_logger.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/ai_api.dart';
import 'package:colonizethis_logic/order_suggestion_api.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'goal_manager.dart';
import '../util/ai_random_utils.dart';
import '../util/orders_extensions.dart';

final _log = packageLogger();

Orders runResearchPlanner({
  required String nationId,
  required PlayerView view,
  required Game game,
  required MapTopology topology,
  required Orders orders,
  required AIConfig config,
  required StrategicGoal primaryGoal,
  required OrderSuggestionAPI suggestionAPI,
  required int researchSeed,
}) {
  final domainWeights = getDomainWeightsForLeader(config.personalityId);
  final researchCandidates = suggestionAPI.suggestResearchOrders(
    view,
    game,
    topology,
    orders,
  );
  final researchThreshold =
      40 - getAgendaResearchModifier(config.hiddenAgendaId);
  if (researchCandidates.isEmpty ||
      (primaryGoal != StrategicGoal.tech &&
          domainWeights.research < researchThreshold)) {
    if (researchCandidates.isNotEmpty) {
      _log.d(
        'research skipped nationId=$nationId threshold not met or no candidates',
      );
    }
    return orders;
  }

  final thresholds = getThresholdsForLeader(config.personalityId);
  final scores = researchCandidates.map((o) {
    final tech = techById(o.techId);
    final category = tech?.category ?? '';
    final w = category == 'transport'
        ? thresholds.researchNaval
        : category == 'military'
        ? thresholds.researchMilitary
        : category == 'gathering'
        ? thresholds.researchEconomic
        : thresholds.researchExploration;
    return math.max(1, w);
  }).toList();
  _log.d(
    'research eval nationId=$nationId researchThreshold=$researchThreshold '
    'candidateCount=${researchCandidates.length} scores=$scores',
  );
  final idx = pickWeightedIndex(scores, researchSeed, useIntRoll: true);
  if (idx == null) return orders;

  final chosen = researchCandidates[idx];
  _log.i(
    'research chosen nationId=$nationId techId=${chosen.techId} score=${scores[idx]}',
  );
  return orders.appendResearchOrders(nationId, [chosen]);
}
