// Shared fixtures for EXPAND GP-only invadable frontier blocker pins (Refs #2509).

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../support/domain_planner_orchestrator_test_support.dart';
import '../support/domain_planner_test_fake_api.dart';

const String kExpandGpOnlyBlockerNationId = kOrchestratorGp1NationId;
const String kExpandGpOnlyBlockerGpId = kOrchestratorBlockerGpId;

const FakeOrderSuggestionAPIForDomainPlannerTests kExpandGpOnlyBlockerEmptyApi =
    FakeOrderSuggestionAPIForDomainPlannerTests(
  work: [],
  build: [],
  move: [],
  research: [],
  navalMove: [],
  navalMission: [],
);

const EconomyPlan kExpandGpOnlyBlockerEconomyPlan = EconomyPlan(
  productionAssignments: [],
  cargoPreference: CargoPreference.none,
);

const AIConfig kExpandGpOnlyBlockerAiConfig = AIConfig(
  leaderId: 'henry',
  personalityId: 'henry',
  hiddenAgendaId: 'merchant',
);

List<String> expandGpOnlyBlockerDeclareWarTargets(Orders orders) => <String>[
  for (final order
      in orders.diplomaticOrdersByPlayerId[kExpandGpOnlyBlockerNationId] ??
          const [])
    if (order.type == DiplomaticOrderType.declareWar) order.targetFactionId,
];
