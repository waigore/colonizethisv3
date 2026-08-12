// Pins the DEVELOP-phase New World acquisition-order suppression contract
// from issue #2509:
//
//   SPEC/ai/ai-architecture.md § Observer goal phases (Full AI):
//     "DEVELOP: Suppresses all new declareWar and NW acquisition; forces
//      civilian work selection with improvement-first threshold
//      (kDevelopCivilianWorkThresholdCap)..."
//
// The civilian-work side of that contract is implemented in
// `shouldFilterObserverPhaseWorkOrder` (`observer_goal_phase.dart`), which
// drops NW `purchase_land` orders while leaving NW `build_improvement` (the
// DEVELOP imperative) intact:
//
//   if (phase == ObserverGoalPhase.colonialLite ||
//       phase == ObserverGoalPhase.develop) {
//     if (order.target == kWorkTargetPurchaseLand &&
//         ProvinceId.regionIdFrom(order.targetTileKey) == kNewWorldRegionId) {
//       return true;
//     }
//   }
//
// Existing predicate-level pins cover EXPAND (`flags purchase_land and
// build_improvement in newWorld during expand`) and COLONIAL-lite
// (`colonialLite filters purchase only not NW build`) inside
// `observer_goal_phase_test.dart`, and the analogous EXPAND integration
// contract is pinned in `domain_planner_orchestrator_expand_nw_work_suppression_test.dart`.
// Neither set pins the DEVELOP filter at the `runDomainPlanners` integration
// boundary. A tuning change that left the predicate intact but bypassed the
// orchestrator's filter call (or short-circuited DEVELOP through the
// COLONIAL fall-through) would silently re-emit NW `purchase_land` work
// orders while DEVELOP's stated imperative is improvement-first development.
//
// Coverage layers:
//   - DEVELOP positive (NW `build_improvement` survives the filter — DEVELOP
//     imperative per SPEC § Observer goal phases (Full AI) DEVELOP rule 1).
//   - DEVELOP negative (NW `purchase_land` is dropped — DEVELOP suppression
//     clause "Suppresses all new declareWar and NW acquisition").
//   - COLONIAL negative control (NW `purchase_land` is **not** dropped when
//     visible colonial targets are present, so the filter does not over-fire
//     on the immediately adjacent phase).
//   - Determinism guard (same inputs → same merged work orders, matching
//     must-have #7 deterministic-output requirement).
//
// SPEC:
//   - `SPEC/ai/ai-architecture.md` § Observer goal phases (Full AI)
//   - `SPEC/program/order-suggestions.md` § Work orders (visibility)

import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/observer_goal_phase.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../support/domain_planner_develop_nw_purchase_suppression_test_support.dart';
import '../support/domain_planner_test_fake_api.dart';

const String _nationId = kDevelopNwPurchaseSuppressionNationId;
const String _owProvince = kDevelopNwPurchaseSuppressionOwProvince;
const String _nwOwnedProvince = kDevelopNwPurchaseSuppressionNwOwnedProvince;
const String _nwTribeProvince = kDevelopNwPurchaseSuppressionNwTribeProvince;
const String _owTile = kDevelopNwPurchaseSuppressionOwTile;
const String _nwOwnedTile = kDevelopNwPurchaseSuppressionNwOwnedTile;
const String _nwTribeTile = kDevelopNwPurchaseSuppressionNwTribeTile;

