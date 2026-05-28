// Pins the COLONIAL-lite phase New World `declareWar` contract at the
// `runDomainPlanners` integration boundary after the Phase 3 soft-weight
// wiring slice (Refs #2847):
//
//   SPEC/ai/phase-planner-architecture.md § Soft-phase priority weights:
//   "The default soft-phase curve never emits `0.0` (min `0.05` at OW<=7)
//   so EXPAND and COLONIAL-lite turns now keep NW declare-war reachable
//   at low priority instead of structurally collapsing."
//
// The legacy COLONIAL-lite hard-suppress rule from issue #2509
// (`shouldSuppressNewWorldDeclareWarInvasionAndPurchase` true for
// EXPAND / COLONIAL-lite / DEVELOP) has been replaced for the
// EXPAND / COLONIAL-lite NW colonial declare-war scoring branches by a
// soft-weight gate on `_DeclareWarTargetContext.nwAcquisitionWeight`:
// `_declareWarSuppressedExpandColonialScore` and
// `_declareWarSuppressedColonialLiteScore` only collapse NW colonial
// declare-war candidates when `nwAcquisitionWeight <= 0.0`, which the
// default curve never produces. Hard structural suppression now requires
// an explicit `priorityWeights.newWorldAcquisition == 0.0` override
// (pinned by `phase_planner_diplomacy_declare_war_soft_weight_wiring_test.dart`).
// DEVELOP still routes off the boolean DEVELOP resolver and remains
// fully suppressed.
//
// Sibling orchestrator-level pins exercise the **EXPAND** half
// (`domain_planner_orchestrator_expand_nw_declare_war_suppression_test.dart`,
// PR #2647), the **COLONIAL** allow side
// (`domain_planner_orchestrator_colonial_tribe_declare_war_test.dart`,
// PR #2616), and the **DEVELOP** half
// (`domain_planner_orchestrator_develop_declare_war_suppression_test.dart`,
// PR #2619).
//
// The negative control re-runs the same scenario with one extra OW
// province (OW=10) so the GP enters **COLONIAL** instead of COLONIAL-lite.
// In COLONIAL the same `declareWar` candidate is emitted by the
// orchestrator (acquisition priority rule "Join Empire ->
// purchase_land -> declare-war + NW invasion").
//
// Coverage layers:
//   - Positive (COLONIAL-lite, default soft-phase weight): merged
//     diplomatic orders **contain** `declareWar` toward the NW tribe
//     candidate the fake API provides (OW=9, turn=120, tribe-owned NW
//     visible). A regression that re-introduces structural collapse
//     for COLONIAL-lite would fail this assert.
//   - Negative control (COLONIAL): the same `declareWar` candidate **is**
//     emitted by the orchestrator at OW=10 same turn (boundary between
//     COLONIAL-lite and COLONIAL is OW=9 vs OW=10 per
//     `isObserverColonialLitePhase` + `isBelowObserverConquestQuota`).
//   - Determinism guard (must-have #7): identical COLONIAL-lite-phase
//     inputs produce identical diplomatic-order fingerprints.

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

// COLONIAL-lite requires `oldWorldProvincesOwned >= kObserverColonialLiteNearQuotaOw`
// (9) **and** below quota (10). Sized at exactly the floor so the boundary
// (one province below quota at turn >= 120) is the regime under test.
const List<String> _gp1OwProvincesAtColonialLiteFloor = <String>[
  'oldWorld|gp1_0',
  'oldWorld|gp1_1',
  'oldWorld|gp1_2',
  'oldWorld|gp1_3',
  'oldWorld|gp1_4',
  'oldWorld|gp1_5',
  'oldWorld|gp1_6',
  'oldWorld|gp1_7',
  'oldWorld|gp1_8',
];

// At quota (`kObserverConquestMinOwProvincesPerGp` = 10). The negative
// control places the GP one province above the COLONIAL-lite floor so the
// phase tips to COLONIAL while every other fixture parameter stays the same.
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
];

