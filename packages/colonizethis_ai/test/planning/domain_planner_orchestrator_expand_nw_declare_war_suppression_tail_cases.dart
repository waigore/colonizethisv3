// Pins the EXPAND-phase New World `declareWar` suppression rule from
// issue #2509 at the `runDomainPlanners` integration boundary:
//
//   SPEC/ai/ai-architecture.md § Observer goal phases (Full AI), EXPAND:
//     Suppress: NW `declareWar`/`establishOverture`, NW conquest army moves,
//     NW naval colonial missions, `purchase_land` in `newWorld|`,
//     `build_improvement` on NW tiles, colonial cargo preference.
//
// The scoring-level half of the `declareWar` suppression is pinned in
// `packages/colonizethis_ai/test/observer_goal_phase_test.dart` group
// `EXPAND suppresses NW declareWar scoring` — that test calls
// `computeDiplomaticCandidateScores` directly and asserts the NW tribe
// `declareWar` candidate collapses to `0`. The symmetric **COLONIAL**
// allow-side is pinned in the same file by group
// `COLONIAL allows NW tribe declareWar scoring` (score strictly positive at
// OW quota).
//
// Sibling EXPAND orchestrator-level pins live in
// `domain_planner_orchestrator_expand_nw_overture_suppression_test.dart`
// (`establishOverture` half) and
// `domain_planner_orchestrator_expand_nw_work_suppression_test.dart`
// (NW `purchase_land` / `build_improvement` / NW conquest army moves halves).
// Neither covers the EXPAND `declareWar` suppression at the orchestrator
// integration: a future tuning slice that left the score collapse intact
// (NW tribe `declareWar` score = 0 in EXPAND) but added a parallel forced
// path in `domain_planner_orchestrator.dart` / `diplomacy_planner.dart` that
// surfaced a `declareWar(NW tribe)` directly into merged diplomatic orders
// — for example a colonial-pressure "forced NW war" helper mirroring
// `_defaultStartOwMinorDeclarePlannerResultIfNeeded` — would silently
// violate the EXPAND clause and pull GPs off the OW quota path before
// turn 100, regressing the canonical seed-42 `--verify-conquest` nightly
// gate (`SPEC/program/run_observer_game-tool.md`).
//
// The negative control asserts the same `declareWar` candidate **is**
// emitted in COLONIAL so a regression that over-suppresses NW
// `declareWar` at OW quota (and therefore strips the war + invasion
// acquisition route from § COLONIAL phase — acquisition priority rule 1
// "Join Empire → `purchase_land` → declare-war + NW invasion") is also
// caught at the orchestrator boundary.
//
// Coverage layers:
//   - Positive (EXPAND): merged diplomatic orders do **not** contain
//     `declareWar` toward the NW tribe candidate the fake API provides.
//   - Negative control (COLONIAL): the same `declareWar` candidate **is**
//     emitted by the orchestrator, so the test catches over-suppression
//     in the wrong phase.
//   - Determinism guard (must-have #7): identical EXPAND-phase inputs
//     produce identical diplomatic-order fingerprints.

import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/orchestrator_options.dart';
import 'package:colonizethis_ai/src/planning/observer_goal_phase.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../support/domain_planner_test_fake_api.dart';
import '../support/domain_planner_orchestrator_test_support.dart';

const String _nationId = kOrchestratorGp1NationId;
const String _tribeId = kOrchestratorTribeId;

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
const PhasePriorityWeights _nwAcquisitionZeroExpand = PhasePriorityWeights(
  oldWorldConquest: 0.95,
  newWorldAcquisition: 0.0,
  oldWorldCivilian: 0.90,
  newWorldCivilian: 0.10,
);

const PhasePlanOutcome _expandPhasePlanHardSuppressNw = PhasePlanOutcome(
  phase: ObserverGoalPhase.expand,
  priorityWeights: _nwAcquisitionZeroExpand,
);

// Uses kGp1OwProvincesBelowQuota / kGp1OwProvincesAtQuota from
// domain_planner_orchestrator_test_support.dart (Refs #3941).

// Fake API provides one `declareWar(tribe1)` candidate. The fake's
// `suggestDeclareWarOrders` filters by `type == declareWar`, so the
// `declareWarOnly` pass of `runDiplomacyPlannerWithResult` is the path
// under test for the SPEC EXPAND `declareWar` suppression rule.
const FakeOrderSuggestionAPIForDomainPlannerTests _nwTribeDeclareWarApi =
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
      targetFactionId: _tribeId,
    ),
  ],
);

const EconomyPlan _economyPlan = EconomyPlan(
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
const AIConfig _aiConfig = AIConfig(
  leaderId: 'henry',
  personalityId: 'henry',
  hiddenAgendaId: 'merchant',
);

// Snapshots: buildOrchestratorExpandNwTribeTargetSnapshot /
// buildOrchestratorColonialNwTribeTargetSnapshot (Refs #3997).

List<String> _declareWarTargets(Orders orders) => <String>[
  for (final order
      in orders.diplomaticOrdersByPlayerId[_nationId] ?? const [])
    if (order.type == DiplomaticOrderType.declareWar) order.targetFactionId,
];

void registerDomainPlannerOrchestratorExpandNwDeclareWarSuppressionTailCases() {

  group('runDomainPlanners EXPAND-phase NW declareWar suppression', () {
    test('emits identical diplomatic orders for identical EXPAND inputs', () {
      final game = buildOrchestratorGp1TribeNwScenarioGame(
        id: 'g-2509-expand-nw-declare-suppress',
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
      final view = buildPlayerView(game, topology, _nationId);
      final snapshot = buildOrchestratorExpandNwTribeTargetSnapshot(tribePeaceRelationScore: 0);

      Orders runOnce(int turnSeed) => runDomainPlanners(
        DomainPlannerInput(
          game: game,
          topology: topology,
          nationId: _nationId,
          view: view,
          snapshot: snapshot,
          config: _aiConfig,
          primaryGoal: StrategicGoal.expand,
          seeds: AISeedBundle.fromTurnSeed(turnSeed),
          suggestionAPI: _nwTribeDeclareWarApi,
          economyPlan: _economyPlan,
          options: OrchestratorOptions(phasePlan: _expandPhasePlanHardSuppressNw),
        ),
      );

      final firstRun = runOnce(2509242);
      final secondRun = runOnce(2509242);

      List<String> diplomaticFingerprint(Orders orders) => <String>[
        for (final o
            in orders.diplomaticOrdersByPlayerId[_nationId] ?? const [])
          '${o.type}|${o.targetFactionId}|${o.overtureStage}',
      ];

      expect(
        diplomaticFingerprint(secondRun),
        diplomaticFingerprint(firstRun),
        reason:
            'Determinism (must-have #7): identical EXPAND-phase inputs '
            'must produce identical diplomatic orders across runs '
            '(otherwise a flaky filter or random scoring path could '
            'mask this contract under repeated runs).',
      );
    });
  });
}
