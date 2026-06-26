// Pins the COLONIAL-lite phase **NW invasion army move suppression** at the
// `runDomainPlanners` integration boundary (Refs #2509 S10).
//
//   SPEC/ai/ai-architecture.md § Observer goal phases (Full AI), COLONIAL-lite:
//     "turn >= kObserverColonialLiteMinTurn (120), OW
//      >= kObserverColonialLiteNearQuotaOw (9) and below quota, global
//      newWorld| not all GP-owned: allows establishOverture, colonial
//      naval/cargo; suppresses NW declareWar, **invasion army moves**, and
//      purchase_land only."
//
// Coverage map for the COLONIAL-lite three-part suppression contract at the
// orchestrator boundary:
//
// | Suppression                       | Existing orchestrator pin                                                |
// |-----------------------------------|--------------------------------------------------------------------------|
// | NW `purchase_land` (work)         | `domain_planner_orchestrator_colonial_lite_test.dart`                    |
// | NW `declareWar` (diplomacy)       | `domain_planner_orchestrator_colonial_lite_declare_war_suppression_test` |
// | NW invasion `ArmyMoveOrder`       | **this file**                                                            |
//
// The underlying predicate
// (`shouldSuppressNewWorldDeclareWarInvasionAndPurchase` returning `true` in
// COLONIAL-lite) is pinned at the unit level in
// `observer_goal_phase_test.dart` group `observerGoalPhaseFor`. The
// **conquest-planner integration** that consumes that predicate — building
// the `invadable` set (`conquest_planner.dart:162-169`) and short-circuiting
// `_scoreArmyMoveDestination` to `0` for NW invadable destinations
// (`conquest_planner.dart:457-464`) under
// `shouldSuppressNewWorldDeclareWarInvasionAndPurchase` — is not currently
// asserted at the `runDomainPlanners` boundary for the COLONIAL-lite branch.
// A tuning slice that left the predicate intact but rewired the conquest
// planner (for example by using `shouldSuppressNewWorldColonialOrders`
// (EXPAND-only) instead, or by dropping the NW short-circuit in
// `_scoreArmyMoveDestination`) could silently emit NW invasion army moves
// from near-quota GPs at turn 120, eroding OW expansion pressure exactly
// when the COLONIAL-lite safeguard is supposed to keep both OW and NW
// progress in motion without trading the turn-100 OW gate for NW work.
//
// The mixed-candidate fixture mirrors
// `domain_planner_orchestrator_expand_nw_work_suppression_test.dart`'s sibling
// pin "EXPAND conquest army move prefers OW invadable minor over NW tribe":
// one OW invadable minor + one NW tribe province as the two army-move
// candidates for a single field army. In COLONIAL-lite the OW path stays
// invadable (the GP is below quota and at war with the minor), while the NW
// path must be scored to `0` by
// `shouldSuppressNewWorldDeclareWarInvasionAndPurchase` and dropped by the
// conquest planner's stalled multi-army selection. The negative control
// re-runs the same fixture at OW=10 (COLONIAL) where the NW invasion
// suppression must not fire — proving the orchestrator does not over-suppress
// NW army moves once the OW quota is met.
//
// Coverage layers:
//   - Positive (COLONIAL-lite): NW invasion army move dropped, OW invadable
//     army move kept (chosen by the stalled multi-army fallback).
//   - Negative control (COLONIAL): same fixture at OW=10; NW invasion army
//     move survives because COLONIAL is the only phase where
//     `shouldSuppressNewWorldDeclareWarInvasionAndPurchase` returns `false`.
//   - Determinism guard (must-have #7): identical COLONIAL-lite inputs
//     produce identical army move order fingerprints across runs.

import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/observer_goal_phase.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../domain_planner_test_fake_api.dart';

const String _nationId = 'gp1';
const String _tribeId = 'tribe1';
const String _minorId = 'minor1';
const String _owProvincePrefix = 'oldWorld|gp1_';
const String _owMinorProvince = 'oldWorld|minor1_p0';
const String _owFieldArmyHome = 'oldWorld|gp1_0';
const String _nwTribeProvince = 'newWorld|tribe1_nw0';
const String _fieldArmyId = 'field_a';

