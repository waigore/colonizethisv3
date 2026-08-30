// Shared fixtures for EXPAND NW overture suppression orchestrator pins (Refs #2509 / #4669).

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../support/domain_planner_test_fake_api.dart';
import '../support/domain_planner_orchestrator_test_support.dart';

const String kExpandNwOvertureSuppressNationId = kOrchestratorGp1NationId;
const String kExpandNwOvertureSuppressTribeId = kOrchestratorTribeId;

const FakeOrderSuggestionAPIForDomainPlannerTests kExpandNwTribeOvertureApi =
    FakeOrderSuggestionAPIForDomainPlannerTests(
  work: [],
  build: [],
  move: [],
  research: [],
  navalMove: [],
  navalMission: [],
  diplomatic: [
    DiplomaticOrder(
      type: DiplomaticOrderType.establishOverture,
      targetFactionId: kExpandNwOvertureSuppressTribeId,
      overtureStage: OvertureStage.joinEmpire,
    ),
  ],
);

const EconomyPlan kExpandNwOvertureSuppressEconomyPlan = EconomyPlan(
  productionAssignments: [],
  cargoPreference: CargoPreference.none,
);

const AIConfig kExpandNwOvertureSuppressAiConfig = AIConfig(
  leaderId: 'henry',
  personalityId: 'henry',
  hiddenAgendaId: 'merchant',
);

List<String> expandNwOvertureTargets(Orders orders) => <String>[
  for (final order
      in orders.diplomaticOrdersByPlayerId[kExpandNwOvertureSuppressNationId] ??
          const [])
    if (order.type == DiplomaticOrderType.establishOverture)
      order.targetFactionId,
];

Game buildExpandNwOvertureSuppressScenarioGame({
  required List<String> gp1OwProvinces,
  required List<DiplomacyRelation> diplomacyRelations,
  required List<OvertureState> overtureStates,
}) {
  return buildOrchestratorGp1TribeNwScenarioGame(
    id: 'g-2509-expand-nw-overture-suppress',
    gp1OwProvinces: gp1OwProvinces,
    diplomacyRelations: diplomacyRelations,
    overtureStates: overtureStates,
  );
}

const List<DiplomacyRelation> kExpandNwOvertureTribePeaceRelations =
    <DiplomacyRelation>[
  DiplomacyRelation(
    factionId1: kOrchestratorGp1NationId,
    factionId2: kOrchestratorTribeId,
    state: RelationState.atPeace,
    score: 60,
  ),
];

const List<OvertureState> kExpandNwOvertureEmbassyStage = <OvertureState>[
  OvertureState(
    gpId: kOrchestratorGp1NationId,
    targetId: kOrchestratorTribeId,
    stage: OvertureStage.embassy,
  ),
];
