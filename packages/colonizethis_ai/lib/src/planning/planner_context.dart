import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/ai_api.dart';
import 'package:colonizethis_logic/order_suggestion_api.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'goal_manager.dart';
import 'growth_stage.dart' show kGrowthStagePlannerEnabled;

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
    this.sameTurnPriorDiplomaticOrders,
    this.growthStagePlannerEnabled = kGrowthStagePlannerEnabled,
    int? currentTurn,
    Map<String, String?>? provinceOwner,
  }) : currentTurn = currentTurn ?? game.worldState.turnState.turnNumber,
       _provinceOwner = provinceOwner;

  final String nationId;
  final PlayerView view;
  final Game game;
  final MapTopology topology;
  final Orders orders;
  final AIConfig config;
  final StrategicGoal primaryGoal;
  final AISeedBundle seeds;
  final OrderSuggestionAPI suggestionAPI;

  /// Declare-war orders from earlier Full AI players this turn (Refs #2509).
  final Orders? sameTurnPriorDiplomaticOrders;

  /// When true, growth-stage economy scoring replaces H8 reactive boosts (Refs #3371).
  final bool growthStagePlannerEnabled;
  final int currentTurn;

  /// Province-owner map memo. Computed lazily on first read and threaded
  /// across [withOrders] so the O(provinces) [getProvinceOwnerMap] scan runs
  /// at most once per AI player turn instead of once per accumulation step
  /// (conquest army-move passes, relocation, and move planning each rebuilt
  /// the context previously). Province ownership is read-only during domain
  /// planning, so the memo stays valid for the lifetime of one player turn.
  /// Refs #3288 (eliminate redundant world-state recomputation).
  Map<String, String?>? _provinceOwner;

  Map<String, String?> get provinceOwner =>
      _provinceOwner ??= getProvinceOwnerMap(game);

  PersonalityDomainWeights get domainWeights => resolveDomainWeights(
    config.personalityId,
    overrides: config.parameterOverrides,
  );

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
    sameTurnPriorDiplomaticOrders: sameTurnPriorDiplomaticOrders,
    growthStagePlannerEnabled: growthStagePlannerEnabled,
    currentTurn: currentTurn,
    provinceOwner: _provinceOwner,
  );
}
