/// Shared orchestrator pin runners (Refs #3941 / #3972).
library;

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/domain_planner_outcome.dart';
import 'package:colonizethis_data/colonizethis_data.dart' show MapTopology;
import 'package:colonizethis_logic/ai_api.dart' show buildPlayerView;
import 'package:colonizethis_logic/order_suggestion_api.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'domain_planner_orchestrator_quota_consts.dart';
import 'domain_planner_test_fake_api.dart';
import 'planner_test_helpers.dart';

/// Runs [runDomainPlannersWithOutcome] with shared topology/view wiring.
DomainPlannerOutcome runOrchestratorWithFakeApi({
  required Game game,
  required AIWorldSnapshot snapshot,
  required OrderSuggestionAPI suggestionAPI,
  String nationId = kOrchestratorGp1NationId,
  MapTopology topology = const MapTopology(nodes: [], edges: []),
  AIConfig config = kTestAiConfig,
  StrategicGoal primaryGoal = StrategicGoal.conquer,
  int turnSeed = 1,
  EconomyPlan economyPlan = kOrchestratorEmptyEconomyPlan,
  OrchestratorOptions options = const OrchestratorOptions(),
}) {
  final view = buildPlayerView(game, topology, nationId);
  return runDomainPlannersWithOutcome(
    DomainPlannerInput(
      game: game,
      topology: topology,
      nationId: nationId,
      view: view,
      snapshot: snapshot,
      config: config,
      primaryGoal: primaryGoal,
      seeds: AISeedBundle.fromTurnSeed(turnSeed),
      suggestionAPI: suggestionAPI,
      economyPlan: economyPlan,
      options: options,
    ),
  );
}

/// Convenience when the fake API type is the domain-planner test fake.
DomainPlannerOutcome runOrchestratorPin({
  required Game game,
  required AIWorldSnapshot snapshot,
  required FakeOrderSuggestionAPIForDomainPlannerTests suggestionAPI,
  String nationId = kOrchestratorGp1NationId,
  MapTopology topology = const MapTopology(nodes: [], edges: []),
  AIConfig config = kTestAiConfig,
  StrategicGoal primaryGoal = StrategicGoal.conquer,
  int turnSeed = 1,
  EconomyPlan economyPlan = kOrchestratorEmptyEconomyPlan,
  OrchestratorOptions options = const OrchestratorOptions(),
}) {
  return runOrchestratorWithFakeApi(
    game: game,
    snapshot: snapshot,
    suggestionAPI: suggestionAPI,
    nationId: nationId,
    topology: topology,
    config: config,
    primaryGoal: primaryGoal,
    turnSeed: turnSeed,
    economyPlan: economyPlan,
    options: options,
  );
}
