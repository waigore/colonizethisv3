// Pins the EXPAND-phase two-Great-Power peace contract from issue #2509 at
// the `runDomainPlanners` integration boundary.
//
// Issue #2509 acceptance criterion (S10 EXPAND § Peace rules):
//
//   Given the same GP in EXPAND at war with two GPs where only one owns the
//   primary invadable OW frontier blocker, when diplomacy peace planning
//   runs, then offerPeace is suggested toward the non-blocker GP and not
//   toward the blocker (deterministic for fixed seed).
//
// The predicate that produces the non-blocker target set is pinned at the
// function level by `observerGoalPhaseFor` /
// `expandPhaseGpPeaceTargets` tests in
// `packages/colonizethis_ai/test/observer_goal_phase_test.dart`
// (group `expandPhaseGpPeaceTargets`). Neither of those tests runs the
// orchestrator, so a future tuning slice could leave the predicate intact
// but bypass the orchestrator's call to
// `_stalledPeacePlannerResultIfNeeded` -> `collectStalledGreatPowerPeaceTargets`
// (or short-circuit through the `declareWarOnly` pass) and silently emit no
// `offerPeace` for the non-blocker — or, worse, peace the OW frontier
// blocker and break the EXPAND quota push. This file pins both halves of
// the contract at the `runDomainPlanners` boundary so the merged
// diplomatic-orders output stays SPEC-compliant.
//
// SPEC:
//   - `SPEC/ai/ai-architecture.md` § Observer goal phases (Full AI), EXPAND
//     phase peace rules ("Hold blocker war... peace the non-blocker GP
//     front(s)" / "When at war with two or more GPs: peace all non-blocker
//     GP fronts").
//   - `SPEC/program/order-suggestions.md` § Diplomatic orders.
//
// Coverage layers:
//   - Positive: EXPAND-phase merged orders contain `offerPeace` toward the
//     non-blocker GP.
//   - Negative: EXPAND-phase merged orders do **not** contain `offerPeace`
//     toward the primary invadable OW frontier blocker GP.
//   - Determinism guard: re-running with identical inputs produces an
//     identical diplomatic-order set (must-have #7).

import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/observer_goal_phase.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../support/domain_planner_orchestrator_test_support.dart';
import '../support/domain_planner_test_fake_api.dart';

const String _nationId = kOrchestratorGp1NationId;
const String _blockerGpId = kOrchestratorExpandTwoGpBlockerId;
const String _nonBlockerGpId = kOrchestratorExpandTwoGpNonBlockerId;

const FakeOrderSuggestionAPIForDomainPlannerTests _emptyApi =
    FakeOrderSuggestionAPIForDomainPlannerTests(
  work: [],
  build: [],
  move: [],
  research: [],
  navalMove: [],
  navalMission: [],
);

const EconomyPlan _economyPlan = EconomyPlan(
  productionAssignments: [],
  cargoPreference: CargoPreference.none,
);

const AIConfig _aiConfig = AIConfig(
  leaderId: 'victoria',
  personalityId: 'victoria',
  hiddenAgendaId: 'peacemaker',
);

AIWorldSnapshot _expandTwoGpWarsSnapshot() {
  return const AIWorldSnapshot(
    playerId: _nationId,
    threats: ThreatSummary(atWarWith: [_blockerGpId, _nonBlockerGpId]),
    opportunities: OpportunitySummary(),
    // 8 OW provinces -> EXPAND phase; invadable list is exactly the
    // blocker's three provinces, so `primaryInvadableOldWorldGpBlocker`
    // resolves to `_blockerGpId` and `isOldWorldGpOnlyInvadableFrontier`
    // is true (no minor owns any invadable province).
    conquest: ConquestSummary(
      oldWorldProvincesOwned: 8,
      invadableProvinceIdsSorted: kOrchestratorExpandTwoGpBlockerInvadableProvinces,
      provincesToVictory: 24,
    ),
    colonial: ColonialSummary(),
    economy: EconomySummary(ownProvinceCount: 8),
    relations: {},
  );
}

