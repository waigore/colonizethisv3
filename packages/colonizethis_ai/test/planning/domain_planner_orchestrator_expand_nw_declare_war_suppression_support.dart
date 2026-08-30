// Shared fixtures for EXPAND-phase NW declareWar orchestrator suppression pins
// (Refs #2509 / #4669 Slice D densify).

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../support/domain_planner_test_fake_api.dart';
import '../support/domain_planner_orchestrator_test_support.dart';

const String kExpandNwDeclareWarSuppressionNationId = kOrchestratorGp1NationId;
const String kExpandNwDeclareWarSuppressionTribeId = kOrchestratorTribeId;

// Explicit NW-acquisition-zero phase plan emulating the legacy
// hard-suppress contract for EXPAND-phase regression assertions
// (Refs #2847 Phase 3 — soft-weight migration). The production
// `_curveWeightsForOw(7)` curve emits `newWorldAcquisition = 0.05`
// (early-sprint plateau), which scoring-side migration in
// `_declareWarSuppressedExpandColonialScore` treats as
// "reachable at low priority" — see the PR's
// `phase_planner_diplomacy_declare_war_nw_suppression_test.dart`.
// Tests that pin the strict hard-suppress regression contract
// thread this explicit override through the orchestrator so
// `nwAcquisitionWeight == 0.0` collapses NW colonial declare-war
// candidates. SPEC § Observer goal phases (Full AI), EXPAND
// suppressions: "NW declareWar/establishOverture..." remains the
// effective contract under this override.
const PhasePriorityWeights kNwAcquisitionZeroExpand = PhasePriorityWeights(
  oldWorldConquest: 0.95,
  newWorldAcquisition: 0.0,
  oldWorldCivilian: 0.90,
  newWorldCivilian: 0.10,
);

const PhasePlanOutcome kExpandPhasePlanHardSuppressNw = PhasePlanOutcome(
  phase: ObserverGoalPhase.expand,
  priorityWeights: kNwAcquisitionZeroExpand,
);

// Fake API provides one `declareWar(tribe1)` candidate. The fake's
// `suggestDeclareWarOrders` filters by `type == declareWar`, so the
// `declareWarOnly` pass of `runDiplomacyPlannerWithResult` is the path
// under test for the SPEC EXPAND `declareWar` suppression rule.
const FakeOrderSuggestionAPIForDomainPlannerTests kNwTribeDeclareWarApi =
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
      targetFactionId: kExpandNwDeclareWarSuppressionTribeId,
    ),
  ],
);

const EconomyPlan kExpandNwDeclareWarSuppressionEconomyPlan = EconomyPlan(
  productionAssignments: [],
  cargoPreference: CargoPreference.none,
);

// `henry` + `merchant` matches the personality/agenda used by the
// scoring-level `EXPAND suppresses NW declareWar scoring` and
// `COLONIAL allows NW tribe declareWar scoring` groups in
// `observer_goal_phase_test.dart`. `peacemaker` is intentionally avoided
// here because that agenda zeroes declare-war candidates regardless of
// phase and would confound both the EXPAND positive (already-zero score)
// and the COLONIAL negative control.
const AIConfig kExpandNwDeclareWarSuppressionAiConfig = AIConfig(
  leaderId: 'henry',
  personalityId: 'henry',
  hiddenAgendaId: 'merchant',
);

List<String> expandNwDeclareWarSuppressionTargets(Orders orders) => <String>[
  for (final order
      in orders.diplomaticOrdersByPlayerId[kExpandNwDeclareWarSuppressionNationId] ??
          const [])
    if (order.type == DiplomaticOrderType.declareWar) order.targetFactionId,
];
