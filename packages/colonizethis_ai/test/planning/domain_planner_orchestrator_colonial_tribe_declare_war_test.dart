// Pins the COLONIAL-phase tribe `declareWar` AC from issue #2509 at the
// `runDomainPlanners` integration boundary:
//
//   Given a GP in COLONIAL phase with a visible tribe owning a sea-reachable
//   unowned `newWorld|` province and valid declare-war preconditions, when
//   diplomacy planning runs, then `declareWar` toward that tribe is among
//   suggested orders (deterministic for fixed seed).
//
// The candidate-emission contract for `suggestDeclareWarOrders` itself is
// pinned in the logic layer
// (`packages/colonizethis_logic/test/order_suggestion_colonial_acquisition_join_empire_or_war_test.dart`,
// PR #2603). The AI scoring contract that the candidate is **not** zeroed
// while in COLONIAL is pinned at the predicate level in
// `packages/colonizethis_ai/test/observer_goal_phase_test.dart`
// (group `COLONIAL allows NW tribe declareWar scoring`). Neither of those
// tests runs the orchestrator, so a future tuning slice could leave both
// the suggestion API and the predicate scoring intact while bypassing the
// orchestrator's integration of those scores into merged diplomatic orders
// (for example by short-circuiting the declare-war pass when the GP already
// has a peace order against the tribe target, or by widening the
// COLONIAL-suppression filter in `domain_planner_orchestrator.dart` so it
// silently drops tribe declare-war candidates). That regression would
// directly threaten the turn-150 NW ownership gate by removing the only
// AC-sanctioned conquest path against tribes still holding `newWorld|`
// provinces.
//
// The negative control asserts the symmetric EXPAND-phase suppression at
// the same `runDomainPlanners` boundary so a regression that over-emits NW
// tribe declare-war below OW quota is also caught (mirrors the EXPAND
// scoring-suppression group in `observer_goal_phase_test.dart`).
//
// SPEC:
//   - `SPEC/ai/ai-architecture.md` § Observer goal phases (Full AI),
//     COLONIAL phase declare-war / overture rule.
//   - `SPEC/program/order-suggestions.md` § Diplomatic orders.
//
// Coverage layers:
//   - Positive: COLONIAL-phase merged diplomatic orders contain
//     `declareWar` toward the visible tribe owning a sea-reachable NW
//     province.
//   - Negative: EXPAND-phase merged diplomatic orders do **not** contain
//     `declareWar` toward the same tribe (NW suppression below OW quota).
//   - Determinism guard: re-running with identical inputs produces an
//     identical diplomatic-order fingerprint (must-have #7).

import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/orchestrator_options.dart';
import 'package:colonizethis_ai/src/planning/observer_goal_phase.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../support/domain_planner_test_fake_api.dart';

const String _nationId = 'gp1';
const String _tribeId = 'tribe1';
const String _tribeNwProvince = 'newWorld|tribe1_nw0';

// Explicit NW-acquisition-zero phase plan emulating the legacy
// hard-suppress contract for the EXPAND negative-control assertion
// (Refs #2847 Phase 3 — soft-weight migration). The production
// `_curveWeightsForOw(7)` curve emits `newWorldAcquisition = 0.05`
// (early-sprint plateau), which the scoring-side migration in
// `_declareWarSuppressedExpandColonialScore` treats as
// "reachable at low priority" — see the PR's
// `phase_planner_diplomacy_declare_war_nw_suppression_test.dart`.
// The strict hard-suppress regression assertion threads this
// explicit override through the orchestrator so
// `nwAcquisitionWeight == 0.0` collapses NW colonial declare-war
// candidates.
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

// gp1 owns 11 OW provinces (>= the observer quota of 10), so the GP is
// past EXPAND and `isBelowObserverConquestQuota` is false. Combined with
// a non-empty `invadableNewWorldProvinceIdsSorted` set, this places the
// GP in COLONIAL per `observerGoalPhaseFor`.
const List<String> _gp1OwProvincesAtQuota = <String>[
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
];

// Sub-quota OW set used for the EXPAND negative control.
const List<String> _gp1OwProvincesBelowQuota = <String>[
  'oldWorld|gp1_0',
  'oldWorld|gp1_1',
  'oldWorld|gp1_2',
  'oldWorld|gp1_3',
  'oldWorld|gp1_4',
  'oldWorld|gp1_5',
  'oldWorld|gp1_6',
];

