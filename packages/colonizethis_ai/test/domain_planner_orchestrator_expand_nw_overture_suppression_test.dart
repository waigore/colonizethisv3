// Pins the EXPAND-phase New World `establishOverture` suppression rule from
// issue #2509 at the `runDomainPlanners` integration boundary:
//
//   SPEC/ai/ai-architecture.md § Observer goal phases (Full AI), EXPAND:
//     Suppress: NW `declareWar`/`establishOverture`, NW conquest army moves,
//     NW naval colonial missions, `purchase_land` in `newWorld|`,
//     `build_improvement` on NW tiles, colonial cargo preference.
//
// The scoring-level half of the `establishOverture` suppression is pinned in
// `packages/colonizethis_ai/test/diplomatic_candidate_scoring_suppression_test.dart`
// (PR #2601 — collapses the overture candidate score to 0 when the GP is
// below OW quota and the target is a tribe / preferred colonial target /
// invadable NW owner). Sibling PR #2616
// (`domain_planner_orchestrator_colonial_tribe_declare_war_test.dart`) pins
// the **`declareWar`** half of the same EXPAND suppression at the
// orchestrator boundary. Neither covers the `establishOverture` half at the
// orchestrator integration: a future tuning slice that left the score
// collapse intact (overture score = 0 in EXPAND) but added a parallel path
// in `domain_planner_orchestrator.dart` / `diplomacy_planner.dart` that
// surfaced `establishOverture(NW tribe, joinEmpire)` directly into merged
// diplomatic orders — for example a "colonial diplomacy forced overture"
// helper mirroring `_defaultStartOwMinorDeclarePlannerResultIfNeeded` — would
// silently violate the EXPAND clause and pull GPs off the OW quota path
// before turn 100, regressing the canonical seed-42 `--verify-conquest`
// nightly gate.
//
// The negative control asserts the same overture candidate **is** emitted in
// COLONIAL so a regression that over-suppresses NW overtures at quota (and
// therefore strips the Join Empire acquisition route from § COLONIAL phase
// — minimum rules § 1) is also caught.
//
// Coverage layers:
//   - Positive (EXPAND): merged diplomatic orders do **not** contain
//     `establishOverture` toward the NW tribe candidate the fake API provides.
//   - Negative control (COLONIAL): the same overture candidate **is** emitted
//     by the orchestrator, so the test catches over-suppression in the wrong
//     phase.
//   - Determinism guard (must-have #7): identical EXPAND-phase inputs
//     produce identical diplomatic-order fingerprints.

import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/observer_goal_phase.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'domain_planner_test_fake_api.dart';

const String _nationId = 'gp1';
const String _tribeId = 'tribe1';
const String _tribeNwProvince = 'newWorld|tribe1_nw0';

// Sub-quota OW set (< `kObserverConquestMinOwProvincesPerGp` = 10) so
// `isBelowObserverConquestQuota` is true and the GP enters EXPAND per
// `observerGoalPhaseFor`. Mirrors the EXPAND negative-control shape used in
// `domain_planner_orchestrator_colonial_tribe_declare_war_test.dart`.
const List<String> _gp1OwProvincesBelowQuota = <String>[
  'oldWorld|gp1_0',
  'oldWorld|gp1_1',
  'oldWorld|gp1_2',
  'oldWorld|gp1_3',
  'oldWorld|gp1_4',
  'oldWorld|gp1_5',
  'oldWorld|gp1_6',
];

// At-quota OW set (>= `kObserverConquestMinOwProvincesPerGp` = 10) so the GP
// passes the EXPAND gate and enters COLONIAL when colonial acquisition
// targets are visible. Used by the negative-control test.
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

