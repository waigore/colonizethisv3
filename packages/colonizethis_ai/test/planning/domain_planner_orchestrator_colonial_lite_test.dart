// Pins the COLONIAL-lite phase orchestrator contract from issue #2509 S10 at
// the `runDomainPlanners` integration boundary.
//
//   SPEC/ai/ai-architecture.md § Observer goal phases (Full AI),
//   COLONIAL-lite: "turn >= kObserverColonialLiteMinTurn, OW
//   >= kObserverColonialLiteNearQuotaOw and below quota, global newWorld| not
//   all GP-owned: allows establishOverture, colonial naval/cargo; suppresses
//   NW declareWar, invasion army moves, and purchase_land only."
//
// COLONIAL-lite is the EXPAND-late-game safeguard: GPs at 9 OW from turn 120
// onward keep pushing NW progress without trading away the OW quota path.
// Unit-level coverage of `isObserverColonialLitePhase` and
// `shouldFilterObserverPhaseWorkOrder` lives in
// `packages/colonizethis_ai/test/observer_goal_phase_test.dart` (groups
// `observerGoalPhaseFor` and `shouldFilterObserverPhaseWorkOrder`). Sibling
// orchestrator pins exist for **EXPAND** NW work suppression
// (`domain_planner_orchestrator_expand_nw_work_suppression_test.dart`) and
// **EXPAND** NW `establishOverture` suppression
// (`domain_planner_orchestrator_expand_nw_overture_suppression_test.dart`),
// but no orchestrator test exercises the COLONIAL-lite branch. Without a
// pin here, a tuning slice that left the underlying predicates intact but
// rewired `runDomainPlanners` (for example by reusing
// `shouldSuppressNewWorldColonialOrders` instead of
// `shouldFilterObserverPhaseWorkOrder` for the work-order filter, or by
// dropping the orchestrator's filter pass entirely) could silently regress
// either:
//   - the "purchase_land only" suppression contract (over-suppress: drops NW
//     `build_improvement` and stalls turn-150 improvement coverage), or
//   - the "allows establishOverture" contract (over-suppress: strips the Join
//     Empire route from the NW acquisition path before turn 150).
//
// The negative control re-runs the same fixture in EXPAND (turn 90, all
// other inputs identical) and asserts the orchestrator drops **both** NW
// `build_improvement` and the NW-tribe `establishOverture` — so a regression
// that mis-tags COLONIAL-lite as EXPAND (or vice versa) also fails.
//
// Coverage layers:
//   - Positive (COLONIAL-lite): NW `purchase_land` dropped, NW
//     `build_improvement` retained, `establishOverture` toward NW tribe
//     retained.
//   - Negative control (EXPAND): same fixture below the turn-120 gate; NW
//     `purchase_land`, NW `build_improvement`, and `establishOverture` toward
//     the NW tribe are all dropped.
//   - Determinism guard (must-have #7): identical COLONIAL-lite inputs
//     produce identical work and diplomatic order fingerprints across runs.

import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/observer_goal_phase.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../support/domain_planner_test_fake_api.dart';
import '../support/domain_planner_orchestrator_test_support.dart';

const String _nationId = kOrchestratorGp1NationId;
const String _tribeId = kOrchestratorTribeId;

