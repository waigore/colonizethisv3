// Shared fixtures for EXPAND-phase NW lock-recovery acquisition pins (Refs #4669 Slice D).

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/orchestrator_options.dart';
import 'package:colonizethis_ai/src/planning/observer_goal_phase.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import '../support/domain_planner_test_fake_api.dart';
import '../support/domain_planner_orchestrator_test_support.dart';

const String kNwLockRecoveryNationId = kOrchestratorGp1NationId;
const String kNwLockRecoveryTribeId = kOrchestratorTribeId;
const String kNwLockRecoveryTribeNwProvince = kOrchestratorTribeNwProvince;

const PhasePriorityWeights kNwAcquisitionLockFloorExpand = PhasePriorityWeights(
  oldWorldConquest: 0.95,
  newWorldAcquisition: kPhasePriorityNwTreasuryRecoveryFloor,
  oldWorldCivilian: 0.90,
  newWorldCivilian: 0.10,
);

const PhasePlanOutcome kExpandPhasePlanLockFloorNw = PhasePlanOutcome(
  phase: ObserverGoalPhase.expand,
  priorityWeights: kNwAcquisitionLockFloorExpand,
);

const PhasePriorityWeights kNwAcquisitionZeroExpand = PhasePriorityWeights(
  oldWorldConquest: 0.95,
  newWorldAcquisition: 0.0,
  oldWorldCivilian: 0.90,
  newWorldCivilian: 0.10,
);

const PhasePlanOutcome kExpandPhasePlanZeroNw = PhasePlanOutcome(
  phase: ObserverGoalPhase.expand,
  priorityWeights: kNwAcquisitionZeroExpand,
);

const FakeOrderSuggestionAPIForDomainPlannerTests kNwLockRecoveryTribeDeclareWarApi =
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
      targetFactionId: kNwLockRecoveryTribeId,
    ),
  ],
);

const EconomyPlan kNwLockRecoveryEconomyPlan = EconomyPlan(
  productionAssignments: [],
  cargoPreference: CargoPreference.none,
);

const AIConfig kNwLockRecoveryAiConfig = AIConfig(
  leaderId: 'henry',
  personalityId: 'henry',
  hiddenAgendaId: 'merchant',
);

AIWorldSnapshot expandNwLockRecoverySnapshot() {
  return const AIWorldSnapshot(
    playerId: kNwLockRecoveryNationId,
    threats: ThreatSummary(),
    opportunities: OpportunitySummary(),
    conquest: ConquestSummary(
      oldWorldProvincesOwned: 7,
      provincesToVictory: 24,
    ),
    colonial: ColonialSummary(
      newWorldProvincesOwned: 0,
      invadableNewWorldProvinceIdsSorted: [kNwLockRecoveryTribeNwProvince],
      adjacentNewWorldOwnerFactionIdsSorted: [kNwLockRecoveryTribeId],
      preferredColonialTargetFactionIdsSorted: [kNwLockRecoveryTribeId],
    ),
    economy: EconomySummary(ownProvinceCount: 7, treasury: 0),
    relations: {
      kNwLockRecoveryTribeId: DiplomacyRelation(
        factionId1: kNwLockRecoveryNationId,
        factionId2: kNwLockRecoveryTribeId,
        state: RelationState.atPeace,
        score: 0,
      ),
    },
  );
}

List<String> nwLockRecoveryDeclareWarTargets(Orders orders) => <String>[
  for (final order
      in orders.diplomaticOrdersByPlayerId[kNwLockRecoveryNationId] ?? const [])
    if (order.type == DiplomaticOrderType.declareWar) order.targetFactionId,
];

Orders runNwLockRecoveryOrchestrator({
  required PhasePlanOutcome phasePlan,
  required int turnSeed,
}) {
  final game = buildOrchestratorGp1TribeNwScenarioGame(
    id: 'g-2924-expand-nw-lock-recovery-acquisition',
    gp1OwProvinces: kGp1OwProvincesBelowQuota,
    diplomacyRelations: const <DiplomacyRelation>[
      DiplomacyRelation(
        factionId1: kOrchestratorGp1NationId,
        factionId2: kOrchestratorTribeId,
        state: RelationState.atPeace,
        score: 0,
      ),
    ],
  );
  const topology = MapTopology(nodes: [], edges: []);
  final view = buildPlayerView(game, topology, kNwLockRecoveryNationId);
  final snapshot = expandNwLockRecoverySnapshot();

  expect(
    observerGoalPhaseFor(snapshot: snapshot, game: game),
    ObserverGoalPhase.expand,
    reason:
        'Fixture must place GP in EXPAND so the lock-floor NW '
        'acquisition contract is exercised by the orchestrator.',
  );

  return runDomainPlanners(
    DomainPlannerInput(
      game: game,
      topology: topology,
      nationId: kNwLockRecoveryNationId,
      view: view,
      snapshot: snapshot,
      config: kNwLockRecoveryAiConfig,
      primaryGoal: StrategicGoal.expand,
      seeds: AISeedBundle.fromTurnSeed(turnSeed),
      suggestionAPI: kNwLockRecoveryTribeDeclareWarApi,
      economyPlan: kNwLockRecoveryEconomyPlan,
      options: OrchestratorOptions(phasePlan: phasePlan),
    ),
  );
}