Game _scenarioGame({required List<String> gp1OwProvinces}) {
  return Game(
    id: 'g-2509-expand-nw-overture-suppress',
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
      // avoids the zero-regiment stalemate peace paths firing as unrelated
      // diplomatic orders (mirrors the guard used in
      // `domain_planner_orchestrator_colonial_two_gp_peace_test.dart`).
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
    // Peace + embassy is the precondition for `establishOverture(joinEmpire)`
    // to be a structurally valid candidate. The fake API returns the
    // candidate unconditionally; the orchestrator's scoring + selection
    // path is what enforces the EXPAND suppression vs COLONIAL emission
    // contract this file pins.
    diplomacyRelations: const [
      DiplomacyRelation(
        factionId1: _nationId,
        factionId2: _tribeId,
        state: RelationState.atPeace,
        score: 60,
      ),
    ],
    overtureStates: const [
      OvertureState(
        gpId: _nationId,
        targetId: _tribeId,
        stage: OvertureStage.embassy,
      ),
    ],
  );
}

// Fake API provides one `establishOverture(tribe1, joinEmpire)` candidate.
// The fake's `suggestDeclareWarOrders` filters by `type == declareWar` so
// only the `nonDeclareWarOnly` pass of `runDiplomacyPlannerWithResult` sees
// this candidate — exactly the path under test for the SPEC EXPAND
// `establishOverture` suppression rule.
const FakeOrderSuggestionAPIForDomainPlannerTests _nwTribeOvertureApi =
    FakeOrderSuggestionAPIForDomainPlannerTests(
  work: [],
  build: [],
  move: [],
  research: [],
  navalMove: [],
  navalMission: [],
  diplomatic: [
    DiplomaticOrder(
      type: DiplomaticOrderType.establishOverture,
      targetFactionId: _tribeId,
      overtureStage: OvertureStage.joinEmpire,
    ),
  ],
);

const EconomyPlan _economyPlan = EconomyPlan(
  productionAssignments: [],
  cargoPreference: CargoPreference.none,
);

// `henry` + `merchant` matches the personality/agenda used by the
// scoring-level COLONIAL positive test
// (`COLONIAL personality colonial acquisition` group in
// `observer_goal_phase_test.dart`) and the orchestrator-level COLONIAL
// tribe declareWar pin (`domain_planner_orchestrator_colonial_tribe_declare_war_test.dart`).
// `peacemaker` is intentionally avoided here because that agenda zeroes
// declare-war candidates and could confound the COLONIAL negative-control
// outcome if it also dampens overture scoring along an unrelated path.
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
    // 7 OW provinces -> EXPAND (below the observer quota of 10).
    conquest: ConquestSummary(
      oldWorldProvincesOwned: 7,
      provincesToVictory: 24,
    ),
    // Tribe is both a visible NW invadable owner **and** a preferred
    // colonial target. Both predicates feed into the EXPAND overture
    // suppression branch in `computeDiplomaticCandidateScores` so the test
    // exercises the rule across all three triggering conditions (tribe /
    // preferred / invadable owner).
    colonial: ColonialSummary(
      invadableNewWorldProvinceIdsSorted: [_tribeNwProvince],
      adjacentNewWorldOwnerFactionIdsSorted: [_tribeId],
      preferredColonialTargetFactionIdsSorted: [_tribeId],
    ),
    economy: EconomySummary(ownProvinceCount: 7),
    relations: {
      _tribeId: DiplomacyRelation(
        factionId1: _nationId,
        factionId2: _tribeId,
        state: RelationState.atPeace,
        score: 60,
      ),
    },
  );
}

AIWorldSnapshot _colonialSnapshot() {
  return const AIWorldSnapshot(
    playerId: _nationId,
    threats: ThreatSummary(),
    opportunities: OpportunitySummary(),
    // 11 OW provinces -> COLONIAL when colonial acquisition targets are
    // visible. EXPAND `establishOverture` suppression must **not** fire here.
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
        state: RelationState.atPeace,
        score: 60,
      ),
    },
  );
}

List<String> _overtureTargets(Orders orders) => <String>[
  for (final order
      in orders.diplomaticOrdersByPlayerId[_nationId] ?? const [])
    if (order.type == DiplomaticOrderType.establishOverture)
      order.targetFactionId,
];

