import 'package:colonizethis_logic/order_suggestion_api.dart';

import '../perception/perception_snapshot.dart';
import 'goal_manager.dart';
import 'orchestrator_options.dart';
import 'planning_imports.dart';

/// Bundles required + optional inputs for [runDomainPlanners] /
/// [runDomainPlannersWithOutcome] (Refs #3977 AC5).
final class DomainPlannerInput {
  const DomainPlannerInput({
    required this.game,
    required this.topology,
    required this.nationId,
    required this.view,
    required this.snapshot,
    required this.config,
    required this.primaryGoal,
    required this.seeds,
    required this.suggestionAPI,
    required this.economyPlan,
    this.options = OrchestratorOptions.defaults,
  });

  final Game game;
  final MapTopology topology;
  final String nationId;
  final PlayerView view;
  final AIWorldSnapshot snapshot;
  final AIConfig config;
  final StrategicGoal primaryGoal;
  final AISeedBundle seeds;
  final OrderSuggestionAPI suggestionAPI;
  final EconomyPlan economyPlan;
  final OrchestratorOptions options;
}