// 9 OW provinces matches `kObserverColonialLiteNearQuotaOw`; turn 120 vs an
// earlier turn flips the COLONIAL-lite / EXPAND decision in
// `isObserverColonialLitePhase`. The COLONIAL negative control raises OW to 10
// (quota met) and reuses the same fixture otherwise.
List<String> _gpOwProvincesAt(int count) => <String>[
  for (var i = 0; i < count; i++) '$_owProvincePrefix$i',
];

/// Builds a GP scenario with:
///   - `gpOwProvinceCount` GP-owned OW provinces (9 → near-quota; 10 → quota).
///   - One OW minor-owned invadable province (`_owMinorProvince`) the GP is
///     already at war with — gives the stalled multi-army fallback a positive
///     OW candidate so the COLONIAL-lite suppression's effect (drop NW) is
///     observable as a phase contract, not a "nothing selected" side effect.
///   - One tribe-owned NW province (`_nwTribeProvince`) that the GP is at war
///     with — satisfies both
///     [globalNewWorldHasNonGpOwnership] (COLONIAL-lite precondition) and the
///     `filterArmyMoveOrdersByDiplomacy` at-war passthrough so the NW invasion
///     candidate reaches the conquest planner's scoring path.
///   - One field army stationed in the GP's home OW province so the fake API
///     can submit cross-region army-move candidates with consistent army id.
Game _scenarioGame({
  required int turnNumber,
  required int gpOwProvinceCount,
}) {
  final gpOwProvinces = _gpOwProvincesAt(gpOwProvinceCount);
  return Game(
    id: 'g-2509-colonial-lite-invasion-army-move-suppression',
    worldState: WorldState(
      turnState: TurnState(
        phase: TurnPhase.orders,
        turnNumber: turnNumber,
      ),
      oldWorld: RegionData(
        provinces: [
          for (final id in gpOwProvinces)
            Province(id: id, regionId: 'oldWorld', ownerId: _nationId),
          const Province(
            id: _owMinorProvince,
            regionId: 'oldWorld',
            ownerId: _minorId,
          ),
        ],
      ),
      newWorld: const RegionData(
        provinces: [
          Province(
            id: _nwTribeProvince,
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
          stationedProvinceId: _owFieldArmyHome,
          regimentUnitIds: const ['u_home'],
          isHomeArmy: true,
        ),
        Army(
          id: _fieldArmyId,
          ownerId: _nationId,
          regionId: 'oldWorld',
          stationedProvinceId: _owFieldArmyHome,
          regimentUnitIds: const ['u_field'],
          isHomeArmy: false,
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
    minorNations: const [MinorNation(id: _minorId, displayName: 'M1')],
    diplomacyRelations: const [
      DiplomacyRelation(
        factionId1: _nationId,
        factionId2: _tribeId,
        state: RelationState.atWar,
        score: -20,
      ),
      DiplomacyRelation(
        factionId1: _nationId,
        factionId2: _minorId,
        state: RelationState.atWar,
        score: -20,
      ),
    ],
  );
}

/// Fake suggestion API surfacing the two phase-distinguishing army-move
/// candidates: one OW invadable minor (must survive in COLONIAL-lite) and one
/// NW tribe invadable (must be dropped in COLONIAL-lite, kept in COLONIAL).
///
/// Mirrors `_mixedOwNwArmyMoveApi` from
/// `domain_planner_orchestrator_expand_nw_work_suppression_test.dart` so the
/// two phase pins exercise the same orchestrator code path with the same
/// candidate shape.
const FakeOrderSuggestionAPIForDomainPlannerTests _mixedOwNwArmyMoveApi =
    FakeOrderSuggestionAPIForDomainPlannerTests(
  work: [],
  build: [],
  move: [],
  research: [],
  navalMove: [],
  navalMission: [],
  armyMove: [
    ArmyMoveOrder(
      armyId: _fieldArmyId,
      destinationProvinceId: _nwTribeProvince,
    ),
    ArmyMoveOrder(
      armyId: _fieldArmyId,
      destinationProvinceId: _owMinorProvince,
    ),
  ],
);

const EconomyPlan _economyPlan = EconomyPlan(
  productionAssignments: [],
  cargoPreference: CargoPreference.none,
);

// `henry` + `merchant` matches `domain_planner_orchestrator_colonial_lite_test`
// so the existing COLONIAL-lite pin and this army-move pin share personality
// inputs and a regression that selectively breaks one phase decision is more
// likely to fail both files together (helps triage).
const AIConfig _aiConfig = AIConfig(
  leaderId: 'henry',
  personalityId: 'henry',
  hiddenAgendaId: 'merchant',
);

AIWorldSnapshot _snapshotFor({required int oldWorldProvincesOwned}) {
  return AIWorldSnapshot(
    playerId: _nationId,
    threats: const ThreatSummary(atWarWith: [_minorId, _tribeId]),
    opportunities: const OpportunitySummary(),
    conquest: ConquestSummary(
      oldWorldProvincesOwned: oldWorldProvincesOwned,
      invadableProvinceIdsSorted: const [_owMinorProvince],
    ),
    colonial: const ColonialSummary(
      invadableNewWorldProvinceIdsSorted: [_nwTribeProvince],
      adjacentNewWorldOwnerFactionIdsSorted: [_tribeId],
      preferredColonialTargetFactionIdsSorted: [_tribeId],
    ),
    economy: const EconomySummary(ownProvinceCount: 9),
    relations: const {
      _tribeId: DiplomacyRelation(
        factionId1: _nationId,
        factionId2: _tribeId,
        state: RelationState.atWar,
        score: -20,
      ),
      _minorId: DiplomacyRelation(
        factionId1: _nationId,
        factionId2: _minorId,
        state: RelationState.atWar,
        score: -20,
      ),
    },
  );
}

List<ArmyMoveOrder> _armyMoves(Orders orders) =>
    orders.armyMoveOrdersByPlayerId[_nationId] ?? const [];

void main() {
  group('runDomainPlanners COLONIAL-lite NW invasion army move suppression', () {
    test(
      'COLONIAL-lite drops NW invasion army move, keeps OW invadable minor move',
      () {
        // Turn 120 + OW=9 + tribe-owned NW = COLONIAL-lite per
        // `isObserverColonialLitePhase`. The conquest planner is in stalled
        // expansion (below quota), so the multi-army fallback path runs.
        final game = _scenarioGame(
          turnNumber: kObserverColonialLiteMinTurn,
          gpOwProvinceCount: kObserverColonialLiteNearQuotaOw,
        );
        const topology = MapTopology(nodes: [], edges: []);
        final view = buildPlayerView(game, topology, _nationId);
        final snapshot = _snapshotFor(
          oldWorldProvincesOwned: kObserverColonialLiteNearQuotaOw,
        );

        expect(
          observerGoalPhaseFor(snapshot: snapshot, game: game),
          ObserverGoalPhase.colonialLite,
          reason:
              'Fixture must place GP in COLONIAL-lite so the SPEC § '
              'COLONIAL-lite "invasion army moves" suppression is exercised '
              'by the orchestrator. EXPAND would over-suppress unrelated '
              'paths (work / overture) so the COLONIAL-lite branch must own '
              'this contract.',
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
          suggestionAPI: _mixedOwNwArmyMoveApi,
          economyPlan: _economyPlan,
        );

        final armyMoves = _armyMoves(orders);
        expect(
          armyMoves,
          isNotEmpty,
          reason:
              'COLONIAL-lite is still below the OW quota and at war with an '
              'invadable OW minor — the conquest planner must emit the OW '
              'army move so the suppression contract is observable as a '
              'phase choice rather than a "no orders" side effect.',
        );
        expect(
          armyMoves.any(
            (m) => m.destinationProvinceId == _nwTribeProvince,
          ),
          isFalse,
          reason:
              'COLONIAL-lite must drop NW invasion army moves (SPEC § '
              'COLONIAL-lite: suppress list is "NW declareWar, invasion '
              'army moves, purchase_land only"). A surviving NW '
              'army move here indicates either the conquest planner '
              'stopped consulting shouldSuppressNewWorldDeclareWarInvasion'
              'AndPurchase when building the invadable set / scoring NW '
              'destinations, or the orchestrator started forwarding the '
              'EXPAND predicate (shouldSuppressNewWorldColonialOrders) — '
              'both regressions would let near-quota GPs at turn 120 '
              'burn turns invading tribes instead of pushing to OW=10.',
        );
        expect(
          armyMoves.any(
            (m) => m.destinationProvinceId == _owMinorProvince,
          ),
          isTrue,
          reason:
              'COLONIAL-lite must keep the OW invadable minor army move so '
              'GPs near the OW quota continue applying expansion pressure '
              'toward the turn-100 / turn-120 OW threshold (must-have #5: '
              'OW conquest pressure not weakened by NW work).',
        );
      },
    );

    test(
      'COLONIAL control: turn 120 with OW=10 keeps NW invasion army move',
      () {
        // Same turn 120 + tribe-owned NW fixture, but OW=10 meets the
        // observer quota → phase becomes COLONIAL. COLONIAL is the only
        // phase where shouldSuppressNewWorldDeclareWarInvasionAndPurchase
        // returns false; the NW invasion army move must survive.
        final game = _scenarioGame(
          turnNumber: kObserverColonialLiteMinTurn,
          gpOwProvinceCount: kObserverConquestMinOwProvincesPerGp,
        );
        const topology = MapTopology(nodes: [], edges: []);
        final view = buildPlayerView(game, topology, _nationId);
        final snapshot = _snapshotFor(
          oldWorldProvincesOwned: kObserverConquestMinOwProvincesPerGp,
        );

        expect(
          observerGoalPhaseFor(snapshot: snapshot, game: game),
          ObserverGoalPhase.colonial,
          reason:
              'Negative-control fixture must place GP in COLONIAL so the '
              'COLONIAL-lite suppression is verified to **not** fire here. '
              'Otherwise a regression that mis-tags COLONIAL as COLONIAL-'
              'lite (over-suppressing post-quota NW invasion) would also '
              'pass the positive case.',
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
          suggestionAPI: _mixedOwNwArmyMoveApi,
          economyPlan: _economyPlan,
        );

        final armyMoves = _armyMoves(orders);
        expect(
          armyMoves.any(
            (m) => m.destinationProvinceId == _nwTribeProvince,
          ),
          isTrue,
          reason:
              'COLONIAL must allow NW invasion army moves toward visible '
              'colonial targets — this is the key contract differentiating '
              'COLONIAL from COLONIAL-lite. A dropped NW move here means '
              'the COLONIAL-lite suppression leaked into COLONIAL and the '
              'orchestrator is over-filtering post-quota NW work (which '
              'would make the turn-150 NW ownership gate unreachable).',
        );
      },
    );

    test(
      'emits identical army move orders for identical COLONIAL-lite inputs',
      () {
        // Determinism guard for must-have #7. The COLONIAL-lite phase
        // decision depends on game.turnNumber + snapshot.conquest +
        // globalNewWorldHasNonGpOwnership(game); a flaky path here would
        // mask the suppression contract by intermittently mis-tagging the
        // phase.
        final game = _scenarioGame(
          turnNumber: kObserverColonialLiteMinTurn,
          gpOwProvinceCount: kObserverColonialLiteNearQuotaOw,
        );
        const topology = MapTopology(nodes: [], edges: []);
        final view = buildPlayerView(game, topology, _nationId);
        final snapshot = _snapshotFor(
          oldWorldProvincesOwned: kObserverColonialLiteNearQuotaOw,
        );

        Orders runOnce(int turnSeed) => runDomainPlanners(
          game: game,
          topology: topology,
          nationId: _nationId,
          view: view,
          snapshot: snapshot,
          config: _aiConfig,
          primaryGoal: StrategicGoal.expand,
          seeds: AISeedBundle.fromTurnSeed(turnSeed),
          suggestionAPI: _mixedOwNwArmyMoveApi,
          economyPlan: _economyPlan,
        );

        final first = runOnce(2509242);
        final second = runOnce(2509242);

        List<String> armyFingerprint(Orders orders) => <String>[
          for (final m in _armyMoves(orders))
            '${m.armyId}|${m.destinationProvinceId}',
        ];

        expect(
          armyFingerprint(second),
          armyFingerprint(first),
          reason:
              'Determinism (must-have #7): identical COLONIAL-lite inputs '
              'must produce identical army move orders so a flaky phase-'
              'gate path cannot mask the NW invasion suppression contract.',
        );
      },
    );
  });
}
