// Pins the COLONIAL-lite phase **naval move ALLOW** contract at the
// `runDomainPlanners` integration boundary (Refs #2509 S10).
//
//   SPEC/ai/ai-architecture.md § Observer goal phases (Full AI),
//   COLONIAL-lite: "turn >= kObserverColonialLiteMinTurn (120), OW
//   >= kObserverColonialLiteNearQuotaOw (9) and below quota, global
//   newWorld| not all GP-owned: **allows establishOverture, colonial
//   naval/cargo**; suppresses NW declareWar, invasion army moves, and
//   purchase_land only."
//
// Coverage map for the COLONIAL-lite contract at the orchestrator boundary:
//
// | Contract                          | Existing orchestrator pin                                                |
// |-----------------------------------|--------------------------------------------------------------------------|
// | NW `purchase_land` suppressed     | `domain_planner_orchestrator_colonial_lite_test.dart`                    |
// | NW `build_improvement` allowed    | `domain_planner_orchestrator_colonial_lite_test.dart`                    |
// | NW-tribe `establishOverture`      | `domain_planner_orchestrator_colonial_lite_test.dart`                    |
// | NW `declareWar` suppressed        | `domain_planner_orchestrator_colonial_lite_declare_war_suppression_test` |
// | NW invasion `ArmyMoveOrder`       | `domain_planner_orchestrator_colonial_lite_invasion_army_move_suppression_test` |
// | Colonial naval move **allowed**   | **this file**                                                            |
//
// `runNavalPlanner` (`packages/colonizethis_ai/lib/src/planning/naval_planner.dart`)
// gates the colonial-pressure naval boost on
// `!shouldSuppressNewWorldColonialOrders(...)` (EXPAND-only suppression):
//
//   final hasColonialTargets = hasColonialAcquisitionTargets(colonial) &&
//       !shouldSuppressNewWorldColonialOrders(
//         snapshot: snapshot,
//         game: ctx.game,
//       );
//   if (hasColonialTargets) {
//     weight += kColonialNavalWeightBonus;          // +65
//   }
//   if (hasColonialTargets && weight < kColonialNavalMinWeightWhenPressure) {
//     weight = kColonialNavalMinWeightWhenPressure; // floor 85
//   }
//   if (weight < 25) return ctx.orders;             // skip planner entirely
//
// `shouldSuppressNewWorldColonialOrders` returns `true` only in EXPAND
// (`observer_goal_phase.dart`), so COLONIAL-lite **must** receive the
// colonial naval boost: the SPEC explicitly allows "colonial naval/cargo"
// in COLONIAL-lite. A tuning slice that swapped that predicate for
// `shouldSuppressNewWorldDeclareWarInvasionAndPurchase` (which **does**
// fire in COLONIAL-lite to gate `declareWar` / invasion / `purchase_land`)
// would silently strip the colonial naval boost and the naval planner
// would skip in COLONIAL-lite for a low-military leader (henry: military
// weight 20, below the 25 floor) — eroding the "allows colonial
// naval/cargo" half of the COLONIAL-lite safeguard exactly when the
// near-quota GP needs naval missions to keep NW expansion alive while OW
// expansion catches up.
//
// The negative control re-runs the same scenario at turn 90 so the GP
// stays in EXPAND. EXPAND suppresses colonial naval orders via
// `shouldSuppressNewWorldColonialOrders`, dropping `hasColonialTargets` to
// `false`. With `primaryGoal = expand` the naval base weight resolves to
// `domainWeights.military = 20` for henry (`ai_personality_config.dart`),
// no colonial boost applies, and the planner short-circuits at `weight < 25`
// — emitting **zero** naval moves. The contrast is deterministic and does
// not depend on the rng-based `take = 1 + rng.nextInt(cap)` EXPAND fallback,
// because the planner returns before reaching the `take` calculation.
//
// Coverage layers:
//   - Positive (COLONIAL-lite): naval move toward the NW-priority sea zone
//     is emitted; orchestrator-level evidence of "allows colonial naval".
//   - Negative control (EXPAND): same fixture at turn 90; naval planner
//     short-circuits (military 20 < 25 floor, no colonial boost) and no
//     naval move orders are emitted.
//   - Determinism guard (must-have #7): identical COLONIAL-lite inputs
//     produce identical naval move order fingerprints across runs.