Game _scenarioGame({required List<String> gp1OwProvinces}) {
  return Game(
    id: 'g-2509-colonial-tribe-declare',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 110),
      oldWorld: RegionData(
        provinces: [
          for (final id in gp1OwProvinces)
            Province(id: id, regionId: 'oldWorld', ownerId: _nationId),
        ],
      ),
      newWorld: const RegionData(
        provinces: [
          Province(
            id: _tribeNwProvince,
            regionId: 'newWorld',
            ownerId: _tribeId,
          ),
        ],
      ),
      // Non-empty Home Army for gp1 keeps `regimentCountForPlayer` > 0 and
      // avoids the zero-regiment stalemate peace paths that would coexist
      // with declare-war scoring in unrelated ways. Mirrors the guard used
      // in the EXPAND/COLONIAL two-GP peace pins
      // (`domain_planner_orchestrator_{expand,colonial}_two_gp_peace_test.dart`).
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
    tribes: const [Tribe(id: _tribeId, displayName: 'T1')],
    minorNations: const [],
  );
}

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

// Match the personality/agenda that scores tribe declare-war > 0 in the
// pinned predicate test (`COLONIAL allows NW tribe declareWar scoring` in
// `observer_goal_phase_test.dart`). The `peacemaker` agenda zeroes
// declare-war candidates regardless of phase, so it would not exercise
// the COLONIAL emission contract this file pins. `henry` / `merchant` is
// a colonial-leaning leader/agenda combo aligned with the AC text
// ("personality may bias military vs diplomatic route").
const AIConfig _aiConfig = AIConfig(
  leaderId: 'henry',
  personalityId: 'henry',
  hiddenAgendaId: 'merchant',
);

AIWorldSnapshot _colonialSnapshot() {
  return const AIWorldSnapshot(
    playerId: _nationId,
    threats: ThreatSummary(),
    opportunities: OpportunitySummary(),
    // 11 OW provinces -> COLONIAL when colonial acquisition targets are
    // visible in the snapshot.
    conquest: ConquestSummary(
      oldWorldProvincesOwned: 11,
      provincesToVictory: 20,
    ),
    colonial: ColonialSummary(
      newWorldProvincesOwned: 0,
      invadableNewWorldProvinceIdsSorted: [_tribeNwProvince],
      adjacentNewWorldOwnerFactionIdsSorted: [_tribeId],
      preferredColonialTargetFactionIdsSorted: [_tribeId],
    ),
    economy: EconomySummary(ownProvinceCount: 11),
    relations: {},
  );
}

AIWorldSnapshot _expandSnapshot() {
  return const AIWorldSnapshot(
    playerId: _nationId,
    threats: ThreatSummary(),
    opportunities: OpportunitySummary(),
    // 7 OW provinces -> EXPAND while invadable NW is visible: the AI
    // must suppress NW tribe declare-war candidates below OW quota
    // even though the suggestion API surfaces them.
    conquest: ConquestSummary(
      oldWorldProvincesOwned: 7,
      provincesToVictory: 24,
    ),
    colonial: ColonialSummary(
      invadableNewWorldProvinceIdsSorted: [_tribeNwProvince],
      adjacentNewWorldOwnerFactionIdsSorted: [_tribeId],
      preferredColonialTargetFactionIdsSorted: [_tribeId],
    ),
    economy: EconomySummary(ownProvinceCount: 7),
    relations: {},
  );
}

List<String> _declareWarTargets(Orders orders) => <String>[
      for (final order
          in orders.diplomaticOrdersByPlayerId[_nationId] ?? const [])
        if (order.type == DiplomaticOrderType.declareWar)
          order.targetFactionId,
    ];

