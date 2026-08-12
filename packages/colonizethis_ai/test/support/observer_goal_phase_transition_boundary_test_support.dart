/// Shared fixtures for observer goal phase transition boundary pins
/// (Refs #2509 / #4310 Slice C).
library;

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'domain_planner_orchestrator_expand_scenarios.dart';
import 'domain_planner_orchestrator_quota_consts.dart';
import 'domain_planner_test_fake_api.dart';
import 'planner_test_helpers.dart';

const String observerGoalPhaseTransitionBoundaryGameId =
    'g-2509-phase-transition-no-hysteresis';

/// Peace + embassy preconditions for `establishOverture(joinEmpire)` candidates.
const List<DiplomacyRelation>
    observerGoalPhaseTransitionBoundaryTribePeaceRelations =
    <DiplomacyRelation>[
  DiplomacyRelation(
    factionId1: kOrchestratorGp1NationId,
    factionId2: kOrchestratorTribeId,
    state: RelationState.atPeace,
    score: 60,
  ),
];

const List<OvertureState> observerGoalPhaseTransitionBoundaryEmbassyOvertures =
    <OvertureState>[
  OvertureState(
    gpId: kOrchestratorGp1NationId,
    targetId: kOrchestratorTribeId,
    stage: OvertureStage.embassy,
  ),
];

Game observerGoalPhaseTransitionBoundaryGameAtQuota() =>
    buildOrchestratorGp1TribeNwScenarioGame(
      id: observerGoalPhaseTransitionBoundaryGameId,
      gp1OwProvinces: kGp1OwProvincesExactQuota,
      diplomacyRelations: observerGoalPhaseTransitionBoundaryTribePeaceRelations,
      overtureStates: observerGoalPhaseTransitionBoundaryEmbassyOvertures,
    );

Game observerGoalPhaseTransitionBoundaryGameJustBelowQuota() =>
    buildOrchestratorGp1TribeNwScenarioGame(
      id: observerGoalPhaseTransitionBoundaryGameId,
      gp1OwProvinces: kGp1OwProvincesColonialLiteNearQuota,
      diplomacyRelations: observerGoalPhaseTransitionBoundaryTribePeaceRelations,
      overtureStates: observerGoalPhaseTransitionBoundaryEmbassyOvertures,
    );

AIWorldSnapshot observerGoalPhaseTransitionBoundaryExpandSnapshot() =>
    buildOrchestratorExpandNwTribeTargetSnapshot(
      oldWorldProvincesOwned: 9,
      provincesToVictory: 22,
      tribePeaceRelationScore: 60,
    );

AIWorldSnapshot observerGoalPhaseTransitionBoundaryColonialSnapshot() =>
    buildOrchestratorColonialNwTribeTargetSnapshot(
      oldWorldProvincesOwned: 10,
      provincesToVictory: 21,
      tribeRelationScore: 60,
    );

const FakeOrderSuggestionAPIForDomainPlannerTests
    observerGoalPhaseTransitionBoundaryNwTribeOvertureApi =
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
      targetFactionId: kOrchestratorTribeId,
      overtureStage: OvertureStage.joinEmpire,
    ),
  ],
);

const EconomyPlan observerGoalPhaseTransitionBoundaryEconomyPlan =
    kTestEconomyPlan;

const AIConfig observerGoalPhaseTransitionBoundaryAiConfig = AIConfig(
  leaderId: 'henry',
  personalityId: 'henry',
  hiddenAgendaId: 'merchant',
);

const MapTopology observerGoalPhaseTransitionBoundaryTopology =
    MapTopology(nodes: [], edges: []);

List<String> observerGoalPhaseTransitionBoundaryOvertureTargets(
  Orders orders,
) =>
    <String>[
      for (final order
          in orders.diplomaticOrdersByPlayerId[kOrchestratorGp1NationId] ??
              const [])
        if (order.type == DiplomaticOrderType.establishOverture)
          order.targetFactionId,
    ];