void main() {
  group('runDomainPlanners EXPAND-phase NW establishOverture suppression', () {
    test('EXPAND drops establishOverture toward NW tribe colonial target', () {
      final game = _scenarioGame(gp1OwProvinces: _gp1OwProvincesBelowQuota);
      const topology = MapTopology(nodes: [], edges: []);
      final view = buildPlayerView(game, topology, _nationId);
      final snapshot = _expandSnapshot();

      expect(
        observerGoalPhaseFor(snapshot: snapshot, game: game),
        ObserverGoalPhase.expand,
        reason:
            'Fixture must place GP in EXPAND so the NW overture '
            'suppression contract is exercised by the orchestrator, not '
            'the COLONIAL fall-through (which has separate diplomacy '
            'rules that allow tribe overtures).',
      );

      final orders = runDomainPlanners(
        game: game,
        topology: topology,
        nationId: _nationId,
        view: view,
        snapshot: snapshot,
        config: _aiConfig,
        primaryGoal: StrategicGoal.expand,
        seeds: AISeedBundle.fromTurnSeed(2509230),
        suggestionAPI: _nwTribeOvertureApi,
        economyPlan: _economyPlan,
      );

      expect(
        _overtureTargets(orders),
        isNot(contains(_tribeId)),
        reason:
            'EXPAND must drop establishOverture toward NW colonial targets '
            'so the GP stays focused on OW expansion to the quota of 10 '
            '(SPEC § Observer goal phases (Full AI), EXPAND suppressions: '
            '"NW declareWar/establishOverture..."). A non-empty contains '
            'list here indicates the orchestrator surfaced an overture the '
            'scoring path collapsed to 0 — most likely a forced/short-circuit '
            'overture helper bypassing the score gate.',
      );
    });

    test(
      'COLONIAL allows establishOverture toward the same NW tribe candidate',
      () {
        final game = _scenarioGame(gp1OwProvinces: _gp1OwProvincesAtQuota);
        const topology = MapTopology(nodes: [], edges: []);
        final view = buildPlayerView(game, topology, _nationId);
        final snapshot = _colonialSnapshot();

        expect(
          observerGoalPhaseFor(snapshot: snapshot, game: game),
          ObserverGoalPhase.colonial,
          reason:
              'Negative-control fixture must place GP in COLONIAL so the '
              'EXPAND NW overture filter is verified to **not** fire here. '
              'Otherwise a regression that over-suppresses NW overture in '
              'COLONIAL (stripping the Join Empire acquisition route from '
              'SPEC § COLONIAL phase minimum rule 1) would also pass the '
              'positive case.',
        );

        final orders = runDomainPlanners(
          game: game,
          topology: topology,
          nationId: _nationId,
          view: view,
          snapshot: snapshot,
          config: _aiConfig,
          primaryGoal: StrategicGoal.conquer,
          seeds: AISeedBundle.fromTurnSeed(2509231),
          suggestionAPI: _nwTribeOvertureApi,
          economyPlan: _economyPlan,
        );

        expect(
          _overtureTargets(orders),
          contains(_tribeId),
          reason:
              'COLONIAL must allow establishOverture toward visible tribe '
              'colonial targets so Join Empire remains a reachable NW '
              'acquisition path (SPEC § COLONIAL phase, acquisition '
              'priority: Join Empire → purchase_land → declare-war). '
              'Over-suppression here would stall NW acquisition toward the '
              'turn-150 NW ownership gate.',
        );
      },
    );

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
        suggestionAPI: _nwTribeOvertureApi,
        economyPlan: _economyPlan,
      );

      final firstRun = runOnce(2509232);
      final secondRun = runOnce(2509232);

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
            '(otherwise a flaky filter or random scoring path could mask '
            'this contract under repeated runs).',
      );
    });
  });
}
