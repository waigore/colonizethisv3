// Pins the DEVELOP-phase `declareWar` suppression AC from issue #2509 at the
// `runDomainPlanners` integration boundary:
//
//   SPEC/ai/ai-architecture.md § Observer goal phases (Full AI), DEVELOP:
//     Suppress: new `declareWar`, NW acquisition orders, OW GP-vs-GP wars,
//     colonial cargo preference for new objectives.
//
// The scoring-level half of this contract is pinned in
// `packages/colonizethis_ai/test/observer_goal_phase_test.dart`
// (group `DEVELOP suppresses declareWar` — score collapses to
// `kDeclareWarNonAdjacentSuppressedScore`). That predicate test does not
// run the orchestrator, so a future tuning slice could leave the scoring
// intact (declare-war score = 0 in DEVELOP) but add a parallel path in
// `domain_planner_orchestrator.dart` / `diplomacy_planner.dart` that
// surfaces a forced declare-war candidate directly into merged diplomatic
// orders (for example a "DEVELOP defensive declare" short-circuit helper
// mirroring `_defaultStartOwMinorDeclarePlannerResultIfNeeded`). That
// regression would re-open GP-vs-GP and tribe wars in the turn-≥120
// improvement-first horizon and starve the `build_improvement` civilian
// work that DEVELOP exists to enable, threatening the turn-150
// `--verify-colonial-expansion` 70% extractable-tile gate.
//
// The negative control asserts the same declare-war candidate **is**
// emitted in COLONIAL (where SPEC § COLONIAL declare-war/overture rule
// allows wars against tribes owning sea-reachable NW provinces) so a
// regression that over-suppresses declare-war in COLONIAL — stripping
// the conquest acquisition route from § COLONIAL phase minimum rule 1 —
// is also caught.
//
// Coverage layers:
//   - Positive (DEVELOP): merged diplomatic orders do **not** contain
//     `declareWar` toward the tribe the fake API provides.
//   - Negative control (COLONIAL): the same declare-war candidate **is**
//     emitted by the orchestrator, so the test catches over-suppression
//     in the wrong phase.
//   - Determinism guard (must-have #7): identical DEVELOP-phase inputs
//     produce identical diplomatic-order fingerprints.

import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/observer_goal_phase.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../support/domain_planner_test_fake_api.dart';
import '../support/domain_planner_orchestrator_test_support.dart';

const String _nationId = kOrchestratorGp1NationId;
const String _tribeId = kOrchestratorTribeId;

// Fake API surfaces one `declareWar(tribe1)` candidate via
// `suggestDeclareWarOrders` — the path under test for the SPEC DEVELOP
// `declareWar` suppression rule. The candidate is the same in both phases
// so the contrast isolates the orchestrator's phase-driven filter rather
// than candidate availability.
const FakeOrderSuggestionAPIForDomainPlannerTests _tribeDeclareWarApi =
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
// COLONIAL scoring tests in `observer_goal_phase_test.dart`
// (`COLONIAL allows NW tribe declareWar scoring` and
// `COLONIAL personality colonial acquisition`) and the sibling
// orchestrator-level COLONIAL tribe declareWar pin
// (`domain_planner_orchestrator_colonial_tribe_declare_war_test.dart`,
// PR #2616). The `peacemaker` agenda zeroes declare-war candidates
// regardless of phase, so it would not exercise the COLONIAL emission
// half of the contract this file pins as a control.
const AIConfig _aiConfig = AIConfig(
  leaderId: 'henry',
  personalityId: 'henry',
  hiddenAgendaId: 'merchant',
);

List<String> _declareWarTargets(Orders orders) => <String>[
  for (final order
      in orders.diplomaticOrdersByPlayerId[_nationId] ?? const [])
    if (order.type == DiplomaticOrderType.declareWar)
      order.targetFactionId,
];

