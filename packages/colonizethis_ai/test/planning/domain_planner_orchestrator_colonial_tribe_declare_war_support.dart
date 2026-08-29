// Shared fixtures for COLONIAL tribe declare-war orchestrator pins (Refs #2509).

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/observer_goal_phase.dart';
import 'package:colonizethis_ai/src/planning/orchestrator_options.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../support/domain_planner_orchestrator_test_support.dart';
import '../support/domain_planner_test_fake_api.dart';

const String kColonialTribeDeclareWarNationId = kOrchestratorGp1NationId;
const String kColonialTribeDeclareWarTribeId = kOrchestratorTribeId;

const PhasePriorityWeights kColonialTribeDeclareWarNwAcquisitionZeroExpand =
    PhasePriorityWeights(
  oldWorldConquest: 0.95,
  newWorldAcquisition: 0.0,
  oldWorldCivilian: 0.90,
  newWorldCivilian: 0.10,
);

const PhasePlanOutcome kColonialTribeDeclareWarExpandPhasePlanHardSuppressNw =
    PhasePlanOutcome(
  phase: ObserverGoalPhase.expand,
  priorityWeights: kColonialTribeDeclareWarNwAcquisitionZeroExpand,
);

const FakeOrderSuggestionAPIForDomainPlannerTests kColonialTribeDeclareWarApi =
    FakeOrderSuggestionAPIForDomainPlannerTests(
  work: [],
  build: [],
  move: [],
  research: [],
  navalMove: [],
  navalMission: [],
  diplomatic: [
    DiplomaticOrder(
      type: DiplomaticOrderType.declareWar,
      targetFactionId: kColonialTribeDeclareWarTribeId,
    ),
  ],
);

const EconomyPlan kColonialTribeDeclareWarEconomyPlan = EconomyPlan(
  productionAssignments: [],
  cargoPreference: CargoPreference.none,
);

const AIConfig kColonialTribeDeclareWarAiConfig = AIConfig(
  leaderId: 'henry',
  personalityId: 'henry',
  hiddenAgendaId: 'merchant',
);

List<String> colonialTribeDeclareWarTargets(Orders orders) => <String>[
  for (final order
      in orders.diplomaticOrdersByPlayerId[kColonialTribeDeclareWarNationId] ??
          const [])
    if (order.type == DiplomaticOrderType.declareWar) order.targetFactionId,
];
