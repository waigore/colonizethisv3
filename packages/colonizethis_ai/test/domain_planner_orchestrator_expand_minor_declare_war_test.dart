// Pins the EXPAND-phase adjacent invadable minor `declareWar` AC from issue
// #2509 at the `runDomainPlanners` integration boundary:
//
//   Given a GP with `oldWorldProvincesOwned < 10` and an adjacent minor
//   owning a province in `invadableProvinceIdsSorted`, when the declare-war
//   pass runs in EXPAND phase, then `declareWar` toward that minor is among
//   suggested orders (deterministic for fixed seed).
//
// The scoring-level half of this contract is pinned in
// `packages/colonizethis_ai/test/observer_goal_phase_test.dart`
// (group `EXPAND allows OW minor declareWar scoring`, PR #2604 — the
// adjacent invadable minor candidate scores strictly positive while below
// OW quota). The candidate-emission contract for `suggestDeclareWarOrders`
// itself is pinned at the logic layer
// (`packages/colonizethis_logic/test/order_suggestion_colonial_acquisition_join_empire_or_war_test.dart`,
// PR #2603). Neither runs the orchestrator, so a future tuning slice could
// leave both the suggestion API and the predicate scoring intact while
// bypassing the orchestrator's integration of those scores into merged
// diplomatic orders (for example by narrowing the
// `_defaultStartOwMinorDeclarePlannerResultIfNeeded` short-circuit gate in
// `diplomacy_planner.dart` so the EXPAND forced minor declare drops out,
// or by widening a phase-level suppression filter that silently zeroes
// adjacent invadable OW minor declare-war candidates below quota). That
// regression would starve EXPAND OW expansion and directly threaten the
// turn-100 `--verify-conquest` per-GP ≥3 net OW gain gate that the
// nightly observer pipeline enforces (`SPEC/program/run_observer_game-tool.md`).
//
// This file is the EXPAND orchestrator-level counterpart to:
//   - `domain_planner_orchestrator_colonial_tribe_declare_war_test.dart`
//     (COLONIAL tribe declare-war orchestrator pin, sibling slice for
//     #2509 — PR #2616) so the EXPAND/COLONIAL declare-war orchestrator
//     pin pair stays side-by-side reviewable for AC ai-S10-1 and
//     ai-S10-5.
//
// SPEC:
//   - `SPEC/ai/ai-architecture.md` § Observer goal phases (Full AI),
//     EXPAND phase declare-war priority order (a) "adjacent minor owners
//     of invadable provinces".
//   - `SPEC/program/order-suggestions.md` § Diplomatic orders.
//
// Coverage layers:
//   - Positive: EXPAND-phase merged diplomatic orders contain
//     `declareWar` toward the adjacent invadable OW minor surfaced by the
//     suggestion API.
//   - Negative: DEVELOP-phase merged diplomatic orders do **not** contain
//     `declareWar` toward the same minor — DEVELOP zeroes every
//     declare-war candidate per `SPEC/ai/ai-architecture.md` § Observer
//     goal phases (Full AI), DEVELOP. This catches a regression that
//     would re-emit minor declare-war past the OW quota and burn turns
//     that should be servicing the turn-150 70% improvement gate.
//   - Determinism guard: re-running with identical EXPAND inputs produces
//     an identical diplomatic-order fingerprint (must-have #7).

import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/observer_goal_phase.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'domain_planner_test_fake_api.dart';

const String _nationId = 'gp1';
const String _minorId = 'minor1';
const String _minorOwProvince = 'oldWorld|minor1_0';

// Sub-quota OW set (< `kObserverConquestMinOwProvincesPerGp` = 10) so
// `isBelowObserverConquestQuota` is true and `observerGoalPhaseFor`
// returns EXPAND. Sized at the observer default start
// (`kObserverDefaultStartOldWorldProvincesPerGp` = 7) so the
// `_defaultStartOwMinorDeclarePlannerResultIfNeeded` short-circuit is in
// scope (`ownOw <= kObserverDefaultStartOldWorldProvincesPerGp + 1`).
const List<String> _gp1OwProvincesBelowQuota = <String>[
  'oldWorld|gp1_0',
  'oldWorld|gp1_1',
  'oldWorld|gp1_2',
  'oldWorld|gp1_3',
  'oldWorld|gp1_4',
  'oldWorld|gp1_5',
  'oldWorld|gp1_6',
];

