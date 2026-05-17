import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/ai_api.dart';
import 'package:colonizethis_logic/order_suggestion_api.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'goal_manager.dart';

/// Shared inputs for domain planners (Refs #2521 AC1).
class PlannerContext {
  PlannerContext({
    required this.nationId,
    required this.view,
    required this.game,
    required this.topology,
    required this.orders,
    required this.config,
    required this.primaryGoal,
    required this.seeds,
    required this.suggestionAPI,
    int? currentTurn,
  }) : currentTurn = currentTurn ?? game.worldState.turnState.turnNumber;

  final String nationId;
  final PlayerView view;
  final Game game;
  final MapTopology topology;
  final Orders orders;
  final AIConfig config;
  final StrategicGoal primaryGoal;
  final AISeedBundle seeds;
  final OrderSuggestionAPI suggestionAPI;
  final int currentTurn;

  late final Map<String, String?> provinceOwner = getProvinceOwnerMap(game);

  PersonalityDomainWeights get domainWeights =>
      getDomainWeightsForLeader(config.personalityId);

  /// Move / army-move / conquest base weight (military vs economy vs fallback).
  int resolveMilitaryEconomyWeight({int fallback = 50}) {
    if (primaryGoal == StrategicGoal.conquer ||
        primaryGoal == StrategicGoal.defend) {
      return domainWeights.military;
    }
    if (primaryGoal == StrategicGoal.expand) {
      return domainWeights.economy;
    }
    return fallback;
  }

  /// Naval planner base weight (military for conquer/defend/expand).
  int resolveNavalBaseWeight({int fallback = 40}) {
    if (primaryGoal == StrategicGoal.conquer ||
        primaryGoal == StrategicGoal.defend ||
        primaryGoal == StrategicGoal.expand) {
      return domainWeights.military;
    }
    return fallback;
  }

  /// Diplomacy planner base weight before pass-specific floors.
  int resolveDiplomacyBaseWeight({int fallback = 40}) {
    if (primaryGoal == StrategicGoal.diplomacy ||
        primaryGoal == StrategicGoal.conquer ||
        primaryGoal == StrategicGoal.trade) {
      return domainWeights.diplomacy;
    }
    return fallback;
  }

  PlannerContext withOrders(Orders nextOrders) => PlannerContext(
    nationId: nationId,
    view: view,
    game: game,
    topology: topology,
    orders: nextOrders,
    config: config,
    primaryGoal: primaryGoal,
    seeds: seeds,
    suggestionAPI: suggestionAPI,
    currentTurn: currentTurn,
  );
}
