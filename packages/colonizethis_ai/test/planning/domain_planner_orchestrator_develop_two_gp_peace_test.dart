// Pins the DEVELOP-phase Great-Power peace contract from issue #2509 at
// the `runDomainPlanners` integration boundary.
//
// Issue #2509 acceptance criterion (S10 DEVELOP § Peace rules):
//
//   Given a GP in DEVELOP at war with two GPs (and an unrelated minor),
//   when diplomacy peace planning runs, then offerPeace is suggested
//   toward both at-war GPs and not toward the minor (deterministic for
//   fixed seed).
//
// The predicate that produces the DEVELOP GP peace target set is pinned
// at the function level by the `developPhaseGpPeaceTargets` group in
// `packages/colonizethis_ai/test/observer_goal_phase_test.dart`. That
// predicate test does not run the orchestrator, so a future tuning slice
// could leave `developPhaseGpPeaceTargets` intact but bypass the
// orchestrator's call to `_stalledPeacePlannerResultIfNeeded` ->
// `collectStalledGreatPowerPeaceTargets` (or short-circuit through the
// `declareWarOnly` pass) and silently fail to emit `offerPeace` toward
// at-war GPs in DEVELOP — leaving GP-vs-GP wars open and starving the
// improvement-first civilian work that S10 DEVELOP exists to enable, in
// turn threatening the turn-150 `--verify-colonial-expansion` 70%
// extractable-tile improvement gate.
//
// This file is the symmetric DEVELOP counterpart to:
//   - `domain_planner_orchestrator_expand_two_gp_peace_test.dart`
//     (EXPAND peace pin merged via PR #2614)
//   - `domain_planner_orchestrator_colonial_two_gp_peace_test.dart`
//     (COLONIAL peace pin, sibling slice for #2509)
// so the EXPAND/COLONIAL/DEVELOP peace pin trio stays side-by-side
// reviewable at the orchestrator boundary.
//
// SPEC:
//   - `SPEC/ai/ai-architecture.md` § Observer goal phases (Full AI),
//     DEVELOP phase peace rule ("`offerPeace` toward all GP wars unless
//     defending a province with an active improvement worker").
//   - `SPEC/program/order-suggestions.md` § Diplomatic orders.
//
// Coverage layers:
//   - Positive: DEVELOP-phase merged orders contain `offerPeace` toward
//     both at-war GPs.
//   - Negative: DEVELOP-phase merged orders do **not** contain
//     `offerPeace` toward an at-war minor (the DEVELOP peace predicate
//     scopes to GP factions only; minors are pursued through other
//     paths).
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
const String _atWarGpAId = kOrchestratorDevelopTwoGpAtWarGpAId;
const String _atWarGpBId = kOrchestratorDevelopTwoGpAtWarGpBId;
const String _atWarMinorId = kOrchestratorDevelopTwoGpAtWarMinorId;

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

// `peacemaker` agenda keeps personality from suppressing peace candidates;
// matches the EXPAND/COLONIAL two-GP peace pin so the trio exercises the
// same agenda surface and any future agenda regression shows up
// symmetrically across phases.
const AIConfig _aiConfig = AIConfig(
  leaderId: 'victoria',
  personalityId: 'victoria',
  hiddenAgendaId: 'peacemaker',
);

AIWorldSnapshot _developTwoGpWarsSnapshot() {
  return const AIWorldSnapshot(
    playerId: _nationId,
    // Includes the minor explicitly so the negative case proves the
    // DEVELOP peace predicate filters non-GP factions even when present
    // in `threats.atWarWith`.
    threats: ThreatSummary(
      atWarWith: [_atWarGpAId, _atWarGpBId, _atWarMinorId],
    ),
    opportunities: OpportunitySummary(),
    // 11 OW provinces: past quota, so EXPAND is exited. Empty
    // `invadableProvinceIdsSorted` keeps the EXPAND minor-first early
    // return from triggering even if the GP were still below quota.
    conquest: ConquestSummary(
      oldWorldProvincesOwned: 11,
      invadableProvinceIdsSorted: [],
      provincesToVictory: 20,
    ),
    // Empty colonial summary: `hasColonialAcquisitionTargets` is false,
    // routing past COLONIAL into DEVELOP.
    colonial: ColonialSummary(),
    economy: EconomySummary(ownProvinceCount: 11),
    relations: {},
  );
}

List<String> _offerPeaceTargets(Orders orders) => <String>[
  for (final order in orders.diplomaticOrdersByPlayerId[_nationId] ?? const [])
    if (order.type == DiplomaticOrderType.offerPeace) order.targetFactionId,
];

void main() {
  group('runDomainPlanners DEVELOP two-GP peace', () {
    test('peaces both at-war Great Power fronts', () {
      final game = buildOrchestratorDevelopTwoGpWarsScenarioGame();
      const topology = MapTopology(nodes: [], edges: []);
      final view = buildPlayerView(game, topology, _nationId);
      final snapshot = _developTwoGpWarsSnapshot();

      expect(
        observerGoalPhaseFor(snapshot: snapshot, game: game),
        ObserverGoalPhase.develop,
        reason:
            'Fixture must place GP in DEVELOP so the all-GP peace contract '
            'is exercised by the orchestrator (not the EXPAND non-blocker '
            'rule or the COLONIAL colonial-blocker rule, which both have '
            'separate peace target sets).',
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
          seeds: AISeedBundle.fromTurnSeed(2509140),
          suggestionAPI: _emptyApi,
          economyPlan: _economyPlan,
        ),
      );

      final peaceTargets = _offerPeaceTargets(orders);
      expect(
        peaceTargets,
        containsAll(<String>[_atWarGpAId, _atWarGpBId]),
        reason:
            'DEVELOP must emit offerPeace toward every at-war Great Power '
            'so improvement-first civilian work can proceed unblocked '
            '(SPEC § Observer goal phases (Full AI), DEVELOP peace '
            'rules).',
      );
    });

    test('does not peace the at-war minor in DEVELOP', () {
      final game = buildOrchestratorDevelopTwoGpWarsScenarioGame();
      const topology = MapTopology(nodes: [], edges: []);
      final view = buildPlayerView(game, topology, _nationId);
      final snapshot = _developTwoGpWarsSnapshot();

      expect(
        observerGoalPhaseFor(snapshot: snapshot, game: game),
        ObserverGoalPhase.develop,
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
          seeds: AISeedBundle.fromTurnSeed(2509141),
          suggestionAPI: _emptyApi,
          economyPlan: _economyPlan,
        ),
      );

      final peaceTargets = _offerPeaceTargets(orders);
      expect(
        peaceTargets,
        isNot(contains(_atWarMinorId)),
        reason:
            'DEVELOP peace targets are scoped to Great Powers only '
            '(developPhaseGpPeaceTargets filters non-GP factions); '
            'minor-faction peace handling is governed by sibling '
            'rulesets (SPEC § Observer goal phases (Full AI), DEVELOP '
            'peace rules).',
      );
    });

    test('emits identical diplomatic orders for identical inputs', () {
      final game = buildOrchestratorDevelopTwoGpWarsScenarioGame();
      const topology = MapTopology(nodes: [], edges: []);
      final view = buildPlayerView(game, topology, _nationId);
      final snapshot = _developTwoGpWarsSnapshot();

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
          suggestionAPI: _emptyApi,
          economyPlan: _economyPlan,
        ),
      );

      final firstRun = runOnce(2509142);
      final secondRun = runOnce(2509142);

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
            'must produce identical diplomatic orders across runs.',
      );
    });
  });
}