/// Fake API surfaces the three phase-distinguishing candidates:
///   - NW `build_improvement` on the GP-owned NW grain tile;
///   - NW `purchase_land` on the tribe NW grain tile;
///   - `establishOverture(tribe1, joinEmpire)` (Join Empire candidate).
///
/// `suggestDeclareWarOrders` filters by `type == declareWar`, so this fixture
/// only feeds the non-declareWar diplomacy pass — i.e. exactly the pass the
/// COLONIAL-lite vs EXPAND overture contract gates.
const FakeOrderSuggestionAPIForDomainPlannerTests _phasePhasingApi =
    FakeOrderSuggestionAPIForDomainPlannerTests(
  work: [
    WorkOrder(
      unitId: 'b_nw',
      target: kWorkTargetBuildImprovement,
      targetTileKey: kOrchestratorColonialLiteNwGpTile,
    ),
    WorkOrder(
      unitId: 'm_nw',
      target: kWorkTargetPurchaseLand,
      targetTileKey: kOrchestratorColonialLiteNwTribeTile,
    ),
  ],
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

// `henry` + `merchant` matches the personality/agenda used by the EXPAND NW
// overture suppression sibling pin
// (`domain_planner_orchestrator_expand_nw_overture_suppression_test.dart`)
// and the COLONIAL personality scoring test in
// `observer_goal_phase_test.dart`. `peacemaker` is intentionally avoided —
// that agenda zeroes declareWar candidates and can confound a regression
// that would otherwise show in the diplomatic-order suppression contract.
const AIConfig _aiConfig = AIConfig(
  leaderId: 'henry',
  personalityId: 'henry',
  hiddenAgendaId: 'merchant',
);

AIWorldSnapshot _nearQuotaSnapshot() {
  return const AIWorldSnapshot(
    playerId: _nationId,
    threats: ThreatSummary(),
    opportunities: OpportunitySummary(),
    // 9 OW provinces -> below quota; phase is decided by turn number
    // (>= 120 enters COLONIAL-lite; otherwise EXPAND).
    conquest: ConquestSummary(
      oldWorldProvincesOwned: kObserverColonialLiteNearQuotaOw,
      provincesToVictory: 22,
    ),
    // Tribe is both a visible NW invadable owner and a preferred colonial
    // target. The same fixture exercises the EXPAND overture suppression
    // (`shouldSuppressNewWorldColonialOrders` branch) when reused at turn
    // 90 in the negative control.
    colonial: ColonialSummary(
      newWorldProvincesOwned: 1,
      invadableNewWorldProvinceIdsSorted: [kOrchestratorColonialLiteNwTribeProvince],
      adjacentNewWorldOwnerFactionIdsSorted: [_tribeId],
      preferredColonialTargetFactionIdsSorted: [_tribeId],
    ),
    economy: EconomySummary(ownProvinceCount: 9),
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

List<WorkOrder> _workOrders(Orders orders) =>
    orders.workOrdersByPlayerId[_nationId] ?? const [];

void main() {
  group('runDomainPlanners COLONIAL-lite phase orchestrator contract', () {
    test(
      'COLONIAL-lite drops NW purchase_land, keeps NW build_improvement and '
      'NW-tribe establishOverture',
      () {
        // Turn 120 + OW 9 + tribe-owned NW = COLONIAL-lite per
        // `isObserverColonialLitePhase`.
        final game = buildOrchestratorColonialLiteWorkPhasingScenarioGame(
          id: 'g-2509-colonial-lite-orchestrator',
          turnNumber: kObserverColonialLiteMinTurn,
        );
        const topology = MapTopology(nodes: [], edges: []);
        final view = buildPlayerView(game, topology, _nationId);
        final snapshot = _nearQuotaSnapshot();

        expect(
          observerGoalPhaseFor(snapshot: snapshot, game: game),
          ObserverGoalPhase.colonialLite,
          reason:
              'Fixture must place GP in COLONIAL-lite so the COLONIAL-lite '
              'contract is exercised by the orchestrator, not EXPAND '
              '(which over-suppresses NW build_improvement / overture) or '
              'COLONIAL (which does not suppress NW purchase_land).',
        );

        final orders = runDomainPlanners(
          game: game,
          topology: topology,
          nationId: _nationId,
          view: view,
          snapshot: snapshot,
          config: _aiConfig,
          primaryGoal: StrategicGoal.expand,
          seeds: AISeedBundle.fromTurnSeed(2509120),
          suggestionAPI: _phasePhasingApi,
          economyPlan: _economyPlan,
        );

        final work = _workOrders(orders);
        expect(
          work.any(
            (w) =>
                w.target == kWorkTargetPurchaseLand &&
                w.targetTileKey == kOrchestratorColonialLiteNwTribeTile,
          ),
          isFalse,
          reason:
              'COLONIAL-lite must drop NW purchase_land candidates (SPEC § '
              'COLONIAL-lite suppression list). A surviving purchase_land '
              'here indicates the orchestrator stopped applying '
              'shouldFilterObserverPhaseWorkOrder to merchant candidates.',
        );
        expect(
          work.any(
            (w) =>
                w.target == kWorkTargetBuildImprovement &&
                w.targetTileKey == kOrchestratorColonialLiteNwGpTile,
          ),
          isTrue,
          reason:
              'COLONIAL-lite must keep NW build_improvement candidates so '
              'GPs near the OW quota continue accruing improvement coverage '
              'toward the turn-150 70% gate (SPEC § COLONIAL-lite: suppress '
              'list is "NW declareWar, invasion army moves, purchase_land '
              'only"). An empty list here means an EXPAND-style over-filter '
              'leaked into COLONIAL-lite.',
        );
        expect(
          _overtureTargets(orders),
          contains(_tribeId),
          reason:
              'COLONIAL-lite must allow establishOverture toward visible '
              'tribes/minors so Join Empire stays reachable as an NW '
              'acquisition route (SPEC § COLONIAL-lite: "allows '
              'establishOverture"). A missing tribe id here indicates the '
              'EXPAND overture suppression (shouldSuppressNewWorldColonial'
              'Orders) leaked into COLONIAL-lite.',
        );
      },
    );

    test(
      'EXPAND control: turn 90 keeps NW civilian work but drops NW-tribe '
      'establishOverture',
      () {
        // Same OW=9 + tribe-owned NW fixture, but turn 90 is below
        // `kObserverColonialLiteMinTurn` (120) so the GP stays in EXPAND.
        // Soft-phase work-order filter keeps NW civilian work at low
        // priority; colonial diplomacy suppression still blocks overtures.
        final game = buildOrchestratorColonialLiteWorkPhasingScenarioGame(
          id: 'g-2509-colonial-lite-orchestrator',
          turnNumber: 90,
        );
        const topology = MapTopology(nodes: [], edges: []);
        final view = buildPlayerView(game, topology, _nationId);
        final snapshot = _nearQuotaSnapshot();

        expect(
          observerGoalPhaseFor(snapshot: snapshot, game: game),
          ObserverGoalPhase.expand,
          reason:
              'Negative-control fixture must place GP in EXPAND so the '
              'COLONIAL-lite contract is verified to **not** fire here. '
              'Otherwise a regression that mis-tags EXPAND as COLONIAL-lite '
              '(loosening the EXPAND NW suppressions before turn 100) would '
              'also pass the positive case.',
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
          suggestionAPI: _phasePhasingApi,
          economyPlan: _economyPlan,
        );

        final work = _workOrders(orders);
        expect(
          work.any(
            (w) =>
                w.target == kWorkTargetPurchaseLand &&
                w.targetTileKey == kOrchestratorColonialLiteNwTribeTile,
          ),
          isTrue,
          reason:
              'EXPAND with soft-phase NW weight must keep NW purchase_land — '
              'the key contract differentiating EXPAND from COLONIAL-lite '
              '(which drops purchase_land only).',
        );
        expect(
          work.any(
            (w) =>
                w.target == kWorkTargetBuildImprovement &&
                w.targetTileKey == kOrchestratorColonialLiteNwGpTile,
          ),
          isTrue,
          reason:
              'EXPAND must also keep NW build_improvement at low priority.',
        );
        expect(
          _overtureTargets(orders),
          isNot(contains(_tribeId)),
          reason:
              'EXPAND must drop NW-tribe establishOverture candidates — '
              'this is the second contract differentiating EXPAND from '
              'COLONIAL-lite. A surviving overture target here means the '
              'EXPAND NW colonial diplomacy suppression '
              '(shouldSuppressNewWorldColonialOrders) is bypassed.',
        );
      },
    );

    test(
      'emits identical work and diplomatic orders for identical COLONIAL-lite '
      'inputs',
      () {
        final game = buildOrchestratorColonialLiteWorkPhasingScenarioGame(
          id: 'g-2509-colonial-lite-orchestrator',
          turnNumber: kObserverColonialLiteMinTurn,
        );
        const topology = MapTopology(nodes: [], edges: []);
        final view = buildPlayerView(game, topology, _nationId);
        final snapshot = _nearQuotaSnapshot();

        Orders runOnce(int turnSeed) => runDomainPlanners(
          game: game,
          topology: topology,
          nationId: _nationId,
          view: view,
          snapshot: snapshot,
          config: _aiConfig,
          primaryGoal: StrategicGoal.expand,
          seeds: AISeedBundle.fromTurnSeed(turnSeed),
          suggestionAPI: _phasePhasingApi,
          economyPlan: _economyPlan,
        );

        final first = runOnce(2509122);
        final second = runOnce(2509122);

        List<String> workFingerprint(Orders orders) => <String>[
          for (final w in orders.workOrdersByPlayerId[_nationId] ?? const [])
            '${w.unitId}|${w.target}|${w.targetTileKey}',
        ];
        List<String> diplomaticFingerprint(Orders orders) => <String>[
          for (final d
              in orders.diplomaticOrdersByPlayerId[_nationId] ?? const [])
            '${d.type}|${d.targetFactionId}|${d.overtureStage}',
        ];

        expect(
          workFingerprint(second),
          workFingerprint(first),
          reason:
              'Determinism (must-have #7): identical COLONIAL-lite inputs '
              'must produce identical civilian work orders so a flaky '
              'phase-filter path cannot mask the suppression contract.',
        );
        expect(
          diplomaticFingerprint(second),
          diplomaticFingerprint(first),
          reason:
              'Determinism (must-have #7): identical COLONIAL-lite inputs '
              'must produce identical diplomatic orders so a flaky NW '
              'overture path cannot mask the allow contract.',
        );
      },
    );
  });
}
