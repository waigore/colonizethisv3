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

import 'domain_planner_test_fake_api.dart';

const String _nationId = 'gp1';
const String _blockerGpId = 'gp2';
const String _nonBlockerGpId = 'gp3';

// gp1 owns 8 OW provinces (below the quota of 10 -> EXPAND).
const List<String> _gp1Provinces = <String>[
  'oldWorld|gp1_0',
  'oldWorld|gp1_1',
  'oldWorld|gp1_2',
  'oldWorld|gp1_3',
  'oldWorld|gp1_4',
  'oldWorld|gp1_5',
  'oldWorld|gp1_6',
  'oldWorld|gp1_7',
];

// gp2 owns three OW provinces; all three appear in
// `invadableProvinceIdsSorted` so it is the primary frontier blocker.
const List<String> _gp2InvadableProvinces = <String>[
  'oldWorld|gp2_0',
  'oldWorld|gp2_1',
  'oldWorld|gp2_2',
];

// gp3 owns one OW province that is **not** invadable from gp1, making it
// the non-blocker target of the EXPAND multi-GP peace rule.
const String _gp3Province = 'oldWorld|gp3_0';

Game _expandTwoGpWarsScenarioGame() {
  return Game(
    id: 'g-2509-expand-two-gp-peace',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 40),
      oldWorld: RegionData(
        provinces: [
          for (final id in _gp1Provinces)
            Province(id: id, regionId: 'oldWorld', ownerId: _nationId),
          for (final id in _gp2InvadableProvinces)
            Province(id: id, regionId: 'oldWorld', ownerId: _blockerGpId),
          const Province(
            id: _gp3Province,
            regionId: 'oldWorld',
            ownerId: _nonBlockerGpId,
          ),
        ],
      ),
      newWorld: const RegionData(),
      // Each GP holds a non-empty Home Army so `regimentCountForPlayer`
      // > 0 for every faction, avoiding the zero-regiment stalemate peace
      // paths (`stalledZeroRegimentGpPeaceTargets`,
      // `mutualZeroRegimentGpStalematePeaceTargets`) which would
      // unconditionally peace every at-war GP (including the blocker) for
      // an entirely different reason than the EXPAND non-blocker rule
      // this test is pinning.
      armies: [
        Army(
          id: homeArmyIdFor(_nationId),
          ownerId: _nationId,
          regionId: 'oldWorld',
          stationedProvinceId: _gp1Provinces.first,
          regimentUnitIds: const ['u_gp1'],
          isHomeArmy: true,
        ),
        Army(
          id: homeArmyIdFor(_blockerGpId),
          ownerId: _blockerGpId,
          regionId: 'oldWorld',
          stationedProvinceId: _gp2InvadableProvinces.first,
          regimentUnitIds: const ['u_gp2'],
          isHomeArmy: true,
        ),
        Army(
          id: homeArmyIdFor(_nonBlockerGpId),
          ownerId: _nonBlockerGpId,
          regionId: 'oldWorld',
          stationedProvinceId: _gp3Province,
          regimentUnitIds: const ['u_gp3'],
          isHomeArmy: true,
        ),
      ],
    ),
    players: const [
      Player(
        id: _nationId,
        displayName: 'GP1',
        isHuman: false,
        leaderKey: 'victoria',
      ),
      Player(id: _blockerGpId, displayName: 'GP2', isHuman: false),
      Player(id: _nonBlockerGpId, displayName: 'GP3', isHuman: false),
    ],
    minorNations: const [],
    tribes: const [],
    diplomacyRelations: const [
      DiplomacyRelation(
        factionId1: _nationId,
        factionId2: _blockerGpId,
        state: RelationState.atWar,
        score: 10,
      ),
      DiplomacyRelation(
        factionId1: _nationId,
        factionId2: _nonBlockerGpId,
        state: RelationState.atWar,
        score: 10,
      ),
    ],
  );
}

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
      invadableProvinceIdsSorted: _gp2InvadableProvinces,
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
      final game = _expandTwoGpWarsScenarioGame();
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
      final game = _expandTwoGpWarsScenarioGame();
      const topology = MapTopology(nodes: [], edges: []);
      final view = buildPlayerView(game, topology, _nationId);
      final snapshot = _expandTwoGpWarsSnapshot();

      expect(
        observerGoalPhaseFor(snapshot: snapshot, game: game),
        ObserverGoalPhase.expand,
      );

      final orders = runDomainPlanners(
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
      final game = _expandTwoGpWarsScenarioGame();
      const topology = MapTopology(nodes: [], edges: []);
      final view = buildPlayerView(game, topology, _nationId);
      final snapshot = _expandTwoGpWarsSnapshot();

      Orders runOnce(int turnSeed) => runDomainPlanners(
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
