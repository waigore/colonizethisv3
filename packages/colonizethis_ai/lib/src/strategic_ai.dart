import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_ai/package_logger.dart';
import 'package:colonizethis_logic/ai_api.dart'
    show PlayerView, TurnTraceAiSection;
import 'package:colonizethis_logic/order_suggestion_api.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'domain_planners.dart';
import 'economy_planner.dart';
import 'goal_manager.dart';
import 'mood_state_machine.dart';
import 'perception.dart';

final _log = packageLogger();

/// Strategic order generation for full AI. SPEC/program/ai-systems-impl.md.
///
/// Returns valid [Orders] and [EconomyPlan] for [nationId] for the current turn
/// using [view] as the only source of visibility. Optionally emits dialogue and mood via callbacks.
StrategicOrderResult generateStrategicOrders({
  required Game game,
  required MapTopology topology,
  required String nationId,
  required PlayerView view,
  required AIConfig config,
  required AISeedBundle seeds,
  required OrderSuggestionAPI suggestionAPI,
  Map<String, TileMapResult>? tileMapByRegion,
  void Function(DialogueEvent)? onDialogue,
  void Function(PortraitMoodEvent)? onMood,
}) {
  return generateStrategicOrdersWithTrace(
    game: game,
    topology: topology,
    nationId: nationId,
    view: view,
    config: config,
    seeds: seeds,
    suggestionAPI: suggestionAPI,
    tileMapByRegion: tileMapByRegion,
    onDialogue: onDialogue,
    onMood: onMood,
  ).result;
}

class StrategicOrderTraceResult {
  const StrategicOrderTraceResult({
    required this.result,
    required this.aiTraceSection,
  });

  final StrategicOrderResult result;
  final TurnTraceAiSection aiTraceSection;
}

StrategicOrderTraceResult generateStrategicOrdersWithTrace({
  required Game game,
  required MapTopology topology,
  required String nationId,
  required PlayerView view,
  required AIConfig config,
  required AISeedBundle seeds,
  required OrderSuggestionAPI suggestionAPI,
  Map<String, TileMapResult>? tileMapByRegion,
  void Function(DialogueEvent)? onDialogue,
  void Function(PortraitMoodEvent)? onMood,
  void Function(String phaseId)? onStagedPlannerProgress,
}) {
  final turn = game.worldState.turnState.turnNumber;
  _log.i('generateStrategicOrders nationId=$nationId turn=$turn');
  final snapshot = AIWorldSnapshot.fromPlayerView(view, topology: topology);
  final goalScores = evaluateStrategicGoalScores(snapshot, config);
  final primaryGoal = selectPrimaryGoal(
    snapshot,
    config,
    seeds.goalSeed,
    nationId: nationId,
    turn: turn,
  );
  _log.d('primaryGoal=$primaryGoal');
  final economyPlan = runEconomyPlanner(
    game: game,
    view: view,
    config: config,
    seeds: seeds,
  );
  final orders = runDomainPlanners(
    game: game,
    topology: topology,
    nationId: nationId,
    view: view,
    snapshot: snapshot,
    config: config,
    primaryGoal: primaryGoal,
    seeds: seeds,
    suggestionAPI: suggestionAPI,
    economyPlan: economyPlan,
    tileMapByRegion: tileMapByRegion,
    onStagedPlannerProgress: onStagedPlannerProgress,
  );
  final moveCount = orders.moveOrdersByPlayerId[nationId]?.length ?? 0;
  final armyMoveCount = orders.armyMoveOrdersByPlayerId[nationId]?.length ?? 0;
  final buildCount = orders.buildUnitOrdersByPlayerId[nationId]?.length ?? 0;
  final workCount = orders.workOrdersByPlayerId[nationId]?.length ?? 0;
  final researchCount = orders.researchOrdersByPlayerId[nationId]?.length ?? 0;
  _log.i(
    'generated orders nationId=$nationId move=$moveCount armyMove=$armyMoveCount build=$buildCount work=$workCount research=$researchCount',
  );
  _emitDialogueAndMood(
    config: config,
    seeds: seeds,
    onDialogue: onDialogue,
    onMood: onMood,
  );
  final result = StrategicOrderResult(orders: orders, economyPlan: economyPlan);
  return StrategicOrderTraceResult(
    result: result,
    aiTraceSection: _buildAiTraceSection(
      nationId: nationId,
      turn: turn,
      config: config,
      seeds: seeds,
      snapshot: snapshot,
      primaryGoal: primaryGoal,
      goalScores: goalScores,
      economyPlan: economyPlan,
      orders: orders,
    ),
  );
}

TurnTraceAiSection _buildAiTraceSection({
  required String nationId,
  required int turn,
  required AIConfig config,
  required AISeedBundle seeds,
  required AIWorldSnapshot snapshot,
  required StrategicGoal primaryGoal,
  required Map<StrategicGoal, int> goalScores,
  required EconomyPlan economyPlan,
  required Orders orders,
}) {
  final ordersByDomain = _orderCountsByDomain(nationId, orders);
  final finalOrders = _finalAggregatedOrders(nationId, orders);
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
      'topAlternates': _rankedGoalCandidates(goalScores, exclude: primaryGoal),
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
        'goalCandidateScores': _goalScoresJson(goalScores),
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
        'adjustedGoalScores': _goalScoresJson(goalScores),
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
      'gates': <Object?>[
        ..._goalSelectionGates(goalScores, primaryGoal),
      ],
    },
    outcome: <String, Object?>{
      'domainOutputs': ordersByDomain,
      'finalAggregatedOrders': finalOrders,
      'emittedOrderCount': finalOrders.length,
    },
  );
}

