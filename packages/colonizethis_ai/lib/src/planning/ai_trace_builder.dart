import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/ai_api.dart' show TurnTraceAiSection;
import 'package:colonizethis_models/colonizethis_models.dart';

import 'goal_manager.dart';
import '../perception/perception_snapshot.dart';

TurnTraceAiSection buildAiTraceSection({
  required String nationId,
  required int turn,
  required AIConfig config,
  required AISeedBundle seeds,
  required AIWorldSnapshot snapshot,
  required StrategicGoal primaryGoal,
  required Map<StrategicGoal, int> goalScores,
  required EconomyPlan economyPlan,
  required Orders orders,
  required Map<String, Object?> ordersByDomain,
  required List<Map<String, Object?>> finalOrders,
  String? declaredWarTargetFactionId,
  int conquestArmyMoveCount = 0,
}) {
  final domainWeights = getDomainWeightsForLeader(config.personalityId);
  final goalWeights = getGoalWeightsForLeader(config.personalityId);
  final thresholds = getThresholdsForLeader(config.personalityId);
  final selectedScore = goalScores[primaryGoal] ?? 0;
  final agendaConquerModifier = getAgendaConquerModifier(config.hiddenAgendaId);
  final agendaDiplomacyModifier = getAgendaDiplomacyModifier(
    config.hiddenAgendaId,
  );
  return TurnTraceAiSection(
    factionId: nationId,
    state: <String, Object?>{
      'winningCandidate': <String, Object?>{
        'type': 'strategicGoal',
        'goal': primaryGoal.name,
        'score': selectedScore,
        'selectionMethod': 'weighted_random',
        'majorConstraint': majorConstraintForStrategicGoal(
          primaryGoal,
          snapshot,
          config,
        ),
      },
      'topAlternates': rankedGoalCandidates(goalScores, exclude: primaryGoal),
      'aggregates': <String, Object?>{
        'totalOrders': finalOrders.length,
        'ordersByDomain': ordersByDomain,
        'economyPlan': <String, Object?>{
          'productionAssignmentCount': economyPlan.productionAssignments.length,
          'cargoPreference': economyPlan.cargoPreference.name,
        },
        'snapshot': <String, Object?>{
          'atWarWith': snapshot.threats.atWarWith,
          'neighborProvincesHostile': snapshot.threats.neighborProvincesHostile,
          'capitalThreatened': snapshot.threats.capitalThreatened,
          'weakNeighbors': snapshot.opportunities.weakNeighbors,
          'richUnexploitedProvinces':
              snapshot.opportunities.richUnexploitedProvinces,
          'unclaimedProvinces': snapshot.opportunities.unclaimedProvinces,
          'workerCount': snapshot.economy.workerCount,
          'treasury': snapshot.economy.treasury,
          'ownProvinceCount': snapshot.economy.ownProvinceCount,
          'provincesToVictory': snapshot.conquest.provincesToVictory,
          'invadableCount':
              snapshot.conquest.invadableProvinceIdsSorted.length,
          'declaredWarTarget': declaredWarTargetFactionId,
          'conquestArmyMoveCount': conquestArmyMoveCount,
        },
      },
      'decisionContext': <String, Object?>{
        'turnNumber': turn,
        'leaderId': config.leaderId,
        'personalityId': config.personalityId,
        'hiddenAgendaId': config.hiddenAgendaId,
      },
    },
    thresholds: <String, Object?>{
      'constants': <String, Object?>{
        'seeds': <String, Object?>{
          'perception': seeds.perceptionSeed,
          'goal': seeds.goalSeed,
          'economy': seeds.economySeed,
          'military': seeds.militarySeed,
          'diplomacy': seeds.diplomacySeed,
          'research': seeds.researchSeed,
          'tactical': seeds.tacticalSeed,
          'dialogue': seeds.dialogueSeed,
          'agenda': seeds.agendaSeed,
        },
        'goalWeights': <String, Object?>{
          'defend': goalWeights.defend,
          'expand': goalWeights.expand,
          'conquer': goalWeights.conquer,
          'trade': goalWeights.trade,
          'tech': goalWeights.tech,
          'diplomacy': goalWeights.diplomacy,
        },
        'agendaModifiers': <String, Object?>{
          'conquer': agendaConquerModifier,
          'diplomacy': agendaDiplomacyModifier,
        },
      },
      'derived': <String, Object?>{
        'goalCandidateScores': goalScoresJson(goalScores),
        'domainWeights': <String, Object?>{
          'economy': domainWeights.economy,
          'military': domainWeights.military,
          'diplomacy': domainWeights.diplomacy,
          'research': domainWeights.research,
        },
      },
      'effective': <String, Object?>{
        'selectedGoal': primaryGoal.name,
        'selectedGoalScore': selectedScore,
        'adjustedGoalScores': goalScoresJson(goalScores),
        'personalityThresholds': <String, Object?>{
          'warLikelihood': thresholds.warLikelihood,
          'peaceTendency': thresholds.peaceTendency,
          'allianceTendency': thresholds.allianceTendency,
          'researchNaval': thresholds.researchNaval,
          'researchMilitary': thresholds.researchMilitary,
          'researchEconomic': thresholds.researchEconomic,
          'researchExploration': thresholds.researchExploration,
        },
      },
      'gates': <Object?>[...goalSelectionGates(goalScores, primaryGoal)],
    },
    outcome: <String, Object?>{
      'domainOutputs': <String, Object?>{
        ...ordersByDomain,
        'conquestArmyMove': conquestArmyMoveCount,
      },
      'finalAggregatedOrders': finalOrders,
      'emittedOrderCount': finalOrders.length,
    },
  );
}

List<Map<String, Object?>> goalSelectionGates(
  Map<StrategicGoal, int> goalScores,
  StrategicGoal selectedGoal,
) {
  final entries = goalScores.entries.toList(growable: false)
    ..sort((a, b) => b.value.compareTo(a.value));
  return entries
      .map(
        (entry) => <String, Object?>{
          'gate': 'strategic_goal_selection',
          'method': 'weighted_random',
          'candidateGoal': entry.key.name,
          'candidateScore': entry.value,
          'selected': entry.key == selectedGoal,
        },
      )
      .toList(growable: false);
}

Map<String, Object?> goalScoresJson(Map<StrategicGoal, int> goalScores) {
  return <String, Object?>{
    for (final entry in goalScores.entries) entry.key.name: entry.value,
  };
}

List<Map<String, Object?>> rankedGoalCandidates(
  Map<StrategicGoal, int> goalScores, {
  required StrategicGoal exclude,
}) {
  final entries =
      goalScores.entries
          .where((entry) => entry.key != exclude)
          .toList(growable: false)
        ..sort((a, b) => b.value.compareTo(a.value));
  return entries
      .take(3)
      .map(
        (entry) => <String, Object?>{
          'type': 'strategicGoal',
          'goal': entry.key.name,
          'score': entry.value,
        },
      )
      .toList(growable: false);
}
