/// Full Phase 6 AI order orchestration (delegates to strategic planners). SPEC/program/ai-planner.md.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/ai_api.dart';
import 'package:colonizethis_logic/order_suggestion_api.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'strategic_ai.dart';

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
  final player = game.playerById(playerId);
  if (player == null || !isAiControlled(game, player.id)) {
    return const StrategicOrderResult(
      orders: Orders(),
      economyPlan: EconomyPlan(
        productionAssignments: [],
        cargoPreference: CargoPreference.none,
      ),
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
  return generateStrategicOrders(
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
  );
}

/// Result of full-AI order generation for all AI GPs: merged orders and per-player economy plans.
/// SPEC/ai/economy-planner.md, SPEC/program/ai-planner.md.
class FullAIResult {
  const FullAIResult({
    required this.orders,
    required this.economyPlansByPlayerId,
  });
  final Orders orders;
  final Map<String, EconomyPlan> economyPlansByPlayerId;
}

/// Generates orders and economy plans for all AI-controlled GPs using full AI. Aggregates all order types including naval.
FullAIResult generateOrdersForGameFullAI(
  Game game,
  MapTopology topology, {
  Map<String, TileMapResult>? tileMapByRegion,
  OrderSuggestionAPI? orderSuggestionApi,
  void Function(DialogueEvent)? onDialogue,
  void Function(PortraitMoodEvent)? onMood,
}) {
  final moveByPlayer = <String, List<MoveOrder>>{};
  final armyMoveByPlayer = <String, List<ArmyMoveOrder>>{};
  final buildByPlayer = <String, List<BuildUnitOrder>>{};
  final workByPlayer = <String, List<WorkOrder>>{};
  final researchByPlayer = <String, List<ResearchOrder>>{};
  final diploByPlayer = <String, List<DiplomaticOrder>>{};
  final navalByPlayer = <String, List<NavalMoveOrder>>{};
  final missionByPlayer = <String, List<NavalMissionOrder>>{};
  final economyPlansByPlayerId = <String, EconomyPlan>{};

  for (final player in game.players) {
    if (!isAiControlled(game, player.id)) continue;
    final result = generateOrdersForPlayerFullAI(
      game,
      topology,
      player.id,
      tileMapByRegion: tileMapByRegion,
      orderSuggestionApi: orderSuggestionApi,
      onDialogue: onDialogue,
      onMood: onMood,
    );
    economyPlansByPlayerId[player.id] = result.economyPlan;
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
  );
}

void _addOrdersIfNonEmpty<T>(
  Map<String, List<T>> aggregate,
  String playerId,
  List<T>? list,
) {
  if (list != null && list.isNotEmpty) aggregate[playerId] = list;
}
