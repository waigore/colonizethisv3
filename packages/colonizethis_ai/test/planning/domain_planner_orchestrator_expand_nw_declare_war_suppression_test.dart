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

const String _nationId = 'gp1';
const String _tribeId = 'tribe1';
const String _tribeNwProvince = 'newWorld|tribe1_nw0';

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

// Sub-quota OW set (< `kObserverConquestMinOwProvincesPerGp` = 10) so
// `isBelowObserverConquestQuota` is true and the GP enters EXPAND per
// `observerGoalPhaseFor`. Mirrors the EXPAND fixture shape used by the
// sibling NW overture / NW work-suppression orchestrator pins.
const List<String> _gp1OwProvincesBelowQuota = <String>[
  'oldWorld|gp1_0',
  'oldWorld|gp1_1',
  'oldWorld|gp1_2',
  'oldWorld|gp1_3',
  'oldWorld|gp1_4',
  'oldWorld|gp1_5',
  'oldWorld|gp1_6',
];

// At-quota OW set (>= `kObserverConquestMinOwProvincesPerGp` = 10) so the
// GP passes the EXPAND gate and enters COLONIAL when colonial acquisition
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
    id: 'g-2509-expand-nw-declare-suppress',
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
      // Non-empty Home Army for gp1 keeps `regimentCountForPlayer` > 0 so
      // the orchestrator does not divert into the zero-regiment stalemate
      // peace paths (`stalledZeroRegimentGpPeaceTargets`,
      // `mutualZeroRegimentGpStalematePeaceTargets`) — same guard pattern
      // as `domain_planner_orchestrator_expand_nw_overture_suppression_test.dart`.
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
    // Peace is the structural precondition for a `declareWar` candidate to
    // be valid (declaring on an already-at-war target is meaningless). The
    // fake API surfaces the candidate unconditionally; the orchestrator's
    // EXPAND scoring + selection pass is what enforces the suppression vs
    // COLONIAL emission contract this file pins.
    diplomacyRelations: const [
      DiplomacyRelation(
        factionId1: _nationId,
        factionId2: _tribeId,
        state: RelationState.atPeace,
        score: 0,
      ),
    ],
  );
}

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
    // colonial target so the EXPAND `declareWar` score collapse path in
    // `computeDiplomaticCandidateScores` is exercised across all
    // triggering predicates (tribe / preferred / invadable owner) —
    // matches the scoring-level fixture for `EXPAND suppresses NW
    // declareWar scoring`.
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
        score: 0,
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
    // visible. The EXPAND NW declareWar suppression must **not** fire
    // here so the COLONIAL acquisition path "declare-war + NW invasion"
    // remains reachable (SPEC § COLONIAL phase, acquisition priority).
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
        score: 0,
      ),
    },
  );
}

List<String> _declareWarTargets(Orders orders) => <String>[
  for (final order
      in orders.diplomaticOrdersByPlayerId[_nationId] ?? const [])
    if (order.type == DiplomaticOrderType.declareWar) order.targetFactionId,
];

void main() {
  group('runDomainPlanners EXPAND-phase NW declareWar suppression', () {
    test('EXPAND drops declareWar toward NW tribe colonial target', () {
      final game = _scenarioGame(gp1OwProvinces: _gp1OwProvincesBelowQuota);
      const topology = MapTopology(nodes: [], edges: []);
      final view = buildPlayerView(game, topology, _nationId);
      final snapshot = _expandSnapshot();

      expect(
        observerGoalPhaseFor(snapshot: snapshot, game: game),
        ObserverGoalPhase.expand,
        reason:
            'Fixture must place GP in EXPAND so the NW declareWar '
            'suppression contract is exercised by the orchestrator, not '
            'the COLONIAL fall-through (which has separate diplomacy '
            'rules that allow tribe declare-war).',
      );

      final orders = runDomainPlanners(
        game: game,
        topology: topology,
        nationId: _nationId,
        view: view,
        snapshot: snapshot,
        config: _aiConfig,
        primaryGoal: StrategicGoal.expand,
        seeds: AISeedBundle.fromTurnSeed(2509240),
        suggestionAPI: _nwTribeDeclareWarApi,
        economyPlan: _economyPlan,
        // Pin the legacy EXPAND hard-suppress contract by threading an
        // explicit `newWorldAcquisition = 0.0` override through the
        // orchestrator (Refs #2847 Phase 3). Under the soft-weight
        // production curve `_curveWeightsForOw(7)` returns 0.05 and the
        // scoring path now keeps NW declare-war reachable at low
        // priority — see
        // `phase_planner_diplomacy_declare_war_nw_suppression_test.dart`.
        // This test continues to assert the strict regression contract.
        options: OrchestratorOptions(phasePlan: _expandPhasePlanHardSuppressNw),
      );

      expect(
        _declareWarTargets(orders),
        isNot(contains(_tribeId)),
        reason:
            'Under the explicit `newWorldAcquisition = 0.0` override '
            '(legacy hard-suppress regression contract), EXPAND must '
            'drop declareWar toward NW colonial targets so the GP stays '
            'focused on OW expansion to the quota of 10 (SPEC § Observer '
            'goal phases (Full AI), EXPAND suppressions: "NW declareWar/'
            'establishOverture..."). A non-empty contains list here '
            'indicates the orchestrator surfaced a declareWar the '
            'scoring path should have collapsed to 0 — most likely a '
            'forced/short-circuit declare-war helper bypassing the '
            'score gate.',
      );
    });

    test(
      'COLONIAL allows declareWar toward the same NW tribe candidate',
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
              'EXPAND NW declareWar filter is verified to **not** fire '
              'here. Otherwise a regression that over-suppresses NW '
              'declareWar in COLONIAL (stripping the war + invasion '
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
          seeds: AISeedBundle.fromTurnSeed(2509241),
          suggestionAPI: _nwTribeDeclareWarApi,
          economyPlan: _economyPlan,
        );

        expect(
          _declareWarTargets(orders),
          contains(_tribeId),
          reason:
              'COLONIAL must allow declareWar toward visible tribe '
              'colonial targets so the SPEC COLONIAL acquisition '
              'priority "Join Empire -> purchase_land -> declare-war + '
              'NW invasion" remains reachable. Over-suppression here '
              'would stall NW acquisition toward the turn-150 NW '
              'ownership gate.',
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
        suggestionAPI: _nwTribeDeclareWarApi,
        economyPlan: _economyPlan,
        options: OrchestratorOptions(phasePlan: _expandPhasePlanHardSuppressNw),
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