// Past-quota OW set (>= `kObserverConquestMinOwProvincesPerGp` = 10) and
// large enough that `oldWorldProvincesOwned` exits both EXPAND and the
// turn-120 COLONIAL-lite safeguard window. Combined with an empty
// `ColonialSummary` it routes `observerGoalPhaseFor` into DEVELOP, where
// every declare-war candidate score collapses to
// `kDeclareWarNonAdjacentSuppressedScore` (verified in
// `observer_goal_phase_test.dart` group `DEVELOP suppresses declareWar`).
const List<String> _gp1OwProvincesDevelop = <String>[
  'oldWorld|gp1_0',
  'oldWorld|gp1_1',
  'oldWorld|gp1_2',
  'oldWorld|gp1_3',
  'oldWorld|gp1_4',
  'oldWorld|gp1_5',
  'oldWorld|gp1_6',
  'oldWorld|gp1_7',
  'oldWorld|gp1_8',
  'oldWorld|gp1_9',
  'oldWorld|gp1_10',
  'oldWorld|gp1_11',
];

Game _scenarioGame({required List<String> gp1OwProvinces}) {
  return Game(
    id: 'g-2509-expand-minor-declare-war',
    worldState: WorldState(
      // Turn 20 sits inside the EXPAND fixture window for the positive
      // case; the DEVELOP fixture overrides via `_developSnapshot` and
      // the helper builds the same turn so the only phase signal that
      // varies is OW holdings size.
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 20),
      oldWorld: RegionData(
        provinces: [
          for (final id in gp1OwProvinces)
            Province(id: id, regionId: 'oldWorld', ownerId: _nationId),
          const Province(
            id: _minorOwProvince,
            regionId: 'oldWorld',
            ownerId: _minorId,
          ),
        ],
      ),
      newWorld: const RegionData(),
      // Non-empty Home Army for gp1 keeps `regimentCountForPlayer` > 0
      // and avoids the zero-regiment stalemate peace paths that would
      // suppress declare-war scoring for unrelated reasons. Mirrors the
      // home-army guard used in the COLONIAL tribe declare-war pin
      // (`domain_planner_orchestrator_colonial_tribe_declare_war_test.dart`).
      armies: [
        Army(
          id: homeArmyIdFor(_nationId),
          ownerId: _nationId,
          regionId: 'oldWorld',
          stationedProvinceId: gp1OwProvinces.first,
          regimentUnitIds: const ['u_gp1'],
          isHomeArmy: true,
        ),
      ],
    ),
    players: const [
      Player(
        id: _nationId,
        displayName: 'GP1',
        isHuman: false,
        leaderKey: 'henry',
      ),
    ],
    tribes: const [],
    minorNations: const [
      MinorNation(id: _minorId, displayName: 'Minor1'),
    ],
  );
}

// Fake API surfaces declareWar toward minor1 so the orchestrator has a
// candidate to score and merge. The same suggestion shape is replayed in
// the DEVELOP negative-control test so the test isolates phase-driven
// suppression, not candidate availability.
const FakeOrderSuggestionAPIForDomainPlannerTests _minorDeclareWarApi =
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
      targetFactionId: _minorId,
    ),
  ],
);

const EconomyPlan _economyPlan = EconomyPlan(
  productionAssignments: [],
  cargoPreference: CargoPreference.none,
);

// `henry` / `merchant` matches the EXPAND scoring-level pin in
// `observer_goal_phase_test.dart` (group `EXPAND allows OW minor
// declareWar scoring`). The `peacemaker` agenda would zero declare-war
// candidates regardless of phase via the agenda conquer modifier and
// suppress the EXPAND emission contract, so it would not exercise the
// orchestrator path this file pins. The same config is reused in the
// DEVELOP negative control so the only varying axis between positive
// and negative cases is the observer goal phase.
const AIConfig _aiConfig = AIConfig(
  leaderId: 'henry',
  personalityId: 'henry',
  hiddenAgendaId: 'merchant',
);

AIWorldSnapshot _expandSnapshot() {
  return const AIWorldSnapshot(
    playerId: _nationId,
    threats: ThreatSummary(),
    opportunities: OpportunitySummary(),
    // 7 OW provinces -> EXPAND (`isBelowObserverConquestQuota` true,
    // observer goal phase routes to EXPAND). `provincesToVictory` 24
    // sits above `kConquerScoreFloorProvincesToVictoryThreshold` so the
    // `behindVictoryPace` minor relation override
    // (`kDeclareWarMinorMaxRelationWhenFarFromVictory`) keeps the
    // declare-war candidate eligible regardless of relation score
    // initialization in `computeDiplomaticCandidateScores`.
    conquest: ConquestSummary(
      oldWorldProvincesOwned: 7,
      provincesToVictory: 24,
      invadableProvinceIdsSorted: [_minorOwProvince],
      adjacentOwnerFactionIdsSorted: [_minorId],
    ),
    colonial: ColonialSummary(),
    economy: EconomySummary(ownProvinceCount: 7),
    relations: {},
  );
}

