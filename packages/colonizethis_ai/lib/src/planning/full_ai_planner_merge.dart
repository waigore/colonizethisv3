/// All-GP Full AI rotation and order-family merge.
/// SPEC/program/ai-planner.md, SPEC/ai/economy-planner.md (Refs #4530).
library;

import 'package:colonizethis_logic/order_suggestion_api.dart';

import 'diplomacy_planner.dart';
import 'full_ai_planner_player_setup.dart';
import 'growth_stage.dart' show kGrowthStagePlannerEnabled;
import 'planning_imports.dart';

final _log = packageLogger();

/// Result of full-AI order generation for all AI GPs: merged orders and per-player economy plans.
/// SPEC/ai/economy-planner.md, SPEC/program/ai-planner.md.
class FullAIResult {
  const FullAIResult({
    required this.orders,
    required this.economyPlansByPlayerId,
    required this.game,
    this.aiTraceSections = const <TurnTraceAiSection>[],
  });
  final Orders orders;
  final Map<String, EconomyPlan> economyPlansByPlayerId;
  final Game game;
  final List<TurnTraceAiSection> aiTraceSections;
}

/// Offset rotation so gp3–gp6 plan before gp1–gp2 on early turns when minors
/// are still available (observer seed-42 conquest gate; Refs #2509).
List<String> orderedFullAiPlayerIds({
  required List<String> aiPlayerIds,
  required int turn,
}) {
  if (aiPlayerIds.isEmpty) return const <String>[];
  final rotateStart = (turn + 2) % aiPlayerIds.length;
  return [
    ...aiPlayerIds.sublist(rotateStart),
    ...aiPlayerIds.sublist(0, rotateStart),
  ];
}

/// Generates orders and economy plans for all AI-controlled GPs using full AI. Aggregates all order types including naval.
FullAIResult generateOrdersForGameFullAI(
  Game game,
  MapTopology topology, {
  Map<String, TileMapResult>? tileMapByRegion,
  OrderSuggestionAPI? orderSuggestionApi,
  void Function(DialogueEvent)? onDialogue,
  void Function(PortraitMoodEvent)? onMood,
  void Function(String phaseId)? onStagedPlannerProgress,
  bool growthStagePlannerEnabled = kGrowthStagePlannerEnabled,
  Map<String, AiProfile>? profiles,
}) {
  final totalStopwatch = Stopwatch()..start();
  var planningGame = game;
  final moveByPlayer = <String, List<MoveOrder>>{};
  final armyMoveByPlayer = <String, List<ArmyMoveOrder>>{};
  final buildByPlayer = <String, List<BuildUnitOrder>>{};
  final workByPlayer = <String, List<WorkOrder>>{};
  final researchByPlayer = <String, List<ResearchOrder>>{};
  final diploByPlayer = <String, List<DiplomaticOrder>>{};
  final navalByPlayer = <String, List<NavalMoveOrder>>{};
  final missionByPlayer = <String, List<NavalMissionOrder>>{};
  final tradeByPlayer = <String, List<TradeOrder>>{};
  final economyPlansByPlayerId = <String, EconomyPlan>{};
  final aiTraceSections = <TurnTraceAiSection>[];

  final aiPlayerIds = [
    for (final p in game.players)
      if (isAiControlled(game, p.id)) p.id,
  ];
  final turn = game.worldState.turnState.turnNumber;
  final orderedAiPlayerIds = orderedFullAiPlayerIds(
    aiPlayerIds: aiPlayerIds,
    turn: turn,
  );
  for (final playerId in orderedAiPlayerIds) {
    final playerStopwatch = Stopwatch()..start();
    _log.i('full_ai player_start gameId=${game.id} playerId=$playerId');
    final sameTurnPriorDiplomaticOrders = diploByPlayer.isEmpty
        ? null
        : Orders(diplomaticOrdersByPlayerId: Map.from(diploByPlayer));
    final traced = generateOrdersForPlayerFullAIWithTrace(
      planningGame,
      topology,
      playerId,
      tileMapByRegion: tileMapByRegion,
      orderSuggestionApi: orderSuggestionApi,
      onDialogue: onDialogue,
      onMood: onMood,
      onStagedPlannerProgress: onStagedPlannerProgress,
      sameTurnPriorDiplomaticOrders: sameTurnPriorDiplomaticOrders,
      growthStagePlannerEnabled: growthStagePlannerEnabled,
      profiles: profiles,
    );
    _log.i(
      'full_ai player_complete gameId=${game.id} playerId=$playerId '
      'elapsedMs=${playerStopwatch.elapsedMilliseconds}',
    );
    planningGame = traced.game;
    final result = traced.result;
    economyPlansByPlayerId[playerId] = result.economyPlan;
    final aiTraceSection = traced.aiTraceSection;
    if (aiTraceSection != null) {
      aiTraceSections.add(aiTraceSection);
    }
    _addOrdersIfNonEmpty(
      moveByPlayer,
      playerId,
      result.orders.moveOrdersByPlayerId[playerId],
    );
    _addOrdersIfNonEmpty(
      armyMoveByPlayer,
      playerId,
      result.orders.armyMoveOrdersByPlayerId[playerId],
    );
    _addOrdersIfNonEmpty(
      buildByPlayer,
      playerId,
      result.orders.buildUnitOrdersByPlayerId[playerId],
    );
    _addOrdersIfNonEmpty(
      workByPlayer,
      playerId,
      result.orders.workOrdersByPlayerId[playerId],
    );
    _addOrdersIfNonEmpty(
      researchByPlayer,
      playerId,
      result.orders.researchOrdersByPlayerId[playerId],
    );
    _addOrdersIfNonEmpty(
      diploByPlayer,
      playerId,
      result.orders.diplomaticOrdersByPlayerId[playerId],
    );
    _addOrdersIfNonEmpty(
      navalByPlayer,
      playerId,
      result.orders.navalMoveOrdersByPlayerId[playerId],
    );
    _addOrdersIfNonEmpty(
      missionByPlayer,
      playerId,
      result.orders.navalMissionOrdersByPlayerId[playerId],
    );
    _addOrdersIfNonEmpty(
      tradeByPlayer,
      playerId,
      result.orders.tradeOrdersByPlayerId[playerId],
    );
  }

  _log.i(
    'full_ai complete gameId=${game.id} '
    'aiPlayers=${economyPlansByPlayerId.length} '
    'elapsedMs=${totalStopwatch.elapsedMilliseconds}',
  );

  final mergedOrders = supplementMutualStalledGreatPowerPeaceOrders(
    game: game,
    topology: topology,
    orders: Orders(
      moveOrdersByPlayerId: moveByPlayer,
      armyMoveOrdersByPlayerId: armyMoveByPlayer,
      buildUnitOrdersByPlayerId: buildByPlayer,
      workOrdersByPlayerId: workByPlayer,
      diplomaticOrdersByPlayerId: diploByPlayer,
      researchOrdersByPlayerId: researchByPlayer,
      navalMoveOrdersByPlayerId: navalByPlayer,
      navalMissionOrdersByPlayerId: missionByPlayer,
      tradeOrdersByPlayerId: tradeByPlayer,
    ),
  );

  return FullAIResult(
    orders: mergedOrders,
    economyPlansByPlayerId: economyPlansByPlayerId,
    game: planningGame,
    aiTraceSections: List<TurnTraceAiSection>.unmodifiable(aiTraceSections),
  );
}

void _addOrdersIfNonEmpty<T>(
  Map<String, List<T>> aggregate,
  String playerId,
  List<T>? list,
) {
  if (list != null && list.isNotEmpty) aggregate[playerId] = list;
}