void main() {
  group('runDomainPlanners COLONIAL tribe declareWar', () {
    test('emits declareWar toward visible NW tribe when in COLONIAL', () {
      final game = _scenarioGame(gp1OwProvinces: _gp1OwProvincesAtQuota);
      const topology = MapTopology(nodes: [], edges: []);
      final view = buildPlayerView(game, topology, _nationId);
      final snapshot = _colonialSnapshot();

      expect(
        observerGoalPhaseFor(snapshot: snapshot, game: game),
        ObserverGoalPhase.colonial,
        reason:
            'Fixture must place GP in COLONIAL so the tribe declare-war '
            'AC is exercised by the orchestrator (not the EXPAND '
            'fall-through, which suppresses NW declare-war).',
      );

      final orders = runDomainPlanners(
        game: game,
        topology: topology,
        nationId: _nationId,
        view: view,
        snapshot: snapshot,
        config: _aiConfig,
        primaryGoal: StrategicGoal.conquer,
        seeds: AISeedBundle.fromTurnSeed(2509120),
        suggestionAPI: _tribeDeclareWarApi,
        economyPlan: _economyPlan,
      );

      expect(
        _declareWarTargets(orders),
        contains(_tribeId),
        reason:
            'COLONIAL with a visible tribe owning a sea-reachable NW '
            'province must surface the tribe declare-war candidate in '
            'merged diplomatic orders (SPEC § Observer goal phases (Full '
            'AI), COLONIAL declare-war rule).',
      );
    });

    test('suppresses tribe declareWar in EXPAND below OW quota', () {
      final game = _scenarioGame(gp1OwProvinces: _gp1OwProvincesBelowQuota);
      const topology = MapTopology(nodes: [], edges: []);
      final view = buildPlayerView(game, topology, _nationId);
      final snapshot = _expandSnapshot();

      expect(
        observerGoalPhaseFor(snapshot: snapshot, game: game),
        ObserverGoalPhase.expand,
        reason:
            'Negative-control fixture must place GP in EXPAND so the NW '
            'declare-war suppression is verified (otherwise the test would '
            'silently exercise COLONIAL).',
      );

      final orders = runDomainPlanners(
        game: game,
        topology: topology,
        nationId: _nationId,
        view: view,
        snapshot: snapshot,
        config: _aiConfig,
        primaryGoal: StrategicGoal.expand,
        seeds: AISeedBundle.fromTurnSeed(2509121),
        suggestionAPI: _tribeDeclareWarApi,
        economyPlan: _economyPlan,
        // Pin the legacy EXPAND hard-suppress contract via an explicit
        // `newWorldAcquisition = 0.0` override (Refs #2847 Phase 3).
        // Under the soft-weight production curve
        // `_curveWeightsForOw(7)` returns 0.05 — see
        // `phase_planner_diplomacy_declare_war_nw_suppression_test.dart`
        // for the new soft-weight contract.
        options: OrchestratorOptions(phasePlan: _expandPhasePlanHardSuppressNw),
      );

      expect(
        _declareWarTargets(orders),
        isNot(contains(_tribeId)),
        reason:
            'Under the explicit `newWorldAcquisition = 0.0` override '
            '(legacy hard-suppress regression contract), EXPAND below '
            'OW quota must drop NW tribe declare-war candidates so OW '
            'conquest pressure is preserved (SPEC § Observer goal '
            'phases (Full AI), EXPAND suppression rule).',
      );
    });

    test('emits identical diplomatic orders for identical COLONIAL inputs',
        () {
      final game = _scenarioGame(gp1OwProvinces: _gp1OwProvincesAtQuota);
      const topology = MapTopology(nodes: [], edges: []);
      final view = buildPlayerView(game, topology, _nationId);
      final snapshot = _colonialSnapshot();

      Orders runOnce(int turnSeed) => runDomainPlanners(
            game: game,
            topology: topology,
            nationId: _nationId,
            view: view,
            snapshot: snapshot,
            config: _aiConfig,
            primaryGoal: StrategicGoal.conquer,
            seeds: AISeedBundle.fromTurnSeed(turnSeed),
            suggestionAPI: _tribeDeclareWarApi,
            economyPlan: _economyPlan,
          );

      final firstRun = runOnce(2509122);
      final secondRun = runOnce(2509122);

      List<String> diplomaticFingerprint(Orders orders) => <String>[
            for (final o
                in orders.diplomaticOrdersByPlayerId[_nationId] ?? const [])
              '${o.type}|${o.targetFactionId}|${o.overtureStage}',
          ];

      expect(
        diplomaticFingerprint(secondRun),
        diplomaticFingerprint(firstRun),
        reason:
            'Determinism (must-have #7): identical COLONIAL-phase inputs '
            'must produce identical diplomatic orders across runs.',
      );
    });
  });
}
