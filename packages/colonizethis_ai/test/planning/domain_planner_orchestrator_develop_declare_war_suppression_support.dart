// Shared fixtures for DEVELOP-phase declareWar suppression orchestrator pins.

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../support/domain_planner_test_fake_api.dart';
import '../support/domain_planner_orchestrator_test_support.dart';

const String kDevelopDeclareWarSuppressNationId = kOrchestratorGp1NationId;
const String kDevelopDeclareWarSuppressTribeId = kOrchestratorTribeId;

const FakeOrderSuggestionAPIForDomainPlannerTests
    kDevelopDeclareWarSuppressTribeDeclareWarApi =
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
      targetFactionId: kDevelopDeclareWarSuppressTribeId,
    ),
  ],
);

const EconomyPlan kDevelopDeclareWarSuppressEconomyPlan = EconomyPlan(
  productionAssignments: [],
  cargoPreference: CargoPreference.none,
);

const AIConfig kDevelopDeclareWarSuppressAiConfig = AIConfig(
  leaderId: 'henry',
  personalityId: 'henry',
  hiddenAgendaId: 'merchant',
);

List<String> declareWarTargetsForNation(Orders orders, String nationId) =>
    <String>[
      for (final order in orders.diplomaticOrdersByPlayerId[nationId] ?? const [])
        if (order.type == DiplomaticOrderType.declareWar)
          order.targetFactionId,
    ];

List<String> diplomaticFingerprintForNation(Orders orders, String nationId) =>
    <String>[
      for (final o in orders.diplomaticOrdersByPlayerId[nationId] ?? const [])
        '${o.type}|${o.targetFactionId}|${o.overtureStage}',
    ];
