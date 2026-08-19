/// Per-player Full AI setup: view, seeds, [AIConfig], then strategic trace.
/// SPEC/program/ai-planner.md, SPEC/ai/economy-planner.md (Refs #4530).
library;

import 'package:colonizethis_logic/order_suggestion_api.dart';

import 'growth_stage.dart' show kGrowthStagePlannerEnabled;
import 'planning_imports.dart';
import 'strategic_ai.dart';
import 'strategic_planning_input.dart';

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
  Map<String, AiProfile>? profiles,
}) {
  return generateOrdersForPlayerFullAIWithTrace(
    game,
    topology,
    playerId,
    tileMapByRegion: tileMapByRegion,
    orderSuggestionApi: orderSuggestionApi,
    onDialogue: onDialogue,
    onMood: onMood,
    profiles: profiles,
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
  bool growthStagePlannerEnabled = kGrowthStagePlannerEnabled,
  Map<String, AiProfile>? profiles,
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
  final activeProfile = profiles?[playerId];
  final config = AIConfig(
    leaderId: leaderId,
    personalityId: personalityKey,
    hiddenAgendaId: agendaId,
    parameterOverrides: activeProfile?.parameters,
    profileId: activeProfile?.profileId,
  );
  final suggestionAPI = orderSuggestionApi ?? const DefaultOrderSuggestionAPI();
  return generateStrategicOrdersWithTrace(
    StrategicPlanningInput(
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
      growthStagePlannerEnabled: growthStagePlannerEnabled,
    ),
  );
}
