// Case bodies for COLONIAL-lite NW invasion army-move orchestrator pin.

import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/observer_goal_phase.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../support/domain_planner_orchestrator_test_support.dart';
import 'domain_planner_orchestrator_colonial_lite_invasion_army_move_suppression_support.dart';

void registerDomainPlannerOrchestratorColonialLiteInvasionArmyMoveSuppressionCases() {
  group('runDomainPlanners COLONIAL-lite NW invasion army move suppression', () {
    test(
      'COLONIAL-lite drops NW invasion army move, keeps OW invadable minor move',
      () {
        final game = buildOrchestratorColonialLiteInvasionArmyMoveScenarioGame(
          id: 'g-2509-colonial-lite-invasion-army-move-suppression',
          turnNumber: kObserverColonialLiteMinTurn,
          gpOwProvinceCount: kObserverColonialLiteNearQuotaOw,
        );
        const topology = MapTopology(nodes: [], edges: []);
        final view = buildPlayerView(
          game,
          topology,
          kColonialLiteInvasionArmyMoveNationId,
        );
        final snapshot = colonialLiteInvasionArmyMoveSnapshotFor(
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
          DomainPlannerInput(
            game: game,
            topology: topology,
            nationId: kColonialLiteInvasionArmyMoveNationId,
            view: view,
            snapshot: snapshot,
            config: kColonialLiteInvasionArmyMoveAiConfig,
            primaryGoal: StrategicGoal.expand,
            seeds: AISeedBundle.fromTurnSeed(2509240),
            suggestionAPI: kColonialLiteInvasionMixedOwNwArmyMoveApi,
            economyPlan: kColonialLiteInvasionArmyMoveEconomyPlan,
          ),
        );

        final armyMoves = colonialLiteInvasionArmyMoves(orders);
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
            (m) =>
                m.destinationProvinceId ==
                kColonialLiteInvasionArmyMoveNwTribeProvince,
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
            (m) =>
                m.destinationProvinceId ==
                kColonialLiteInvasionArmyMoveOwMinorProvince,
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
        final game = buildOrchestratorColonialLiteInvasionArmyMoveScenarioGame(
          id: 'g-2509-colonial-lite-invasion-army-move-suppression',
          turnNumber: kObserverColonialLiteMinTurn,
          gpOwProvinceCount: kObserverConquestMinOwProvincesPerGp,
        );
        const topology = MapTopology(nodes: [], edges: []);
        final view = buildPlayerView(
          game,
          topology,
          kColonialLiteInvasionArmyMoveNationId,
        );
        final snapshot = colonialLiteInvasionArmyMoveSnapshotFor(
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
          DomainPlannerInput(
            game: game,
            topology: topology,
            nationId: kColonialLiteInvasionArmyMoveNationId,
            view: view,
            snapshot: snapshot,
            config: kColonialLiteInvasionArmyMoveAiConfig,
            primaryGoal: StrategicGoal.conquer,
            seeds: AISeedBundle.fromTurnSeed(2509241),
            suggestionAPI: kColonialLiteInvasionMixedOwNwArmyMoveApi,
            economyPlan: kColonialLiteInvasionArmyMoveEconomyPlan,
          ),
        );

        final armyMoves = colonialLiteInvasionArmyMoves(orders);
        expect(
          armyMoves.any(
            (m) =>
                m.destinationProvinceId ==
                kColonialLiteInvasionArmyMoveNwTribeProvince,
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
        final game = buildOrchestratorColonialLiteInvasionArmyMoveScenarioGame(
          id: 'g-2509-colonial-lite-invasion-army-move-suppression',
          turnNumber: kObserverColonialLiteMinTurn,
          gpOwProvinceCount: kObserverColonialLiteNearQuotaOw,
        );
        const topology = MapTopology(nodes: [], edges: []);
        final view = buildPlayerView(
          game,
          topology,
          kColonialLiteInvasionArmyMoveNationId,
        );
        final snapshot = colonialLiteInvasionArmyMoveSnapshotFor(
          oldWorldProvincesOwned: kObserverColonialLiteNearQuotaOw,
        );

        Orders runOnce(int turnSeed) => runDomainPlanners(
          DomainPlannerInput(
            game: game,
            topology: topology,
            nationId: kColonialLiteInvasionArmyMoveNationId,
            view: view,
            snapshot: snapshot,
            config: kColonialLiteInvasionArmyMoveAiConfig,
            primaryGoal: StrategicGoal.expand,
            seeds: AISeedBundle.fromTurnSeed(turnSeed),
            suggestionAPI: kColonialLiteInvasionMixedOwNwArmyMoveApi,
            economyPlan: kColonialLiteInvasionArmyMoveEconomyPlan,
          ),
        );

        final first = runOnce(2509242);
        final second = runOnce(2509242);

        List<String> armyFingerprint(Orders orders) => <String>[
          for (final m in colonialLiteInvasionArmyMoves(orders))
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