List<String> _offerPeaceTargets(Orders orders) => <String>[
  for (final order in orders.diplomaticOrdersByPlayerId[_nationId] ?? const [])
    if (order.type == DiplomaticOrderType.offerPeace) order.targetFactionId,
];

void main() {
  group('runDomainPlanners EXPAND two-GP peace', () {
    test('peaces the non-blocker GP front', () {
      final game = buildOrchestratorExpandTwoGpWarsScenarioGame();
      const topology = MapTopology(nodes: [], edges: []);
      final view = buildPlayerView(game, topology, _nationId);
      final snapshot = _expandTwoGpWarsSnapshot();

      expect(
        observerGoalPhaseFor(snapshot: snapshot, game: game),
        ObserverGoalPhase.expand,
        reason:
            'Fixture must place GP in EXPAND so the two-GP peace contract '
            'is exercised by the orchestrator (not the COLONIAL/DEVELOP '
            'fall-through, which has separate peace targets).',
      );

      final orders = runDomainPlanners(
        DomainPlannerInput(
          game: game,
          topology: topology,
          nationId: _nationId,
          view: view,
          snapshot: snapshot,
          config: _aiConfig,
          primaryGoal: StrategicGoal.expand,
          seeds: AISeedBundle.fromTurnSeed(2509042),
          suggestionAPI: _emptyApi,
          economyPlan: _economyPlan,
        ),
      );

      final peaceTargets = _offerPeaceTargets(orders);
      expect(
        peaceTargets,
        contains(_nonBlockerGpId),
        reason:
            'EXPAND with two GP wars must emit offerPeace toward the '
            'non-blocker GP front (SPEC § Observer goal phases (Full AI), '
            'EXPAND peace rules).',
      );
    });

    test('holds the primary invadable OW frontier blocker war', () {
      final game = buildOrchestratorExpandTwoGpWarsScenarioGame();
      const topology = MapTopology(nodes: [], edges: []);
      final view = buildPlayerView(game, topology, _nationId);
      final snapshot = _expandTwoGpWarsSnapshot();

      expect(
        observerGoalPhaseFor(snapshot: snapshot, game: game),
        ObserverGoalPhase.expand,
      );

      final orders = runDomainPlanners(
        DomainPlannerInput(
          game: game,
          topology: topology,
          nationId: _nationId,
          view: view,
          snapshot: snapshot,
          config: _aiConfig,
          primaryGoal: StrategicGoal.expand,
          seeds: AISeedBundle.fromTurnSeed(2509043),
          suggestionAPI: _emptyApi,
          economyPlan: _economyPlan,
        ),
      );

      final peaceTargets = _offerPeaceTargets(orders);
      expect(
        peaceTargets,
        isNot(contains(_blockerGpId)),
        reason:
            'EXPAND must not peace the primary invadable OW frontier '
            'blocker GP while still below quota: that war is the only path '
            'to the +3-province turn-100 gate (SPEC § Observer goal phases '
            '(Full AI), EXPAND peace rules).',
      );
    });

    test('emits identical diplomatic orders for identical inputs', () {
      final game = buildOrchestratorExpandTwoGpWarsScenarioGame();
      const topology = MapTopology(nodes: [], edges: []);
      final view = buildPlayerView(game, topology, _nationId);
      final snapshot = _expandTwoGpWarsSnapshot();

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
          suggestionAPI: _emptyApi,
          economyPlan: _economyPlan,
        ),
      );

      final firstRun = runOnce(2509044);
      final secondRun = runOnce(2509044);

      List<String> diplomaticFingerprint(Orders orders) => <String>[
        for (final o
            in orders.diplomaticOrdersByPlayerId[_nationId] ?? const [])
          '${o.type}|${o.targetFactionId}|${o.overtureStage}',
      ];

      expect(
        diplomaticFingerprint(secondRun),
        diplomaticFingerprint(firstRun),
        reason:
            'Determinism (must-have #7): identical EXPAND-phase inputs must '
            'produce identical diplomatic orders across runs.',
      );
    });
  });
}