const FakeOrderSuggestionAPIForDomainPlannerTests _mixedRegionWorkApi =
    FakeOrderSuggestionAPIForDomainPlannerTests(
  work: [
    WorkOrder(
      unitId: 'b_ow',
      target: kWorkTargetBuildImprovement,
      targetTileKey: _owTile,
    ),
    WorkOrder(
      unitId: 'b_nw',
      target: kWorkTargetBuildImprovement,
      targetTileKey: _nwOwnedTile,
    ),
    WorkOrder(
      unitId: 'm_nw',
      target: kWorkTargetPurchaseLand,
      targetTileKey: _nwTribeTile,
    ),
  ],
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

void main() {
  group('runDomainPlanners DEVELOP-phase NW purchase_land suppression', () {
    test(
      'DEVELOP drops NW purchase_land but keeps NW + OW build_improvement',
      () {
        final game = developNwPurchaseSuppressionScenarioGame();
        const topology = MapTopology(nodes: [], edges: []);
        final view = buildPlayerView(game, topology, _nationId);
        // OW quota met (>=10) + no colonial acquisition targets → DEVELOP.
        const snapshot = AIWorldSnapshot(
          playerId: _nationId,
          threats: ThreatSummary(),
          opportunities: OpportunitySummary(),
          conquest: ConquestSummary(oldWorldProvincesOwned: 11),
          colonial: ColonialSummary(newWorldProvincesOwned: 1),
          economy: EconomySummary(ownProvinceCount: 2),
          relations: {},
        );
        expect(
          observerGoalPhaseFor(snapshot: snapshot, game: game),
          ObserverGoalPhase.develop,
          reason:
              'Fixture must place GP in DEVELOP so the NW acquisition '
              'suppression contract is exercised, not the COLONIAL fall-through.',
        );

        final orders = runDomainPlanners(
          DomainPlannerInput(
            game: game,
            topology: topology,
            nationId: _nationId,
            view: view,
            snapshot: snapshot,
            config: _aiConfig,
            primaryGoal: StrategicGoal.diplomacy,
            seeds: AISeedBundle.fromTurnSeed(2509101),
            suggestionAPI: _mixedRegionWorkApi,
            economyPlan: _economyPlan,
          ),
        );

        final work = orders.workOrdersByPlayerId[_nationId] ?? const [];
        expect(
          work.any(
            (w) =>
                w.target == kWorkTargetPurchaseLand &&
                w.targetTileKey == _nwTribeTile,
          ),
          isFalse,
          reason:
              'DEVELOP must drop NW purchase_land candidates (SPEC § Observer '
              'goal phases (Full AI) DEVELOP suppression of NW acquisition).',
        );
        expect(
          work.any(
            (w) =>
                w.target == kWorkTargetBuildImprovement &&
                w.targetTileKey == _nwOwnedTile,
          ),
          isTrue,
          reason:
              'DEVELOP imperative is improvement-first development across both '
              'regions; NW build_improvement on GP-owned tiles must survive '
              'the filter.',
        );
        expect(
          work.any(
            (w) =>
                w.target == kWorkTargetBuildImprovement &&
                w.targetTileKey == _owTile,
          ),
          isTrue,
          reason:
              'OW build_improvement is unaffected by the DEVELOP NW '
              'acquisition filter and must remain in merged work orders.',
        );
      },
    );

    test(
      'COLONIAL keeps NW purchase_land the DEVELOP filter would drop',
      () {
        final game = developNwPurchaseSuppressionScenarioGame();
        const topology = MapTopology(nodes: [], edges: []);
        final view = buildPlayerView(game, topology, _nationId);
        // OW quota met (>=10) + visible colonial target → COLONIAL.
        const snapshot = AIWorldSnapshot(
          playerId: _nationId,
          threats: ThreatSummary(),
          opportunities: OpportunitySummary(),
          conquest: ConquestSummary(oldWorldProvincesOwned: 11),
          colonial: ColonialSummary(
            newWorldProvincesOwned: 1,
            invadableNewWorldProvinceIdsSorted: [_nwTribeProvince],
            adjacentNewWorldOwnerFactionIdsSorted: ['tribe1'],
          ),
          economy: EconomySummary(ownProvinceCount: 2),
          relations: {},
        );
        expect(
          observerGoalPhaseFor(snapshot: snapshot, game: game),
          ObserverGoalPhase.colonial,
          reason:
              'Negative-control fixture must place GP in COLONIAL so the '
              'DEVELOP NW purchase_land filter is verified to **not** fire here.',
        );

        final orders = runDomainPlanners(
          DomainPlannerInput(
            game: game,
            topology: topology,
            nationId: _nationId,
            view: view,
            snapshot: snapshot,
            config: _aiConfig,
            primaryGoal: StrategicGoal.diplomacy,
            seeds: AISeedBundle.fromTurnSeed(2509102),
            suggestionAPI: _mixedRegionWorkApi,
            economyPlan: _economyPlan,
          ),
        );

        final work = orders.workOrdersByPlayerId[_nationId] ?? const [];
        // selectFullAiCivilianWorkOrders may pick a single per-unit best
        // target, so we don't assert every candidate remains; the key
        // contract is that NW `purchase_land` is not unconditionally
        // suppressed in COLONIAL (the candidate must survive the
        // orchestrator's filter pass and remain available for selection).
        expect(
          work.any(
            (w) =>
                w.target == kWorkTargetPurchaseLand &&
                w.targetTileKey == _nwTribeTile,
          ),
          isTrue,
          reason:
              'COLONIAL must not apply the DEVELOP NW purchase_land filter; '
              'the merchant purchase_land work order must survive when visible '
              'colonial targets are present.',
        );
      },
    );

    test('DEVELOP filter outcome is deterministic for identical inputs', () {
      final game = developNwPurchaseSuppressionScenarioGame();
      const topology = MapTopology(nodes: [], edges: []);
      final view = buildPlayerView(game, topology, _nationId);
      const snapshot = AIWorldSnapshot(
        playerId: _nationId,
        threats: ThreatSummary(),
        opportunities: OpportunitySummary(),
        conquest: ConquestSummary(oldWorldProvincesOwned: 11),
        colonial: ColonialSummary(newWorldProvincesOwned: 1),
        economy: EconomySummary(ownProvinceCount: 2),
        relations: {},
      );
      final seeds = AISeedBundle.fromTurnSeed(2509103);

      final first = runDomainPlanners(
        DomainPlannerInput(
          game: game,
          topology: topology,
          nationId: _nationId,
          view: view,
          snapshot: snapshot,
          config: _aiConfig,
          primaryGoal: StrategicGoal.diplomacy,
          seeds: seeds,
          suggestionAPI: _mixedRegionWorkApi,
          economyPlan: _economyPlan,
        ),
      );
      final second = runDomainPlanners(
        DomainPlannerInput(
          game: game,
          topology: topology,
          nationId: _nationId,
          view: view,
          snapshot: snapshot,
          config: _aiConfig,
          primaryGoal: StrategicGoal.diplomacy,
          seeds: seeds,
          suggestionAPI: _mixedRegionWorkApi,
          economyPlan: _economyPlan,
        ),
      );

      List<String> describe(Orders orders) =>
          (orders.workOrdersByPlayerId[_nationId] ?? const [])
              .map((w) => '${w.unitId}|${w.target}|${w.targetTileKey}')
              .toList();
      expect(describe(first), describe(second));
    });
  });
}