import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/observer_goal_phase.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../domain_planner_test_fake_api.dart';

const String _nationId = 'gp1';
const String _tribeId = 'tribe1';
const String _owProvincePrefix = 'oldWorld|gp1_';
const String _nwTribeProvince = 'newWorld|tribe1_nw0';
const String _fleetId = 'f_nw';
const String _nwSeaZoneId = 'newWorld|sea_priority';

// 9 GP-owned OW provinces (`kObserverColonialLiteNearQuotaOw`). At turn
// `kObserverColonialLiteMinTurn` the GP enters COLONIAL-lite; at turn 90
// the same OW count keeps the GP in EXPAND (the EXPAND/COLONIAL-lite
// branch flips purely on the turn number, isolating the contract under
// test).
const List<String> _gp1OwProvincesNearQuota = <String>[
  '${_owProvincePrefix}0',
  '${_owProvincePrefix}1',
  '${_owProvincePrefix}2',
  '${_owProvincePrefix}3',
  '${_owProvincePrefix}4',
  '${_owProvincePrefix}5',
  '${_owProvincePrefix}6',
  '${_owProvincePrefix}7',
  '${_owProvincePrefix}8',
];

/// Builds a near-quota GP scenario where the only NW province is owned by
/// a tribe — satisfying `isObserverColonialLitePhase`'s
/// `globalNewWorldHasNonGpOwnership` precondition. The Game holds no fleet
/// units (the `runNavalPlanner` skip check fires on `weight` only; naval
/// candidates are supplied entirely by the fake suggestion API, so the
/// fixture stays minimal).
Game _scenarioGame({required int turnNumber}) {
  return Game(
    id: 'g-2509-colonial-lite-naval-allow',
    worldState: WorldState(
      turnState: TurnState(
        phase: TurnPhase.orders,
        turnNumber: turnNumber,
      ),
      oldWorld: RegionData(
        provinces: [
          for (final id in _gp1OwProvincesNearQuota)
            Province(id: id, regionId: 'oldWorld', ownerId: _nationId),
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
    ),
    players: const [
      Player(
        id: _nationId,
        displayName: 'GP1',
        isHuman: false,
        // `henry` has the lowest military weight (20) among canonical
        // leaders (`ai_personality_config.dart`). The < 25 naval skip
        // floor depends on this — a higher-military leader (e.g.
        // `napoleon` military=90) would emit naval moves even without
        // the colonial boost, hiding the negative-control regression.
        leaderKey: 'henry',
      ),
    ],
    tribes: const [Tribe(id: _tribeId, displayName: 'T1')],
    minorNations: const [],
  );
}

/// Fake API surfaces a single colonial naval move candidate (toward a
/// `newWorld|` sea zone) so the orchestrator output cleanly reflects
/// whether the naval planner ran or short-circuited.
const FakeOrderSuggestionAPIForDomainPlannerTests _navalCandidateApi =
    FakeOrderSuggestionAPIForDomainPlannerTests(
  work: [],
  build: [],
  move: [],
  research: [],
  navalMove: [
    NavalMoveOrder(
      fleetId: _fleetId,
      destinationSeaZoneId: _nwSeaZoneId,
    ),
  ],
  navalMission: [],
);

const EconomyPlan _economyPlan = EconomyPlan(
  productionAssignments: [],
  cargoPreference: CargoPreference.none,
);

// `henry` + `merchant` matches the personality/agenda used by the COLONIAL
// personality scoring tests
// (`diplomatic_candidate_scoring_personality_colonial_divergence_test.dart`,
// `observer_goal_phase_test.dart`) and by the COLONIAL-lite orchestrator
// pin (`domain_planner_orchestrator_colonial_lite_test.dart`).
const AIConfig _aiConfig = AIConfig(
  leaderId: 'henry',
  personalityId: 'henry',
  hiddenAgendaId: 'merchant',
);

AIWorldSnapshot _nearQuotaSnapshotWithColonialTarget() {
  return const AIWorldSnapshot(
    playerId: _nationId,
    threats: ThreatSummary(),
    opportunities: OpportunitySummary(),
    // OW 9 -> below quota. Phase decided by turn number (>= 120 enters
    // COLONIAL-lite; otherwise EXPAND).
    conquest: ConquestSummary(
      oldWorldProvincesOwned: kObserverColonialLiteNearQuotaOw,
      provincesToVictory: 22,
    ),
    // Visible NW tribe province satisfies `hasColonialAcquisitionTargets`
    // — required for the colonial naval boost to engage in COLONIAL-lite.
    colonial: ColonialSummary(
      newWorldProvincesOwned: 0,
      invadableNewWorldProvinceIdsSorted: [_nwTribeProvince],
      adjacentNewWorldOwnerFactionIdsSorted: [_tribeId],
      preferredColonialTargetFactionIdsSorted: [_tribeId],
    ),
    economy: EconomySummary(ownProvinceCount: 9),
    relations: {},
  );
}

List<NavalMoveOrder> _navalMoves(Orders orders) =>
    orders.navalMoveOrdersByPlayerId[_nationId] ?? const [];

void main() {
  group('runDomainPlanners COLONIAL-lite naval move ALLOW contract', () {
    test(
      'COLONIAL-lite emits the colonial naval move candidate under the '
      'colonial pressure boost',
      () {
        final game = _scenarioGame(turnNumber: kObserverColonialLiteMinTurn);
        const topology = MapTopology(nodes: [], edges: []);
        final view = buildPlayerView(game, topology, _nationId);
        final snapshot = _nearQuotaSnapshotWithColonialTarget();

        expect(
          observerGoalPhaseFor(snapshot: snapshot, game: game),
          ObserverGoalPhase.colonialLite,
          reason:
              'Fixture must place GP in COLONIAL-lite so the colonial naval '
              'ALLOW contract is exercised, not EXPAND (which suppresses the '
              'naval colonial boost) or COLONIAL (which does not require '
              'the COLONIAL-lite safeguard).',
        );

        final orders = runDomainPlanners(
          game: game,
          topology: topology,
          nationId: _nationId,
          view: view,
          snapshot: snapshot,
          config: _aiConfig,
          // `expand` (or `conquer`/`defend`) resolves the naval base
          // weight to `domainWeights.military` for henry (20), so the
          // colonial boost is the only path past the < 25 skip floor.
          primaryGoal: StrategicGoal.expand,
          seeds: AISeedBundle.fromTurnSeed(2509200),
          suggestionAPI: _navalCandidateApi,
          economyPlan: _economyPlan,
        );

        final navalMoves = _navalMoves(orders);
        expect(
          navalMoves,
          isNotEmpty,
          reason:
              'COLONIAL-lite must allow colonial naval moves (SPEC § '
              'Observer goal phases (Full AI), COLONIAL-lite allow list: '
              '"colonial naval/cargo"). An empty list here means the '
              'colonial naval boost has been stripped in COLONIAL-lite '
              '(`hasColonialTargets` false) and `runNavalPlanner` skipped '
              'at the < 25 weight floor.',
        );
        expect(
          navalMoves.first.destinationSeaZoneId,
          _nwSeaZoneId,
          reason:
              'The single candidate targets the visible NW sea zone — when '
              'emitted, the colonial-pressure-ranked output must surface '
              'that NW destination so the COLONIAL-lite safeguard actually '
              'advances NW progress for the near-quota GP.',
        );
      },
    );

    test(
      'EXPAND control: turn 90 with the same fixture resolves to EXPAND '
      '(phase-classification negative-control for the COLONIAL-lite ALLOW '
      'contract above) — Refs #2847 Phase 3 soft-phase intent',
      () {
        // Same OW=9 + tribe-owned NW fixture, but turn 90 is below
        // `kObserverColonialLiteMinTurn` (120) so the GP stays in EXPAND
        // (`observerGoalPhaseFor` returns `ObserverGoalPhase.expand`)
        // and the positive COLONIAL-lite test above cannot pass on a
        // mis-tagged EXPAND fixture.
        //
        // Refs #2847 Phase 3 naval colonial-pressure floor wiring: the
        // legacy hard-phase EXPAND suppression of the colonial naval
        // boost is **deliberately retired** in this slice. The naval
        // colonial-pressure bonus / floor now scale linearly with the
        // soft-phase `newWorldAcquisition` weight, so at OW=9 the curve
        // weight (0.20) lifts the floor above `kNavalRunMinWeight` and
        // the planner emits the candidate even under the EXPAND phase
        // label. The actual negative-control payload for the
        // COLONIAL-lite ALLOW contract is therefore the
        // **phase-classification check** below — emitted moves no
        // longer carry information about hard-phase suppression.
        final game = _scenarioGame(turnNumber: 90);
        const topology = MapTopology(nodes: [], edges: []);
        final view = buildPlayerView(game, topology, _nationId);
        final snapshot = _nearQuotaSnapshotWithColonialTarget();

        expect(
          observerGoalPhaseFor(snapshot: snapshot, game: game),
          ObserverGoalPhase.expand,
          reason:
              'Negative-control fixture must place GP in EXPAND so the '
              'COLONIAL-lite naval ALLOW contract is verified to **not** '
              'fire here. Otherwise a regression that mis-tagged EXPAND as '
              'COLONIAL-lite (re-enabling the colonial naval boost before '
              'turn 100) would also pass the positive case.',
        );

        final orders = runDomainPlanners(
          game: game,
          topology: topology,
          nationId: _nationId,
          view: view,
          snapshot: snapshot,
          config: _aiConfig,
          primaryGoal: StrategicGoal.expand,
          seeds: AISeedBundle.fromTurnSeed(2509201),
          suggestionAPI: _navalCandidateApi,
          economyPlan: _economyPlan,
        );

        // Phase 3 soft-phase intent: at OW=9 the curve sets
        // `newWorldAcquisition = 0.20`, which lifts the naval-pass
        // weight (round(85 × 0.20) = 17 floor + base 20 + round(65 ×
        // 0.20) = 13 bonus = 33) above `kNavalRunMinWeight` so the
        // candidate is emitted even under the EXPAND phase label. The
        // empty-list legacy assertion is intentionally retired here —
        // the negative-control payload is the phase classification
        // above, not the naval-move emptiness.
        expect(
          _navalMoves(orders),
          isNotEmpty,
          reason:
              'Refs #2847 Phase 3 naval colonial-pressure floor wiring: at '
              'OW=9 the soft-phase newWorldAcquisition weight (0.20) lifts '
              'the naval-pass weight above kNavalRunMinWeight via the '
              'continuous-scale floor (round(85 × 0.20) = 17), so the '
              'EXPAND phase plan emits the colonial naval candidate — the '
              'legacy hard-phase EXPAND naval suppression is deliberately '
              'retired in this slice (negative-control payload for the '
              'COLONIAL-lite ALLOW contract is the phase-classification '
              'check above).',
        );
      },
    );

    test(
      'emits identical naval move orders for identical COLONIAL-lite inputs',
      () {
        final game = _scenarioGame(turnNumber: kObserverColonialLiteMinTurn);
        const topology = MapTopology(nodes: [], edges: []);
        final view = buildPlayerView(game, topology, _nationId);
        final snapshot = _nearQuotaSnapshotWithColonialTarget();

        Orders runOnce(int turnSeed) => runDomainPlanners(
          game: game,
          topology: topology,
          nationId: _nationId,
          view: view,
          snapshot: snapshot,
          config: _aiConfig,
          primaryGoal: StrategicGoal.expand,
          seeds: AISeedBundle.fromTurnSeed(turnSeed),
          suggestionAPI: _navalCandidateApi,
          economyPlan: _economyPlan,
        );

        final first = runOnce(2509202);
        final second = runOnce(2509202);

        List<String> navalMoveFingerprint(Orders orders) => <String>[
          for (final m in _navalMoves(orders))
            '${m.fleetId}|${m.destinationSeaZoneId ?? ''}|'
                '${m.destinationPortProvinceId ?? ''}',
        ];

        expect(
          navalMoveFingerprint(second),
          navalMoveFingerprint(first),
          reason:
              'Determinism (must-have #7): identical COLONIAL-lite inputs '
              'must produce identical naval move orders so a flaky '
              'colonial naval boost path cannot mask the ALLOW contract.',
        );
      },
    );
  });
}