void main() {
  group('runDomainPlanners DEVELOP-phase declareWar suppression', () {
    test('DEVELOP drops declareWar toward at-war tribe candidate', () {
      final game = buildOrchestratorDevelopGpOwnedNwScenarioGame(
        id: 'g-2509-develop-declare-war-suppress',
      );
      const topology = MapTopology(nodes: [], edges: []);
      final view = buildPlayerView(game, topology, _nationId);
      final snapshot = buildOrchestratorDevelopNoColonialTargetsSnapshot(
        atWarWith: const [_tribeId],
        tribeRelationScore: 10,
      );

      expect(
        observerGoalPhaseFor(snapshot: snapshot, game: game),
        ObserverGoalPhase.develop,
        reason:
            'Fixture must place GP in DEVELOP so the declareWar '
            'suppression contract is exercised by the orchestrator, not '
            'the COLONIAL fall-through (which has separate rules that '
            'allow tribe declare-war for NW acquisition).',
      );

      final orders = runDomainPlanners(
        DomainPlannerInput(
          game: game,
          topology: topology,
          nationId: _nationId,
          view: view,
          snapshot: snapshot,
          config: _aiConfig,
          primaryGoal: StrategicGoal.diplomacy,
          seeds: AISeedBundle.fromTurnSeed(2509330),
          suggestionAPI: _tribeDeclareWarApi,
          economyPlan: _economyPlan,
        ),
      );

      expect(
        _declareWarTargets(orders),
        isNot(contains(_tribeId)),
        reason:
            'DEVELOP must drop new declareWar candidates so '
            'improvement-first civilian work toward the turn-150 70% '
            'extractable-tile gate is not destabilised by re-opening '
            'wars (SPEC § Observer goal phases (Full AI), DEVELOP '
            'suppressions: "new declareWar, NW acquisition orders, OW '
            'GP-vs-GP wars..."). A non-empty contains list here '
            'indicates the orchestrator surfaced a declare-war the '
            'scoring path collapsed to '
            'kDeclareWarNonAdjacentSuppressedScore — most likely a '
            'forced/short-circuit declare-war helper bypassing the '
            'score gate.',
      );
    });

    test(
      'COLONIAL allows declareWar toward the same at-war tribe candidate',
      () {
        final game = buildOrchestratorGp1TribeNwScenarioGame(
          id: 'g-2509-develop-declare-war-suppress-colonial-control',
          gp1OwProvinces: kGp1OwProvincesAtQuota,
          turnNumber: 130,
        );
        const topology = MapTopology(nodes: [], edges: []);
        final view = buildPlayerView(game, topology, _nationId);
        final snapshot = buildOrchestratorColonialNwTribeTargetSnapshot(
          atWarWith: const [_tribeId],
          tribeRelationScore: 10,
          tribeRelationState: RelationState.atWar,
        );

        expect(
          observerGoalPhaseFor(snapshot: snapshot, game: game),
          ObserverGoalPhase.colonial,
          reason:
              'Negative-control fixture must place GP in COLONIAL so '
              'the DEVELOP declareWar filter is verified to **not** '
              'fire here. Otherwise a regression that over-suppresses '
              'declareWar in COLONIAL (stripping the conquest '
              'acquisition route from SPEC § COLONIAL phase minimum '
              'rule 1) would also pass the positive case.',
        );

        final orders = runDomainPlanners(
          DomainPlannerInput(
            game: game,
            topology: topology,
            nationId: _nationId,
            view: view,
            snapshot: snapshot,
            config: _aiConfig,
            primaryGoal: StrategicGoal.conquer,
            seeds: AISeedBundle.fromTurnSeed(2509331),
            suggestionAPI: _tribeDeclareWarApi,
            economyPlan: _economyPlan,
          ),
        );

        expect(
          _declareWarTargets(orders),
          contains(_tribeId),
          reason:
              'COLONIAL must allow declareWar toward visible tribe '
              'owners of sea-reachable unowned NW provinces so the '
              'conquest acquisition path remains reachable toward the '
              'turn-150 NW ownership gate (SPEC § COLONIAL phase, '
              'declare-war / overture rule).',
        );
      },
    );

    test('emits identical diplomatic orders for identical DEVELOP inputs', () {
      final game = buildOrchestratorDevelopGpOwnedNwScenarioGame(
        id: 'g-2509-develop-declare-war-suppress',
      );
      const topology = MapTopology(nodes: [], edges: []);
      final view = buildPlayerView(game, topology, _nationId);
      final snapshot = buildOrchestratorDevelopNoColonialTargetsSnapshot(
        atWarWith: const [_tribeId],
        tribeRelationScore: 10,
      );

      Orders runOnce(int turnSeed) => runDomainPlanners(
        DomainPlannerInput(
          game: game,
          topology: topology,
          nationId: _nationId,
          view: view,
          snapshot: snapshot,
          config: _aiConfig,
          primaryGoal: StrategicGoal.diplomacy,
          seeds: AISeedBundle.fromTurnSeed(turnSeed),
          suggestionAPI: _tribeDeclareWarApi,
          economyPlan: _economyPlan,
        ),
      );

      final firstRun = runOnce(2509332);
      final secondRun = runOnce(2509332);

      List<String> diplomaticFingerprint(Orders orders) => <String>[
        for (final o
            in orders.diplomaticOrdersByPlayerId[_nationId] ?? const [])
          '${o.type}|${o.targetFactionId}|${o.overtureStage}',
      ];

      expect(
        diplomaticFingerprint(secondRun),
        diplomaticFingerprint(firstRun),
        reason:
            'Determinism (must-have #7): identical DEVELOP-phase inputs '
            'must produce identical diplomatic orders across runs '
            '(otherwise a flaky filter or random scoring path could '
            'mask this contract under repeated runs).',
      );
    });
  });
}
