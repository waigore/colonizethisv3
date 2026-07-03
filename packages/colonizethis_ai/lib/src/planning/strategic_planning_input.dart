import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/ai_api.dart';
import 'package:colonizethis_logic/order_suggestion_api.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'growth_stage.dart' show kGrowthStagePlannerEnabled;

/// Bundles inputs for [generateStrategicOrdersWithTrace] (Refs #3822 Phase 3).
final class StrategicPlanningInput {
  const StrategicPlanningInput({
    required this.game,
    required this.topology,
    required this.nationId,
    required this.view,
    required this.config,
    required this.seeds,
    required this.suggestionAPI,
    this.tileMapByRegion,
    this.onDialogue,
    this.onMood,
    this.onStagedPlannerProgress,
    this.sameTurnPriorDiplomaticOrders,
    this.growthStagePlannerEnabled = kGrowthStagePlannerEnabled,
  });

  final Game game;
  final MapTopology topology;
  final String nationId;
  final PlayerView view;
  final AIConfig config;
  final AISeedBundle seeds;
  final OrderSuggestionAPI suggestionAPI;
  final Map<String, TileMapResult>? tileMapByRegion;
  final void Function(DialogueEvent)? onDialogue;
  final void Function(PortraitMoodEvent)? onMood;
  final void Function(String phaseId)? onStagedPlannerProgress;
  final Orders? sameTurnPriorDiplomaticOrders;
  final bool growthStagePlannerEnabled;
}
