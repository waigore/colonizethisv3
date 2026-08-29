// Shared orchestrator helpers for pending-cost trade recompute pins (Refs #3122).

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/domain_planner_outcome.dart';
import 'package:colonizethis_ai/src/planning/orchestrator_options.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../support/domain_planner_orchestrator_test_support.dart';
import '../support/domain_planner_test_fake_api.dart';

const String kPendingCostTradeNationId = kOrchestratorGp1NationId;

const AIConfig kPendingCostTradeAiConfig = AIConfig(
  leaderId: 'napoleon',
  personalityId: 'napoleon',
  hiddenAgendaId: 'warmonger',
);

DomainPlannerOutcome runPendingCostTradeOrchestrator({
  required EconomyPlan economyPlan,
  required Game game,
  required FakeOrderSuggestionAPIForDomainPlannerTests api,
  required bool recompute,
}) {
  const topology = MapTopology(nodes: [], edges: []);
  final view = buildPlayerView(game, topology, kPendingCostTradeNationId);
  final snapshot = buildOrchestratorExpandMinorWarAtWarSnapshot();
  return runDomainPlannersWithOutcome(
    DomainPlannerInput(
      game: game,
      topology: topology,
      nationId: kPendingCostTradeNationId,
      view: view,
      snapshot: snapshot,
      config: kPendingCostTradeAiConfig,
      primaryGoal: StrategicGoal.expand,
      seeds: AISeedBundle.fromTurnSeed(3122700),
      suggestionAPI: api,
      economyPlan: economyPlan,
      options: OrchestratorOptions(recomputeTradeOrdersWithPendingCosts: recompute),
    ),
  );
}
