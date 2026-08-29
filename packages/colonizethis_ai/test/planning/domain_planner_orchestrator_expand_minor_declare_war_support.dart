// Shared fixtures for EXPAND adjacent invadable OW minor declare-war pins.

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../support/domain_planner_orchestrator_test_support.dart';
import '../support/domain_planner_test_fake_api.dart';

const String kExpandMinorDeclareWarNationId = kOrchestratorGp1NationId;
const String kExpandMinorDeclareWarMinorId = kOrchestratorAdjacentMinorId;

const FakeOrderSuggestionAPIForDomainPlannerTests kExpandMinorDeclareWarApi =
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
      targetFactionId: kExpandMinorDeclareWarMinorId,
    ),
  ],
);

const EconomyPlan kExpandMinorDeclareWarEconomyPlan = EconomyPlan(
  productionAssignments: [],
  cargoPreference: CargoPreference.none,
);

const AIConfig kExpandMinorDeclareWarAiConfig = AIConfig(
  leaderId: 'henry',
  personalityId: 'henry',
  hiddenAgendaId: 'merchant',
);

List<String> expandMinorDeclareWarTargets(Orders orders) => <String>[
  for (final order
      in orders.diplomaticOrdersByPlayerId[kExpandMinorDeclareWarNationId] ??
          const [])
    if (order.type == DiplomaticOrderType.declareWar) order.targetFactionId,
];
