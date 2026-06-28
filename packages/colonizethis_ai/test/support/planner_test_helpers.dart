import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/planner_context.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

/// Default AI config for domain-planner tests (Refs #2521).
const kTestAiConfig = AIConfig(
  leaderId: 'victoria',
  personalityId: 'victoria',
  hiddenAgendaId: 'peacemaker',
);

const kTestEconomyPlan = EconomyPlan(
  productionAssignments: [],
  cargoPreference: CargoPreference.none,
);

/// Builds [PlannerContext] for unit tests of individual domain planners.
PlannerContext buildTestPlannerContext({
  required Game game,
  required MapTopology topology,
  String nationId = 'gp1',
  PlayerView? view,
  Orders orders = const Orders(),
  AIConfig config = kTestAiConfig,
  StrategicGoal primaryGoal = StrategicGoal.expand,
  int turnSeed = 1,
  OrderSuggestionAPI suggestionAPI = const DefaultOrderSuggestionAPI(),
}) {
  final resolvedView = view ?? buildPlayerView(game, topology, nationId);
  return PlannerContext(
    nationId: nationId,
    view: resolvedView,
    game: game,
    topology: topology,
    orders: orders,
    config: config,
    primaryGoal: primaryGoal,
    seeds: AISeedBundle.fromTurnSeed(turnSeed),
    suggestionAPI: suggestionAPI,
  );
}

/// Runs [runDomainPlanners] with shared test defaults for orchestrator tests.
Orders runDomainPlannersInTest({
  required Game game,
  required MapTopology topology,
  String nationId = 'gp1',
  PlayerView? view,
  AIWorldSnapshot? snapshot,
  AIConfig config = kTestAiConfig,
  StrategicGoal primaryGoal = StrategicGoal.expand,
  int turnSeed = 1,
  OrderSuggestionAPI suggestionAPI = const DefaultOrderSuggestionAPI(),
  EconomyPlan economyPlan = kTestEconomyPlan,
  Map<String, TileMapResult>? tileMapByRegion,
  void Function(String phaseId)? onStagedPlannerProgress,
}) {
  final resolvedView = view ?? buildPlayerView(game, topology, nationId);
  final resolvedSnapshot =
      snapshot ?? AIWorldSnapshot.fromPlayerView(resolvedView);
  return runDomainPlanners(
    game: game,
    topology: topology,
    nationId: nationId,
    view: resolvedView,
    snapshot: resolvedSnapshot,
    config: config,
    primaryGoal: primaryGoal,
    seeds: AISeedBundle.fromTurnSeed(turnSeed),
    suggestionAPI: suggestionAPI,
    economyPlan: economyPlan,
    tileMapByRegion: tileMapByRegion,
    onStagedPlannerProgress: onStagedPlannerProgress,
  );
}
