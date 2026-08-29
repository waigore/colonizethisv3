// Shared fixtures for COLONIAL-lite NW declareWar orchestrator pins (Refs #2509).

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../support/domain_planner_orchestrator_test_support.dart';
import '../support/domain_planner_test_fake_api.dart';

const String kColonialLiteDeclareWarNationId = kOrchestratorGp1NationId;
const String kColonialLiteDeclareWarTribeId = kOrchestratorTribeId;

const FakeOrderSuggestionAPIForDomainPlannerTests kColonialLiteNwTribeDeclareWarApi =
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
      targetFactionId: kColonialLiteDeclareWarTribeId,
    ),
  ],
);

const EconomyPlan kColonialLiteDeclareWarEconomyPlan = EconomyPlan(
  productionAssignments: [],
  cargoPreference: CargoPreference.none,
);

const AIConfig kColonialLiteDeclareWarAiConfig = AIConfig(
  leaderId: 'henry',
  personalityId: 'henry',
  hiddenAgendaId: 'merchant',
);

List<String> colonialLiteDeclareWarTargets(Orders orders) => <String>[
  for (final order
      in orders.diplomaticOrdersByPlayerId[kColonialLiteDeclareWarNationId] ??
          const [])
    if (order.type == DiplomaticOrderType.declareWar) order.targetFactionId,
];