AIWorldSnapshot _developSnapshot() {
  return const AIWorldSnapshot(
    playerId: _nationId,
    threats: ThreatSummary(),
    opportunities: OpportunitySummary(),
    // 12 OW provinces past the observer quota with no colonial
    // acquisition targets: `observerGoalPhaseFor` routes to DEVELOP.
    // `provincesToVictory` 19 keeps `behindVictoryPace` false (<= 20)
    // so the negative case isolates the DEVELOP suppression rather
    // than relying on the behind-victory-pace minor relation override.
    conquest: ConquestSummary(
      oldWorldProvincesOwned: 12,
      provincesToVictory: 19,
      invadableProvinceIdsSorted: [_minorOwProvince],
      adjacentOwnerFactionIdsSorted: [_minorId],
    ),
    colonial: ColonialSummary(),
    economy: EconomySummary(ownProvinceCount: 12),
    relations: {},
  );
}

List<String> _declareWarTargets(Orders orders) => <String>[
  for (final order
      in orders.diplomaticOrdersByPlayerId[_nationId] ?? const [])
    if (order.type == DiplomaticOrderType.declareWar) order.targetFactionId,
];

void main() {
  group('runDomainPlanners EXPAND minor declareWar', () {
    test('emits declareWar toward adjacent invadable OW minor in EXPAND', () {
      final game = _scenarioGame(gp1OwProvinces: _gp1OwProvincesBelowQuota);
      const topology = MapTopology(nodes: [], edges: []);
      final view = buildPlayerView(game, topology, _nationId);
      final snapshot = _expandSnapshot();

      expect(
        observerGoalPhaseFor(snapshot: snapshot, game: game),
        ObserverGoalPhase.expand,
        reason:
            'Fixture must place GP in EXPAND so the adjacent invadable '
            'minor declare-war AC is exercised by the orchestrator (not '
            'the COLONIAL fall-through, which routes through a different '
            'tribe/Join-Empire path, or DEVELOP which suppresses all '
            'declare-war candidates).',
      );

      final orders = runDomainPlanners(
        game: game,
        topology: topology,
        nationId: _nationId,
        view: view,
        snapshot: snapshot,
        config: _aiConfig,
        primaryGoal: StrategicGoal.expand,
        seeds: AISeedBundle.fromTurnSeed(2509101),
        suggestionAPI: _minorDeclareWarApi,
        economyPlan: _economyPlan,
      );

      expect(
        _declareWarTargets(orders),
        contains(_minorId),
        reason:
            'EXPAND with an adjacent invadable OW minor must surface the '
            'minor declare-war candidate in merged diplomatic orders so '
            'the GP can pursue OW conquest pressure toward the turn-100 '
            'per-GP +3 net OW gain gate (SPEC § Observer goal phases '
            '(Full AI), EXPAND declare-war priority order (a)).',
      );
    });

    test('suppresses minor declareWar in DEVELOP at quota', () {
      final game = _scenarioGame(gp1OwProvinces: _gp1OwProvincesDevelop);
      const topology = MapTopology(nodes: [], edges: []);
      final view = buildPlayerView(game, topology, _nationId);
      final snapshot = _developSnapshot();

      expect(
        observerGoalPhaseFor(snapshot: snapshot, game: game),
        ObserverGoalPhase.develop,
        reason:
            'Negative-control fixture must place GP in DEVELOP so the '
            'phase-wide declare-war suppression is exercised (otherwise '
            'this case would silently re-emit the EXPAND short-circuit '
            'and not verify the regression target).',
      );

      final orders = runDomainPlanners(
        game: game,
        topology: topology,
        nationId: _nationId,
        view: view,
        snapshot: snapshot,
        config: _aiConfig,
        primaryGoal: StrategicGoal.diplomacy,
        seeds: AISeedBundle.fromTurnSeed(2509102),
        suggestionAPI: _minorDeclareWarApi,
        economyPlan: _economyPlan,
      );

      expect(
        _declareWarTargets(orders),
        isNot(contains(_minorId)),
        reason:
            'DEVELOP must drop every declare-war candidate (including '
            'adjacent invadable OW minors) so improvement-first civilian '
            'work proceeds unblocked toward the turn-150 70% extractable-'
            'tile improvement gate (SPEC § Observer goal phases (Full '
            'AI), DEVELOP).',
      );
    });

    test('emits identical diplomatic orders for identical EXPAND inputs', () {
      final game = _scenarioGame(gp1OwProvinces: _gp1OwProvincesBelowQuota);
      const topology = MapTopology(nodes: [], edges: []);
      final view = buildPlayerView(game, topology, _nationId);
      final snapshot = _expandSnapshot();

      Orders runOnce(int turnSeed) => runDomainPlanners(
        game: game,
        topology: topology,
        nationId: _nationId,
        view: view,
        snapshot: snapshot,
        config: _aiConfig,
        primaryGoal: StrategicGoal.expand,
        seeds: AISeedBundle.fromTurnSeed(turnSeed),
        suggestionAPI: _minorDeclareWarApi,
        economyPlan: _economyPlan,
      );

      final firstRun = runOnce(2509103);
      final secondRun = runOnce(2509103);

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
            'must produce identical diplomatic orders across runs.',
      );
    });
  });
}
