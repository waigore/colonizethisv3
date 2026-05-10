import 'dart:math' as math;

import 'package:colonizethis_ai/package_logger.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/ai_api.dart';
import 'package:colonizethis_logic/order_suggestion_api.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../goal_manager.dart';
import '../perception.dart';
import '../util/ai_random_utils.dart';
import '../util/orders_extensions.dart';
import 'war_desire_calculator.dart';

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

/// Pre-weighted-random scores for diplomatic order candidates (0 = suppressed).
/// Exposed for deterministic tests; [runDomainPlanners] uses the same values.
List<int> computeDiplomaticCandidateScores({
  required List<DiplomaticOrder> candidates,
  required String nationId,
  required Game game,
  required AIWorldSnapshot snapshot,
  required AIConfig config,
}) {
  final agendaId = config.hiddenAgendaId;
  final thresholds = getThresholdsForLeader(config.personalityId);
  final maxRelationForDeclareWar = getDeclareWarMaxRelationScore(agendaId);
  const warCooldownTurns = 4;
  const improveRelationsCooldownTurns = 2;
  final currentTurn = game.worldState.turnState.turnNumber;
  final warDesireByTarget = <String, int>{};
  int warDesireForTarget(String targetFactionId, int relationScore) {
    return warDesireByTarget.putIfAbsent(
      targetFactionId,
      () => computeWarDesireScore(
        game: game,
        nationId: nationId,
        targetFactionId: targetFactionId,
        relationScore: relationScore,
      ),
    );
  }
  return candidates.map((o) {
    var s = 50;
    switch (o.type) {
      case DiplomaticOrderType.offerPeace:
        {
          final rel = snapshot.relations[o.targetFactionId];
          final warDesire = warDesireForTarget(
            o.targetFactionId,
            rel?.score ?? 50,
          );
          // Lower peace desire when current war desire remains high.
          s -= (warDesire - 50);
        }
        s += getAgendaPeaceAcceptanceModifier(agendaId);
        s += (thresholds.peaceTendency - 50);
        break;
      case DiplomaticOrderType.alliance:
        s += getAgendaAllianceAcceptanceModifier(agendaId);
        s += (thresholds.allianceTendency - 50);
        break;
      case DiplomaticOrderType.declareWar:
        {
          final rel = snapshot.relations[o.targetFactionId];
          final relationScore = rel?.score ?? 50;
          if (relationScore > maxRelationForDeclareWar) {
            s = 0;
          } else {
            if (_isDecisionOnCooldown(
              game: game,
              actorFactionId: nationId,
              targetFactionId: o.targetFactionId,
              eventTypes: const [DiplomaticEventType.declareWar],
              cooldownTurns: warCooldownTurns,
              currentTurn: currentTurn,
            )) {
              s = 0;
              break;
            }
            final warDesire = warDesireForTarget(
              o.targetFactionId,
              relationScore,
            );
            final targetProvinceCount = provinceCountOwnedBy(
              game,
              o.targetFactionId,
            );
            final desiredTerritory = targetProvinceCount <= 0
                ? 1
                : ((warDesire / 25).round()).clamp(1, targetProvinceCount);
            s += getAgendaConquerModifier(agendaId);
            s += getAgendaTreatyBreakingModifier(agendaId);
            s += (thresholds.warLikelihood - 50);
            s += (warDesire - 50);
            if (snapshot.opportunities.weakNeighbors.contains(
              o.targetFactionId,
            )) {
              s += getDeclareWarTargetBonusWeakerNeighbor(agendaId);
            }
            if (rel?.level == RelationLevel.allied) {
              s += getDeclareWarTargetBonusAlly(agendaId);
            }
            _log.d(
              'diplomacy warDesire nationId=$nationId targetFactionId=${o.targetFactionId} '
              'warDesire=$warDesire desiredTerritory=$desiredTerritory',
            );
          }
          break;
        }
      case DiplomaticOrderType.establishOverture:
        {
          if (_isDecisionOnCooldown(
            game: game,
            actorFactionId: nationId,
            targetFactionId: o.targetFactionId,
            eventTypes: const [
              DiplomaticEventType.overtureAccepted,
              DiplomaticEventType.overtureRejected,
            ],
            cooldownTurns: improveRelationsCooldownTurns,
            currentTurn: currentTurn,
          )) {
            s = 0;
            break;
          }
          final rel = snapshot.relations[o.targetFactionId];
          final warDesire = warDesireForTarget(
            o.targetFactionId,
            rel?.score ?? 50,
          );
          final improveRelationsDesire = 100 - warDesire;
          s += (improveRelationsDesire - 50);
          break;
        }
      default:
        break;
    }
    return s == 0 ? 0 : math.max(1, s);
  }).toList();
}

bool _isDecisionOnCooldown({
  required Game game,
  required String actorFactionId,
  required String targetFactionId,
  required List<DiplomaticEventType> eventTypes,
  required int cooldownTurns,
  required int currentTurn,
}) {
  for (final event in game.diplomaticHistoryEvents.reversed) {
    if (!eventTypes.contains(event.type)) continue;
    if (event.fromFactionId != actorFactionId) continue;
    if (event.toFactionId != targetFactionId) continue;
    return (currentTurn - event.turn) < cooldownTurns;
  }
  return false;
}
