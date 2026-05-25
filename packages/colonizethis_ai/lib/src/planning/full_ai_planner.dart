/// Full Phase 6 AI order orchestration (delegates to strategic planners). SPEC/program/ai-planner.md.

import 'package:colonizethis_logic/order_suggestion_api.dart';

import 'diplomacy_planner.dart';
import 'observer_goal_phase.dart';
import 'planning_imports.dart';
import 'strategic_ai.dart';

final _log = packageLogger();

/// Generates orders and economy plan for a single AI-controlled GP using full AI (Phase 6).
/// Caller should ensure game has hidden agendas assigned ([assignHiddenAgendasForGame]).
/// SPEC/ai/economy-planner.md.
StrategicOrderResult generateOrdersForPlayerFullAI(
  Game game,
  MapTopology topology,
  String playerId, {
  Map<String, TileMapResult>? tileMapByRegion,
  OrderSuggestionAPI? orderSuggestionApi,
  void Function(DialogueEvent)? onDialogue,
  void Function(PortraitMoodEvent)? onMood,
}) {
  return generateOrdersForPlayerFullAIWithTrace(
    game,
    topology,
    playerId,
    tileMapByRegion: tileMapByRegion,
    orderSuggestionApi: orderSuggestionApi,
    onDialogue: onDialogue,
    onMood: onMood,
  ).result;
}

typedef FullAIPlayerTraceResult = StrategicOrderTraceResult;

StrategicOrderTraceResult generateOrdersForPlayerFullAIWithTrace(
  Game game,
  MapTopology topology,
  String playerId, {
  Map<String, TileMapResult>? tileMapByRegion,
  OrderSuggestionAPI? orderSuggestionApi,
  void Function(DialogueEvent)? onDialogue,
  void Function(PortraitMoodEvent)? onMood,
  void Function(String phaseId)? onStagedPlannerProgress,
  Orders? sameTurnPriorDiplomaticOrders,
}) {
  final player = game.playerById(playerId);
  if (player == null || !isAiControlled(game, player.id)) {
    return StrategicOrderTraceResult(
      result: const StrategicOrderResult(
        orders: Orders(),
        economyPlan: EconomyPlan(
          productionAssignments: [],
          cargoPreference: CargoPreference.none,
        ),
      ),
      game: game,
    );
  }
  final view = buildPlayerView(game, topology, playerId);
  final turn = game.worldState.turnState.turnNumber;
  final turnSeed = turnSeedForPlayer(game, player.id, turn);
  final seeds = AISeedBundle.fromTurnSeed(turnSeed);
  final leaderKeyOrId = player.leaderKey ?? player.id;
  final leaderId = canonicalLeaderIdForPersonality(leaderKeyOrId);
  final personalityKey = personalityLookupKeyForAi(
    leaderKeyOrId: leaderKeyOrId,
    personalityId: player.personalityId,
  );
  final agendaId = game.hiddenAgendaByGpId[playerId] ?? 'peacemaker';
  final config = AIConfig(
    leaderId: leaderId,
    personalityId: personalityKey,
    hiddenAgendaId: agendaId,
  );
  final suggestionAPI = orderSuggestionApi ?? const DefaultOrderSuggestionAPI();
  final traced = generateStrategicOrdersWithTrace(
    game: game,
    topology: topology,
    nationId: playerId,
    view: view,
    config: config,
    seeds: seeds,
    suggestionAPI: suggestionAPI,
    tileMapByRegion: tileMapByRegion,
    onDialogue: onDialogue,
    onMood: onMood,
    onStagedPlannerProgress: onStagedPlannerProgress,
    sameTurnPriorDiplomaticOrders: sameTurnPriorDiplomaticOrders,
  );
  return traced;
}

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

/// Generates orders and economy plans for all AI-controlled GPs using full AI. Aggregates all order types including naval.
FullAIResult generateOrdersForGameFullAI(
  Game game,
  MapTopology topology, {
  Map<String, TileMapResult>? tileMapByRegion,
  OrderSuggestionAPI? orderSuggestionApi,
  void Function(DialogueEvent)? onDialogue,
  void Function(PortraitMoodEvent)? onMood,
  void Function(String phaseId)? onStagedPlannerProgress,
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
  final economyPlansByPlayerId = <String, EconomyPlan>{};
  final aiTraceSections = <TurnTraceAiSection>[];

  final aiPlayerIds = [
    for (final p in game.players)
      if (isAiControlled(game, p.id)) p.id,
  ];
  final turn = game.worldState.turnState.turnNumber;
  // Offset rotation so gp3–gp6 plan before gp1–gp2 on early turns when minors
  // are still available (observer seed-42 conquest gate; Refs #2509).
  final rotateStart = aiPlayerIds.isEmpty ? 0 : (turn + 2) % aiPlayerIds.length;
  final orderedAiPlayerIds = [
    ...aiPlayerIds.sublist(rotateStart),
    ...aiPlayerIds.sublist(0, rotateStart),
  ];
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
