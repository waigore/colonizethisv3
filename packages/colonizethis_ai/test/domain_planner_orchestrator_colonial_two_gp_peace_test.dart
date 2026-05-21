// Pins the COLONIAL-phase two-Great-Power peace contract from issue #2509 at
// the `runDomainPlanners` integration boundary.
//
// Issue #2509 acceptance criterion (S10 COLONIAL § Peace rules):
//
//   Given a GP in COLONIAL at war with two GPs where only one owns a
//   province blocking the GP's primary colonial target, when diplomacy
//   peace planning runs, then offerPeace is suggested toward the
//   non-blocking GP and not toward the blocking GP (deterministic for
//   fixed seed).
//
// The predicate that produces the non-blocker target set is pinned at the
// function level by `colonialPhaseGpPeaceTargets` /
// `primaryColonialGpBlocker` tests in
// `packages/colonizethis_ai/test/observer_goal_phase_test.dart`
// (group `colonialPhaseGpPeaceTargets`). Neither of those tests runs the
// orchestrator, so a future tuning slice could leave the predicate intact
// but bypass the orchestrator's call to
// `_stalledPeacePlannerResultIfNeeded` -> `collectStalledGreatPowerPeaceTargets`
// (or short-circuit through the `declareWarOnly` pass) and silently emit
// no `offerPeace` for the non-blocker — or, worse, peace the colonial
// frontier blocker and stall the COLONIAL acquisition push toward the
// turn-150 NW ownership gate. This file is the symmetric counterpart to
// `domain_planner_orchestrator_expand_two_gp_peace_test.dart` (EXPAND
// peace pin merged via PR #2614) and pins both halves of the contract at
// the `runDomainPlanners` boundary so the merged diplomatic-orders output
// stays SPEC-compliant when a GP is in COLONIAL with two GP wars.
//
// SPEC:
//   - `SPEC/ai/ai-architecture.md` § Observer goal phases (Full AI),
//     COLONIAL phase peace rule ("offerPeace toward at-war Great Powers
//     that do not own the primary colonial NW frontier blocker when
//     fighting two or more GPs").
//   - `SPEC/program/order-suggestions.md` § Diplomatic orders.
//
// Coverage layers:
//   - Positive: COLONIAL-phase merged orders contain `offerPeace` toward
//     the non-blocker GP.
//   - Negative: COLONIAL-phase merged orders do **not** contain
//     `offerPeace` toward the primary colonial NW frontier blocker GP.
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