List<Map<String, Object?>> _goalSelectionGates(
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

Map<String, Object?> _goalScoresJson(Map<StrategicGoal, int> goalScores) {
  return <String, Object?>{
    for (final entry in goalScores.entries) entry.key.name: entry.value,
  };
}

List<Map<String, Object?>> _rankedGoalCandidates(
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

Map<String, Object?> _orderCountsByDomain(String playerId, Orders orders) {
  return <String, Object?>{
    'move':
        (orders.moveOrdersByPlayerId[playerId] ?? const <MoveOrder>[]).length,
    'armyMove':
        (orders.armyMoveOrdersByPlayerId[playerId] ?? const <ArmyMoveOrder>[])
            .length,
    'build':
        (orders.buildUnitOrdersByPlayerId[playerId] ?? const <BuildUnitOrder>[])
            .length,
    'work':
        (orders.workOrdersByPlayerId[playerId] ?? const <WorkOrder>[]).length,
    'diplomatic':
        (orders.diplomaticOrdersByPlayerId[playerId] ??
                const <DiplomaticOrder>[])
            .length,
    'research':
        (orders.researchOrdersByPlayerId[playerId] ?? const <ResearchOrder>[])
            .length,
    'navalMove':
        (orders.navalMoveOrdersByPlayerId[playerId] ?? const <NavalMoveOrder>[])
            .length,
    'navalMission':
        (orders.navalMissionOrdersByPlayerId[playerId] ??
                const <NavalMissionOrder>[])
            .length,
  };
}

List<Map<String, Object?>> _finalAggregatedOrders(
  String playerId,
  Orders orders,
) {
  final aggregated = <Map<String, Object?>>[];
  for (final order
      in orders.moveOrdersByPlayerId[playerId] ?? const <MoveOrder>[]) {
    aggregated.add(<String, Object?>{
      'domain': 'move',
      'unitId': order.unitId,
      'destinationTileKey': order.destinationTileKey,
    });
  }
  for (final order
      in orders.armyMoveOrdersByPlayerId[playerId] ?? const <ArmyMoveOrder>[]) {
    aggregated.add(<String, Object?>{
      'domain': 'armyMove',
      'armyId': order.armyId,
      'destinationProvinceId': order.destinationProvinceId,
    });
  }
  for (final order
      in orders.buildUnitOrdersByPlayerId[playerId] ??
          const <BuildUnitOrder>[]) {
    aggregated.add(<String, Object?>{
      'domain': 'build',
      'unitType': order.unitType,
      'spawnProvinceId': order.spawnProvinceId,
    });
  }
  for (final order
      in orders.workOrdersByPlayerId[playerId] ?? const <WorkOrder>[]) {
    aggregated.add(<String, Object?>{
      'domain': 'work',
      'unitId': order.unitId,
      'targetTileKey': order.targetTileKey,
      'target': order.target,
    });
  }
  for (final order
      in orders.diplomaticOrdersByPlayerId[playerId] ??
          const <DiplomaticOrder>[]) {
    aggregated.add(<String, Object?>{
      'domain': 'diplomatic',
      'type': order.type.name,
      'targetFactionId': order.targetFactionId,
      if (order.amount != null) 'amount': order.amount,
    });
  }
  for (final order
      in orders.researchOrdersByPlayerId[playerId] ?? const <ResearchOrder>[]) {
    aggregated.add(<String, Object?>{
      'domain': 'research',
      'slotIndex': order.slotIndex,
      'techId': order.techId,
      'funding': order.funding.name,
    });
  }
  for (final order
      in orders.navalMoveOrdersByPlayerId[playerId] ??
          const <NavalMoveOrder>[]) {
    aggregated.add(<String, Object?>{
      'domain': 'navalMove',
      'fleetId': order.fleetId,
      'isDock': order.isDock,
      'destinationSeaZoneId': order.destinationSeaZoneId,
      'destinationPortProvinceId': order.destinationPortProvinceId,
    });
  }
  for (final order
      in orders.navalMissionOrdersByPlayerId[playerId] ??
          const <NavalMissionOrder>[]) {
    aggregated.add(<String, Object?>{
      'domain': 'navalMission',
      'fleetId': order.fleetId,
      'mission': order.mission,
      'targetProvinceId': order.targetProvinceId,
      'targetPortId': order.targetPortId,
    });
  }
  return List<Map<String, Object?>>.unmodifiable(aggregated);
}

void _emitDialogueAndMood({
  required AIConfig config,
  required AISeedBundle seeds,
  void Function(DialogueEvent)? onDialogue,
  void Function(PortraitMoodEvent)? onMood,
}) {
  // Optional dialogue/mood emission (deterministic from dialogueSeed).
  // SPEC/ai/dialogue-and-mood.md § When to emit:
  // Strategic AI may emit optional agenda/comment and base mood once every
  // kDialogueTurnsBetweenComments turns per leader, when
  // `dialogueSeed % kDialogueTurnsBetweenComments == 0`.
  if (onDialogue != null &&
      seeds.dialogueSeed % kDialogueTurnsBetweenComments == 0) {
    onDialogue(
      DialogueEvent(
        leaderId: config.leaderId,
        category: 'agenda',
        situation: 'comment',
        era: 'earlyModern',
        variables: const {},
      ),
    );
  }
  if (onMood != null &&
      seeds.dialogueSeed % kDialogueTurnsBetweenComments == 0) {
    onMood(
      PortraitMoodEvent(
        leaderId: config.leaderId,
        fromMood: kDefaultMood,
        toMood: kDefaultMood,
        durationMs: 0,
      ),
    );
  }
}
