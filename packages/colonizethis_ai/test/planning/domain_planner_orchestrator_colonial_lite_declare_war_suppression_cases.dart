// Case bodies for COLONIAL-lite NW declareWar orchestrator pin (Refs #2847).

import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/observer_goal_phase.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../support/domain_planner_orchestrator_test_support.dart';
import 'domain_planner_orchestrator_colonial_lite_declare_war_suppression_support.dart';

void registerDomainPlannerOrchestratorColonialLiteDeclareWarSuppressionCases() {
  group(
    'runDomainPlanners COLONIAL-lite-phase NW declareWar suppression',
    () {
      test(
        'COLONIAL-lite keeps declareWar toward NW tribe colonial target scorable at default soft-phase weight',
        () {
          final game = buildOrchestratorColonialLiteDeclareWarScenarioGame(
            id: 'g-2509-colonial-lite-nw-declare-suppress',
            gp1OwProvinces: kGp1OwProvincesColonialLiteNearQuota,
          );
          const topology = MapTopology(nodes: [], edges: []);
          final view = buildPlayerView(
            game,
            topology,
            kColonialLiteDeclareWarNationId,
          );
          final snapshot = buildOrchestratorExpandNwTribeTargetSnapshot(
            oldWorldProvincesOwned: kObserverColonialLiteNearQuotaOw,
            provincesToVictory: 22,
            tribePeaceRelationScore: 0,
          );

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
            DomainPlannerInput(
              game: game,
              topology: topology,
              nationId: kColonialLiteDeclareWarNationId,
              view: view,
              snapshot: snapshot,
              config: kColonialLiteDeclareWarAiConfig,
              primaryGoal: StrategicGoal.expand,
              seeds: AISeedBundle.fromTurnSeed(2509300),
              suggestionAPI: kColonialLiteNwTribeDeclareWarApi,
              economyPlan: kColonialLiteDeclareWarEconomyPlan,
            ),
          );

          expect(
            colonialLiteDeclareWarTargets(orders),
            contains(kColonialLiteDeclareWarTribeId),
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
                '`phase_planner_diplomacy_declare_war_nw_suppression_test.dart`.',
          );
        },
      );

      test(
        'COLONIAL (OW=10) keeps declareWar toward the same NW tribe candidate',
        () {
          final game = buildOrchestratorColonialLiteDeclareWarScenarioGame(
            id: 'g-2509-colonial-lite-nw-declare-suppress',
            gp1OwProvinces: kGp1OwProvincesExactQuota,
          );
          const topology = MapTopology(nodes: [], edges: []);
          final view = buildPlayerView(
            game,
            topology,
            kColonialLiteDeclareWarNationId,
          );
          final snapshot = buildOrchestratorColonialNwTribeTargetSnapshot(
            oldWorldProvincesOwned: kObserverConquestMinOwProvincesPerGp,
            provincesToVictory: 21,
            tribeRelationScore: 0,
          );

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
            DomainPlannerInput(
              game: game,
              topology: topology,
              nationId: kColonialLiteDeclareWarNationId,
              view: view,
              snapshot: snapshot,
              config: kColonialLiteDeclareWarAiConfig,
              primaryGoal: StrategicGoal.conquer,
              seeds: AISeedBundle.fromTurnSeed(2509301),
              suggestionAPI: kColonialLiteNwTribeDeclareWarApi,
              economyPlan: kColonialLiteDeclareWarEconomyPlan,
            ),
          );

          expect(
            colonialLiteDeclareWarTargets(orders),
            contains(kColonialLiteDeclareWarTribeId),
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
          final game = buildOrchestratorColonialLiteDeclareWarScenarioGame(
            id: 'g-2509-colonial-lite-nw-declare-suppress',
            gp1OwProvinces: kGp1OwProvincesColonialLiteNearQuota,
          );
          const topology = MapTopology(nodes: [], edges: []);
          final view = buildPlayerView(
            game,
            topology,
            kColonialLiteDeclareWarNationId,
          );
          final snapshot = buildOrchestratorExpandNwTribeTargetSnapshot(
            oldWorldProvincesOwned: kObserverColonialLiteNearQuotaOw,
            provincesToVictory: 22,
            tribePeaceRelationScore: 0,
          );

          Orders runOnce(int turnSeed) => runDomainPlanners(
            DomainPlannerInput(
              game: game,
              topology: topology,
              nationId: kColonialLiteDeclareWarNationId,
              view: view,
              snapshot: snapshot,
              config: kColonialLiteDeclareWarAiConfig,
              primaryGoal: StrategicGoal.expand,
              seeds: AISeedBundle.fromTurnSeed(turnSeed),
              suggestionAPI: kColonialLiteNwTribeDeclareWarApi,
              economyPlan: kColonialLiteDeclareWarEconomyPlan,
            ),
          );

          final firstRun = runOnce(2509302);
          final secondRun = runOnce(2509302);

          List<String> diplomaticFingerprint(Orders orders) => <String>[
            for (final o
                in orders.diplomaticOrdersByPlayerId[
                        kColonialLiteDeclareWarNationId] ??
                    const [])
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
