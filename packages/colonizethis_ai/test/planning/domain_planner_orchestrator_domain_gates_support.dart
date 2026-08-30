// Shared fixtures for Refs #2832 domain-gate orchestrator pins (#4669 Slice D).

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/domain_planner_outcome.dart';
import 'package:colonizethis_ai/src/planning/orchestrator_options.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../support/domain_planner_test_fake_api.dart';
import '../support/domain_planner_orchestrator_test_support.dart';

const String kDomainGatesNationId = kOrchestratorGp1NationId;
const String kDomainGatesFieldArmyId = kOrchestratorFieldArmyId;
const String kDomainGatesOwMinorProvince = kOrchestratorOwMinorProvince;

const FakeOrderSuggestionAPIForDomainPlannerTests kDomainGatesConquestApi =
    FakeOrderSuggestionAPIForDomainPlannerTests(
  work: [],
  build: [],
  move: [],
  research: [],
  navalMove: [],
  navalMission: [],
  armyMove: [
    ArmyMoveOrder(
      armyId: kDomainGatesFieldArmyId,
      destinationProvinceId: kDomainGatesOwMinorProvince,
    ),
  ],
);

const EconomyPlan kDomainGatesEconomyPlan = EconomyPlan(
  productionAssignments: [],
  cargoPreference: CargoPreference.none,
);

const AIConfig kDomainGatesAiConfig = AIConfig(
  leaderId: 'napoleon',
  personalityId: 'napoleon',
  hiddenAgendaId: 'warmonger',
);

DomainPlannerOutcome runDomainGatesForPhase(PhasePlanOutcome plan) {
  final game = buildOrchestratorExpandMinorWarScenarioGame(
    id: 'g-2832-orchestrator-domain-gates',
  );
  const topology = MapTopology(nodes: [], edges: []);
  final view = buildPlayerView(game, topology, kDomainGatesNationId);
  final snapshot = buildOrchestratorExpandMinorWarAtWarSnapshot();
  return runDomainPlannersWithOutcome(
    DomainPlannerInput(
      game: game,
      topology: topology,
      nationId: kDomainGatesNationId,
      view: view,
      snapshot: snapshot,
      config: kDomainGatesAiConfig,
      primaryGoal: StrategicGoal.conquer,
      seeds: AISeedBundle.fromTurnSeed(2832100),
      suggestionAPI: kDomainGatesConquestApi,
      economyPlan: kDomainGatesEconomyPlan,
      options: OrchestratorOptions(phasePlan: plan),
    ),
  );
}
