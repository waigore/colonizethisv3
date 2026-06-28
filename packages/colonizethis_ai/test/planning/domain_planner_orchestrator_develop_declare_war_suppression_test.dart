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

const String _nationId = 'gp1';
const String _tribeId = 'tribe1';
const String _gpOwnedNwProvince = 'newWorld|gp1_nw0';
const String _tribeNwProvince = 'newWorld|tribe1_nw0';

// gp1 owns 11 OW provinces (>= the observer quota of 10), so the GP is
// past EXPAND and `isBelowObserverConquestQuota` is false. The COLONIAL
// vs DEVELOP split is then driven entirely by whether the NW region holds
// a tribe-owned (or otherwise non-GP) province visible to the snapshot's
// colonial summary.
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

/// DEVELOP scenario: every `newWorld|` province is GP-owned so
/// `hasColonialAcquisitionTargets` is false and the snapshot has no
/// invadable/adjacent colonial targets. Combined with `oldWorldProvincesOwned
/// >= 10` this places the GP in DEVELOP per `observerGoalPhaseFor`.
Game _developScenarioGame() {
  return Game(
    id: 'g-2509-develop-declare-war-suppress',
    worldState: WorldState(
      // Turn 140 keeps us past the turn-120 COLONIAL-lite safeguard window
      // and inside the DEVELOP improvement-first horizon toward turn 150.
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 140),
      oldWorld: RegionData(
        provinces: [
          for (final id in _gp1OwProvincesAtQuota)
            Province(id: id, regionId: 'oldWorld', ownerId: _nationId),
        ],
      ),
      newWorld: const RegionData(
        provinces: [
          Province(
            id: _gpOwnedNwProvince,
            regionId: 'newWorld',
            ownerId: _nationId,
          ),
        ],
      ),
      // Non-empty Home Army for gp1 keeps `regimentCountForPlayer` > 0 and
      // avoids the zero-regiment stalemate peace paths firing alongside the
      // declare-war contract this file pins. Mirrors the guard used in the
      // EXPAND/COLONIAL two-GP peace and overture suppression pins.
      armies: [
        Army(
          id: homeArmyIdFor(_nationId),
          ownerId: _nationId,
          regionId: 'oldWorld',
          stationedProvinceId: _gp1OwProvincesAtQuota.first,
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

/// COLONIAL scenario: a tribe still owns a sea-reachable `newWorld|`
/// province, so `hasColonialAcquisitionTargets` is true and the GP enters
/// COLONIAL per `observerGoalPhaseFor`. The negative-control fixture
/// exercises the orchestrator on the SAME fake API to verify the DEVELOP
/// filter is not over-applied in COLONIAL.
Game _colonialScenarioGame() {
  return Game(
    id: 'g-2509-develop-declare-war-suppress-colonial-control',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 130),
      oldWorld: RegionData(
        provinces: [
          for (final id in _gp1OwProvincesAtQuota)
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
      armies: [
        Army(
          id: homeArmyIdFor(_nationId),
          ownerId: _nationId,
          regionId: 'oldWorld',
          stationedProvinceId: _gp1OwProvincesAtQuota.first,
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

AIWorldSnapshot _developSnapshot() {
  return const AIWorldSnapshot(
    playerId: _nationId,
    // At war with the tribe so the declare-war candidate is structurally
    // a candidate (DEVELOP suppression must drop a candidate the planner
    // would otherwise consider, not merely one without a valid target).
    threats: ThreatSummary(atWarWith: [_tribeId]),
    opportunities: OpportunitySummary(),
    // 11 OW provinces -> past EXPAND quota. Empty colonial summary +
    // GP-owned NW -> DEVELOP.
    conquest: ConquestSummary(
      oldWorldProvincesOwned: 11,
      provincesToVictory: 20,
    ),
    colonial: ColonialSummary(newWorldProvincesOwned: 1),
    economy: EconomySummary(ownProvinceCount: 11),
    relations: {
      _tribeId: DiplomacyRelation(
        factionId1: _nationId,
        factionId2: _tribeId,
        state: RelationState.atWar,
        score: 10,
      ),
    },
  );
}

AIWorldSnapshot _colonialSnapshot() {
  return const AIWorldSnapshot(
    playerId: _nationId,
    threats: ThreatSummary(atWarWith: [_tribeId]),
    opportunities: OpportunitySummary(),
    // 11 OW provinces + invadable NW -> COLONIAL.
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
    relations: {
      _tribeId: DiplomacyRelation(
        factionId1: _nationId,
        factionId2: _tribeId,
        state: RelationState.atWar,
        score: 10,
      ),
    },
  );
}

List<String> _declareWarTargets(Orders orders) => <String>[
  for (final order
      in orders.diplomaticOrdersByPlayerId[_nationId] ?? const [])
    if (order.type == DiplomaticOrderType.declareWar)
      order.targetFactionId,
];

void main() {
  group('runDomainPlanners DEVELOP-phase declareWar suppression', () {
    test('DEVELOP drops declareWar toward at-war tribe candidate', () {
      final game = _developScenarioGame();
      const topology = MapTopology(nodes: [], edges: []);
      final view = buildPlayerView(game, topology, _nationId);
      final snapshot = _developSnapshot();

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
        final game = _colonialScenarioGame();
        const topology = MapTopology(nodes: [], edges: []);
        final view = buildPlayerView(game, topology, _nationId);
        final snapshot = _colonialSnapshot();

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
      final game = _developScenarioGame();
      const topology = MapTopology(nodes: [], edges: []);
      final view = buildPlayerView(game, topology, _nationId);
      final snapshot = _developSnapshot();

      Orders runOnce(int turnSeed) => runDomainPlanners(
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