Game _scenarioGame({required List<String> gp1OwProvinces}) {
  return Game(
    id: 'g-2509-colonial-lite-nw-declare-suppress',
    worldState: WorldState(
      // turnNumber == kObserverColonialLiteMinTurn (120) keeps the fixture
      // inside the COLONIAL-lite window (positive case) while leaving the
      // negative control free to flip to COLONIAL purely via the OW count.
      turnState: TurnState(
        phase: TurnPhase.orders,
        turnNumber: kObserverColonialLiteMinTurn,
      ),
      oldWorld: RegionData(
        provinces: [
          for (final id in gp1OwProvinces)
            Province(id: id, regionId: 'oldWorld', ownerId: _nationId),
        ],
      ),
      // One tribe-owned NW province keeps `globalNewWorldHasNonGpOwnership`
      // true so the COLONIAL-lite eligibility predicate fires at OW=9 turn
      // 120 (`isObserverColonialLitePhase`).
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
      // peace paths — same guard pattern as the EXPAND/DEVELOP NW
      // declareWar suppression sibling pins.
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
    // phase-keyed scoring + selection pass is what enforces the
    // COLONIAL-lite suppression vs COLONIAL emission contract this file
    // pins.
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
// under test for the SPEC COLONIAL-lite `declareWar` suppression rule.
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

// `henry` + `merchant` matches the personality/agenda used by the EXPAND NW
// declareWar suppression sibling pin
// (`domain_planner_orchestrator_expand_nw_declare_war_suppression_test.dart`)
// and the COLONIAL-lite work-order pin
// (`domain_planner_orchestrator_colonial_lite_test.dart`).
// `peacemaker` is intentionally avoided — that agenda zeroes declareWar
// candidates regardless of phase and would confound both the COLONIAL-lite
// positive (already-zero score) and the COLONIAL negative control.
const AIConfig _aiConfig = AIConfig(
  leaderId: 'henry',
  personalityId: 'henry',
  hiddenAgendaId: 'merchant',
);

AIWorldSnapshot _colonialLiteSnapshot() {
  return const AIWorldSnapshot(
    playerId: _nationId,
    threats: ThreatSummary(),
    opportunities: OpportunitySummary(),
    // 9 OW provinces -> below quota (matches `_gp1OwProvincesAtColonialLiteFloor`).
    // Combined with turn=120 and a non-GP-owned NW province in the
    // fixture this lands the GP in COLONIAL-lite per
    // `isObserverColonialLitePhase`.
    conquest: ConquestSummary(
      oldWorldProvincesOwned: kObserverColonialLiteNearQuotaOw,
      provincesToVictory: 22,
    ),
    // Tribe is both a visible NW invadable owner **and** a preferred
    // colonial target so every `declareWar` scoring-collapse predicate in
    // `computeDiplomaticCandidateScores` for COLONIAL-lite is exercised
    // (tribe / preferred / invadable owner) — mirrors the EXPAND NW
    // declareWar suppression fixture.
    colonial: ColonialSummary(
      newWorldProvincesOwned: 0,
      invadableNewWorldProvinceIdsSorted: [_tribeNwProvince],
      adjacentNewWorldOwnerFactionIdsSorted: [_tribeId],
      preferredColonialTargetFactionIdsSorted: [_tribeId],
    ),
    economy: EconomySummary(ownProvinceCount: 9),
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
    // 10 OW provinces -> at quota (matches `_gp1OwProvincesAtQuota`).
    // `isBelowObserverConquestQuota(10)` -> false so COLONIAL-lite cannot
    // fire even at turn 120, and `hasColonialAcquisitionTargets` true
    // places the GP in COLONIAL. Boundary differs from the positive case
    // by a single OW province.
    conquest: ConquestSummary(
      oldWorldProvincesOwned: kObserverConquestMinOwProvincesPerGp,
      provincesToVictory: 21,
    ),
    colonial: ColonialSummary(
      newWorldProvincesOwned: 0,
      invadableNewWorldProvinceIdsSorted: [_tribeNwProvince],
      adjacentNewWorldOwnerFactionIdsSorted: [_tribeId],
      preferredColonialTargetFactionIdsSorted: [_tribeId],
    ),
    economy: EconomySummary(ownProvinceCount: 10),
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
  group(
    'runDomainPlanners COLONIAL-lite-phase NW declareWar suppression',
    () {
      test(
        'COLONIAL-lite keeps declareWar toward NW tribe colonial target scorable at default soft-phase weight',
        () {
          final game = _scenarioGame(
            gp1OwProvinces: _gp1OwProvincesAtColonialLiteFloor,
          );
          const topology = MapTopology(nodes: [], edges: []);
          final view = buildPlayerView(game, topology, _nationId);
          final snapshot = _colonialLiteSnapshot();

          expect(
            observerGoalPhaseFor(snapshot: snapshot, game: game),
            ObserverGoalPhase.colonialLite,
            reason:
                'Fixture must place GP in COLONIAL-lite so the NW '
                'declareWar suppression contract is exercised by the '
                'orchestrator. EXPAND (turn < 120) or COLONIAL (OW >= 10) '
                'mis-tagging would either over-suppress the positive case '
                '(and pass for the wrong reason) or skip the COLONIAL-lite '
                'branch under test entirely.',
          );

          final orders = runDomainPlanners(
            game: game,
            topology: topology,
            nationId: _nationId,
            view: view,
            snapshot: snapshot,
            config: _aiConfig,
            primaryGoal: StrategicGoal.expand,
            seeds: AISeedBundle.fromTurnSeed(2509300),
            suggestionAPI: _nwTribeDeclareWarApi,
            economyPlan: _economyPlan,
          );

          expect(
            _declareWarTargets(orders),
            contains(_tribeId),
            reason:
                'Phase 3 diplomacy declare-war wiring (Refs #2847; SPEC '
                '§ Soft-phase priority weights) replaces the legacy '
                'hard structural collapse with a soft-weight gate on '
                '`nwAcquisitionWeight`. The default soft-phase curve at '
                'OW=9 yields `newWorldAcquisition == 0.20` (> 0.0), so '
                'COLONIAL-lite must keep NW colonial declare-war '
                'candidates scorable at low priority instead of '
                'structurally collapsing them. Hard-suppress is now '
                'only reached via an explicit `priorityWeights.newWorldAcquisition '
                '== 0.0` override, pinned by '
                '`phase_planner_diplomacy_declare_war_soft_weight_wiring_test.dart`.',
          );
        },
      );

      test(
        'COLONIAL (OW=10) keeps declareWar toward the same NW tribe candidate',
        () {
          final game = _scenarioGame(
            gp1OwProvinces: _gp1OwProvincesAtQuota,
          );
          const topology = MapTopology(nodes: [], edges: []);
          final view = buildPlayerView(game, topology, _nationId);
          final snapshot = _colonialSnapshot();

          expect(
            observerGoalPhaseFor(snapshot: snapshot, game: game),
            ObserverGoalPhase.colonial,
            reason:
                'Negative-control fixture must place GP in COLONIAL so '
                'the COLONIAL-lite NW declareWar filter is verified to '
                '**not** fire here. The only fixture difference vs the '
                'positive case is the OW count (9 -> 10), which is the '
                'COLONIAL-lite/COLONIAL boundary per '
                'isBelowObserverConquestQuota + isObserverColonialLitePhase.',
          );

          final orders = runDomainPlanners(
            game: game,
            topology: topology,
            nationId: _nationId,
            view: view,
            snapshot: snapshot,
            config: _aiConfig,
            primaryGoal: StrategicGoal.conquer,
            seeds: AISeedBundle.fromTurnSeed(2509301),
            suggestionAPI: _nwTribeDeclareWarApi,
            economyPlan: _economyPlan,
          );

          expect(
            _declareWarTargets(orders),
            contains(_tribeId),
            reason:
                'COLONIAL must allow declareWar toward visible tribe '
                'colonial targets so the SPEC § COLONIAL phase acquisition '
                'priority "Join Empire -> purchase_land -> declare-war + '
                'NW invasion" remains reachable once the GP hits the OW '
                'quota. Over-suppression here would stall NW acquisition '
                'toward the turn-150 NW ownership gate and collapse the '
                'COLONIAL-lite/COLONIAL distinction into a single rule.',
          );
        },
      );

      test(
        'emits identical diplomatic orders for identical COLONIAL-lite inputs',
        () {
          final game = _scenarioGame(
            gp1OwProvinces: _gp1OwProvincesAtColonialLiteFloor,
          );
          const topology = MapTopology(nodes: [], edges: []);
          final view = buildPlayerView(game, topology, _nationId);
          final snapshot = _colonialLiteSnapshot();

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
          );

          final firstRun = runOnce(2509302);
          final secondRun = runOnce(2509302);

          List<String> diplomaticFingerprint(Orders orders) => <String>[
            for (final o
                in orders.diplomaticOrdersByPlayerId[_nationId] ?? const [])
              '${o.type}|${o.targetFactionId}|${o.overtureStage}',
          ];

          expect(
            diplomaticFingerprint(secondRun),
            diplomaticFingerprint(firstRun),
            reason:
                'Determinism (must-have #7): identical COLONIAL-lite-phase '
                'inputs must produce identical diplomatic orders across '
                'runs (otherwise a flaky filter or random scoring path '
                'could mask this contract under repeated runs).',
          );
        },
      );
    },
  );
}
