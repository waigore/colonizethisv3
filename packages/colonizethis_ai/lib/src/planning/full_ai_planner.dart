/// Full Phase 6 AI order orchestration (delegates to strategic planners). SPEC/program/ai-planner.md.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/ai_api.dart';
import 'package:colonizethis_logic/order_suggestion_api.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_ai/package_logger.dart';
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

class FullAIPlayerTraceResult {
  const FullAIPlayerTraceResult({
    required this.result,
    required this.game,
    this.aiTraceSection,
  });

  final StrategicOrderResult result;
  final Game game;
  final TurnTraceAiSection? aiTraceSection;
}

FullAIPlayerTraceResult generateOrdersForPlayerFullAIWithTrace(
  Game game,
  MapTopology topology,
  String playerId, {
  Map<String, TileMapResult>? tileMapByRegion,
  OrderSuggestionAPI? orderSuggestionApi,
  void Function(DialogueEvent)? onDialogue,
  void Function(PortraitMoodEvent)? onMood,
  void Function(String phaseId)? onStagedPlannerProgress,
}) {
  final player = game.playerById(playerId);
  if (player == null || !isAiControlled(game, player.id)) {
    return FullAIPlayerTraceResult(
      result: const StrategicOrderResult(
        orders: Orders(),
        economyPlan: EconomyPlan(
          productionAssignments: [],
          cargoPreference: CargoPreference.none,
        ),
      ),
      game: game,
      aiTraceSection: null,
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
  );
  return FullAIPlayerTraceResult(
    result: traced.result,
    game: traced.game,
    aiTraceSection: traced.aiTraceSection,
  );
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

  for (final player in game.players) {
    if (!isAiControlled(game, player.id)) continue;
    final playerStopwatch = Stopwatch()..start();
    _log.i('full_ai player_start gameId=${game.id} playerId=${player.id}');
    final traced = generateOrdersForPlayerFullAIWithTrace(
      planningGame,
      topology,
      player.id,
      tileMapByRegion: tileMapByRegion,
      orderSuggestionApi: orderSuggestionApi,
      onDialogue: onDialogue,
      onMood: onMood,
      onStagedPlannerProgress: onStagedPlannerProgress,
    );
    _log.i(
      'full_ai player_complete gameId=${game.id} playerId=${player.id} '
      'elapsedMs=${playerStopwatch.elapsedMilliseconds}',
    );
    planningGame = traced.game;
    final result = traced.result;
    economyPlansByPlayerId[player.id] = result.economyPlan;
    final aiTraceSection = traced.aiTraceSection;
    if (aiTraceSection != null) {
      aiTraceSections.add(aiTraceSection);
    }
    _addOrdersIfNonEmpty(
      moveByPlayer,
      player.id,
      result.orders.moveOrdersByPlayerId[player.id],
    );
    _addOrdersIfNonEmpty(
      armyMoveByPlayer,
      player.id,
      result.orders.armyMoveOrdersByPlayerId[player.id],
    );
    _addOrdersIfNonEmpty(
      buildByPlayer,
      player.id,
      result.orders.buildUnitOrdersByPlayerId[player.id],
    );
    _addOrdersIfNonEmpty(
      workByPlayer,
      player.id,
      result.orders.workOrdersByPlayerId[player.id],
    );
    _addOrdersIfNonEmpty(
      researchByPlayer,
      player.id,
      result.orders.researchOrdersByPlayerId[player.id],
    );
    _addOrdersIfNonEmpty(
      diploByPlayer,
      player.id,
      result.orders.diplomaticOrdersByPlayerId[player.id],
    );
    _addOrdersIfNonEmpty(
      navalByPlayer,
      player.id,
      result.orders.navalMoveOrdersByPlayerId[player.id],
    );
    _addOrdersIfNonEmpty(
      missionByPlayer,
      player.id,
      result.orders.navalMissionOrdersByPlayerId[player.id],
    );
  }

  _log.i(
    'full_ai complete gameId=${game.id} '
    'aiPlayers=${economyPlansByPlayerId.length} '
    'elapsedMs=${totalStopwatch.elapsedMilliseconds}',
  );

  return FullAIResult(
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