// gp1 owns 11 OW provinces (>= the observer quota of 10), so the GP is
// past EXPAND and `isBelowObserverConquestQuota` is false. Combined with a
// non-empty colonial acquisition target set, this places the GP in
// COLONIAL per `observerGoalPhaseFor`.
const List<String> _gp1OwProvinces = <String>[
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

// gp2 owns two NW provinces. Both are listed in
// `invadableNewWorldProvinceIdsSorted` so `primaryColonialGpBlocker`
// resolves to `_blockerGpId` (the GP owning the most provinces in the
// invadable colonial set).
const List<String> _gp2InvadableNwProvinces = <String>[
  'newWorld|gp2_nw0',
  'newWorld|gp2_nw1',
];

// tribe1 owns one NW province in the invadable list. Its presence is what
// makes `hasColonialAcquisitionTargets` non-empty, but it does not
// outnumber gp2 in the invadable set so it is not the colonial blocker.
const String _tribeNwProvince = 'newWorld|tribe1_nw0';

// gp3 owns one OW province only (no NW presence), making it the
// non-blocker target of the COLONIAL multi-GP peace rule.
const String _gp3OwProvince = 'oldWorld|gp3_0';

Game _colonialTwoGpWarsScenarioGame() {
  return Game(
    id: 'g-2509-colonial-two-gp-peace',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 110),
      oldWorld: RegionData(
        provinces: [
          for (final id in _gp1OwProvinces)
            Province(id: id, regionId: 'oldWorld', ownerId: _nationId),
          const Province(
            id: _gp3OwProvince,
            regionId: 'oldWorld',
            ownerId: _nonBlockerGpId,
          ),
        ],
      ),
      newWorld: RegionData(
        provinces: [
          for (final id in _gp2InvadableNwProvinces)
            Province(id: id, regionId: 'newWorld', ownerId: _blockerGpId),
          const Province(
            id: _tribeNwProvince,
            regionId: 'newWorld',
            ownerId: 'tribe1',
          ),
        ],
      ),
      // Each GP holds a non-empty Home Army so `regimentCountForPlayer`
      // > 0 for every faction, avoiding the zero-regiment stalemate peace
      // paths (`stalledZeroRegimentGpPeaceTargets`,
      // `mutualZeroRegimentGpStalematePeaceTargets`) which would
      // unconditionally peace every at-war GP (including the blocker) for
      // an entirely different reason than the COLONIAL non-blocker rule
      // this test is pinning. Mirrors the equivalent guard in the EXPAND
      // two-GP peace pin (`domain_planner_orchestrator_expand_two_gp_peace_test.dart`).
      armies: [
        Army(
          id: homeArmyIdFor(_nationId),
          ownerId: _nationId,
          regionId: 'oldWorld',
          stationedProvinceId: _gp1OwProvinces.first,
          regimentUnitIds: const ['u_gp1'],
          isHomeArmy: true,
        ),
        Army(
          id: homeArmyIdFor(_blockerGpId),
          ownerId: _blockerGpId,
          regionId: 'newWorld',
          stationedProvinceId: _gp2InvadableNwProvinces.first,
          regimentUnitIds: const ['u_gp2'],
          isHomeArmy: true,
        ),
        Army(
          id: homeArmyIdFor(_nonBlockerGpId),
          ownerId: _nonBlockerGpId,
          regionId: 'oldWorld',
          stationedProvinceId: _gp3OwProvince,
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
    tribes: const [Tribe(id: 'tribe1', displayName: 'T1')],
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

AIWorldSnapshot _colonialTwoGpWarsSnapshot() {
  return const AIWorldSnapshot(
    playerId: _nationId,
    threats: ThreatSummary(atWarWith: [_blockerGpId, _nonBlockerGpId]),
    opportunities: OpportunitySummary(),
    // 11 OW provinces -> COLONIAL (quota met, acquisition targets visible).
    // No invadable OW frontier means the EXPAND-phase invadable-blocker
    // preservation rule does not apply here (orthogonal to COLONIAL).
    conquest: ConquestSummary(
      oldWorldProvincesOwned: 11,
      provincesToVictory: 20,
    ),
    // gp2 owns two of the three invadable NW provinces, so
    // `primaryColonialGpBlocker` resolves to `_blockerGpId`. The presence
    // of `tribe1` as an adjacent owner keeps `hasColonialAcquisitionTargets`
    // true so the phase resolves to COLONIAL rather than DEVELOP.
    colonial: ColonialSummary(
      newWorldProvincesOwned: 0,
      invadableNewWorldProvinceIdsSorted: [
        'newWorld|gp2_nw0',
        'newWorld|gp2_nw1',
        _tribeNwProvince,
      ],
      adjacentNewWorldOwnerFactionIdsSorted: [_blockerGpId, 'tribe1'],
    ),
    economy: EconomySummary(ownProvinceCount: 11),
    relations: {},
  );
}

List<String> _offerPeaceTargets(Orders orders) => <String>[
  for (final order in orders.diplomaticOrdersByPlayerId[_nationId] ?? const [])
    if (order.type == DiplomaticOrderType.offerPeace) order.targetFactionId,
];

void main() {
  group('runDomainPlanners COLONIAL two-GP peace', () {
    test('peaces the non-blocker GP front', () {
      final game = _colonialTwoGpWarsScenarioGame();
      const topology = MapTopology(nodes: [], edges: []);
      final view = buildPlayerView(game, topology, _nationId);
      final snapshot = _colonialTwoGpWarsSnapshot();

      expect(
        observerGoalPhaseFor(snapshot: snapshot, game: game),
        ObserverGoalPhase.colonial,
        reason:
            'Fixture must place GP in COLONIAL so the two-GP peace contract '
            'is exercised by the orchestrator (not the EXPAND/DEVELOP '
            'fall-through, which has separate peace targets).',
      );
      expect(
        primaryColonialGpBlocker(game: game, snapshot: snapshot),
        _blockerGpId,
        reason:
            'Fixture must resolve `primaryColonialGpBlocker` to gp2 so the '
            'colonialPhaseGpPeaceTargets rule has a well-defined non-blocker '
            'set (otherwise the test cannot meaningfully assert blocker '
            'preservation).',
      );

      final orders = runDomainPlanners(
        game: game,
        topology: topology,
        nationId: _nationId,
        view: view,
        snapshot: snapshot,
        config: _aiConfig,
        primaryGoal: StrategicGoal.conquer,
        seeds: AISeedBundle.fromTurnSeed(2509110),
        suggestionAPI: _emptyApi,
        economyPlan: _economyPlan,
      );

      final peaceTargets = _offerPeaceTargets(orders);
      expect(
        peaceTargets,
        contains(_nonBlockerGpId),
        reason:
            'COLONIAL with two GP wars must emit offerPeace toward the '
            'non-blocker GP front (SPEC § Observer goal phases (Full AI), '
            'COLONIAL peace rule).',
      );
    });

    test('holds the primary colonial NW frontier blocker war', () {
      final game = _colonialTwoGpWarsScenarioGame();
      const topology = MapTopology(nodes: [], edges: []);
      final view = buildPlayerView(game, topology, _nationId);
      final snapshot = _colonialTwoGpWarsSnapshot();

      expect(
        observerGoalPhaseFor(snapshot: snapshot, game: game),
        ObserverGoalPhase.colonial,
      );

      final orders = runDomainPlanners(
        game: game,
        topology: topology,
        nationId: _nationId,
        view: view,
        snapshot: snapshot,
        config: _aiConfig,
        primaryGoal: StrategicGoal.conquer,
        seeds: AISeedBundle.fromTurnSeed(2509111),
        suggestionAPI: _emptyApi,
        economyPlan: _economyPlan,
      );

      final peaceTargets = _offerPeaceTargets(orders);
      expect(
        peaceTargets,
        isNot(contains(_blockerGpId)),
        reason:
            'COLONIAL must not peace the primary colonial NW frontier '
            'blocker GP while acquisition targets remain: that war is the '
            'sanctioned path toward the turn-150 NW ownership gate (SPEC '
            '§ Observer goal phases (Full AI), COLONIAL peace rule).',
      );
    });

    test('emits identical diplomatic orders for identical inputs', () {
      final game = _colonialTwoGpWarsScenarioGame();
      const topology = MapTopology(nodes: [], edges: []);
      final view = buildPlayerView(game, topology, _nationId);
      final snapshot = _colonialTwoGpWarsSnapshot();

      Orders runOnce(int turnSeed) => runDomainPlanners(
        game: game,
        topology: topology,
        nationId: _nationId,
        view: view,
        snapshot: snapshot,
        config: _aiConfig,
        primaryGoal: StrategicGoal.conquer,
        seeds: AISeedBundle.fromTurnSeed(turnSeed),
        suggestionAPI: _emptyApi,
        economyPlan: _economyPlan,
      );

      final firstRun = runOnce(2509112);
      final secondRun = runOnce(2509112);

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
