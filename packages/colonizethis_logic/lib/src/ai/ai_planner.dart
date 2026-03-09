/// AIPlanner: generates orders for AI-controlled GPs. SPEC/program/ai-planner.md.

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../constants.dart';
import '../world/player_view.dart';
import '../orders/order_suggestion_api_impl.dart';
import 'ai_control.dart';
import 'simple_ai_heuristics.dart';

/// Generates orders for a single AI-controlled GP. Deterministic given game
/// state and seeds. Respects diplomacy: no attacks against factions at peace.
/// Uses the shared simple heuristics (PlayerView, suggestion API, diplomacy filter).
Orders generateOrdersForPlayer(Game game, MapTopology topology, String playerId) {
  final player = game.playerById(playerId);
  if (player == null || !isAiControlled(game, player.id)) {
    return const Orders();
  }

  final turn = game.worldState.turnState.turnNumber;
  final turnSeed = turnSeedForPlayer(game, player.id, turn);
  return generateOrdersWithSimpleHeuristics(
    game,
    topology,
    player.id,
    turnSeed,
  );
}

/// Generates orders for all AI-controlled GPs. Deterministic given game state and seeds.
/// Respects diplomacy: no attacks against factions at peace.
Orders generateOrdersForGame(Game game, MapTopology topology) {
  final moveByPlayer = <String, List<MoveOrder>>{};
  final buildByPlayer = <String, List<BuildUnitOrder>>{};
  final workByPlayer = <String, List<WorkOrder>>{};
  final researchByPlayer = <String, List<ResearchOrder>>{};

  for (final player in game.players) {
    if (!isAiControlled(game, player.id)) continue;
    final ordersForPlayer = generateOrdersForPlayer(game, topology, player.id);
    final moves = ordersForPlayer.moveOrdersByPlayerId[player.id];
    final builds = ordersForPlayer.buildUnitOrdersByPlayerId[player.id];
    final works = ordersForPlayer.workOrdersByPlayerId[player.id];
    final research = ordersForPlayer.researchOrdersByPlayerId[player.id];

    if (moves != null && moves.isNotEmpty) {
      moveByPlayer[player.id] = moves;
    }
    if (builds != null && builds.isNotEmpty) {
      buildByPlayer[player.id] = builds;
    }
    if (works != null && works.isNotEmpty) {
      workByPlayer[player.id] = works;
    }
    if (research != null && research.isNotEmpty) {
      researchByPlayer[player.id] = research;
    }
  }

  return Orders(
    moveOrdersByPlayerId: moveByPlayer,
    buildUnitOrdersByPlayerId: buildByPlayer,
    workOrdersByPlayerId: workByPlayer,
    diplomaticOrdersByPlayerId: const {},
    researchOrdersByPlayerId: researchByPlayer,
    navalMoveOrdersByPlayerId: const {},
  );
}

/// Generates orders and economy plan for a single AI-controlled GP using full AI (Phase 6).
/// Caller should ensure game has hidden agendas assigned (assignHiddenAgendasForGame).
/// SPEC/ai/economy-planner.md.
StrategicOrderResult generateOrdersForPlayerFullAI(
  Game game,
  MapTopology topology,
  String playerId, {
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
  final agendaId = game.hiddenAgendaByGpId[playerId] ?? 'peacemaker';
  final config = AIConfig(
    leaderId: leaderId,
    personalityId: leaderId,
    hiddenAgendaId: agendaId,
  );
  const suggestionAPI = DefaultOrderSuggestionAPI();
  return generateStrategicOrders(
    game: game,
    topology: topology,
    nationId: playerId,
    view: view,
    config: config,
    seeds: seeds,
    suggestionAPI: suggestionAPI,
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
  void Function(DialogueEvent)? onDialogue,
  void Function(PortraitMoodEvent)? onMood,
}) {
  final moveByPlayer = <String, List<MoveOrder>>{};
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
      onDialogue: onDialogue,
      onMood: onMood,
    );
    economyPlansByPlayerId[player.id] = result.economyPlan;
    void add<T>(Map<String, List<T>> map, String pid, List<T>? list) {
      if (list != null && list.isNotEmpty) map[pid] = list;
    }
    add(moveByPlayer, player.id, result.orders.moveOrdersByPlayerId[player.id]);
    add(buildByPlayer, player.id, result.orders.buildUnitOrdersByPlayerId[player.id]);
    add(workByPlayer, player.id, result.orders.workOrdersByPlayerId[player.id]);
    add(researchByPlayer, player.id, result.orders.researchOrdersByPlayerId[player.id]);
    add(diploByPlayer, player.id, result.orders.diplomaticOrdersByPlayerId[player.id]);
    add(navalByPlayer, player.id, result.orders.navalMoveOrdersByPlayerId[player.id]);
    add(missionByPlayer, player.id, result.orders.navalMissionOrdersByPlayerId[player.id]);
  }

  return FullAIResult(
    orders: Orders(
      moveOrdersByPlayerId: moveByPlayer,
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
