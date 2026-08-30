// Case bodies for EXPAND NW `establishOverture` orchestrator suppression (Refs #2509 / #4669).

import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/observer_goal_phase.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../support/domain_planner_orchestrator_test_support.dart';
import 'domain_planner_orchestrator_expand_nw_overture_suppression_support.dart';

void registerDomainPlannerOrchestratorExpandNwOvertureSuppressionCases() {
  group('runDomainPlanners EXPAND-phase NW establishOverture suppression', () {
    test('EXPAND drops establishOverture toward NW tribe colonial target', () {
      final game = buildExpandNwOvertureSuppressScenarioGame(
        gp1OwProvinces: kGp1OwProvincesBelowQuota,
        diplomacyRelations: kExpandNwOvertureTribePeaceRelations,
        overtureStates: kExpandNwOvertureEmbassyStage,
      );
      const topology = MapTopology(nodes: [], edges: []);
      final view = buildPlayerView(
        game,
        topology,
        kExpandNwOvertureSuppressNationId,
      );
      final snapshot = buildOrchestratorExpandNwTribeTargetSnapshot(
        tribePeaceRelationScore: 60,
      );

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
        DomainPlannerInput(
          game: game,
          topology: topology,
          nationId: kExpandNwOvertureSuppressNationId,
          view: view,
          snapshot: snapshot,
          config: kExpandNwOvertureSuppressAiConfig,
          primaryGoal: StrategicGoal.expand,
          seeds: AISeedBundle.fromTurnSeed(2509230),
          suggestionAPI: kExpandNwTribeOvertureApi,
          economyPlan: kExpandNwOvertureSuppressEconomyPlan,
        ),
      );

      expect(
        expandNwOvertureTargets(orders),
        isNot(contains(kExpandNwOvertureSuppressTribeId)),
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
        final game = buildExpandNwOvertureSuppressScenarioGame(
          gp1OwProvinces: kGp1OwProvincesAtQuota,
          diplomacyRelations: kExpandNwOvertureTribePeaceRelations,
          overtureStates: kExpandNwOvertureEmbassyStage,
        );
        const topology = MapTopology(nodes: [], edges: []);
        final view = buildPlayerView(
          game,
          topology,
          kExpandNwOvertureSuppressNationId,
        );
        final snapshot = buildOrchestratorColonialNwTribeTargetSnapshot(
          tribeRelationScore: 60,
        );

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
          DomainPlannerInput(
            game: game,
            topology: topology,
            nationId: kExpandNwOvertureSuppressNationId,
            view: view,
            snapshot: snapshot,
            config: kExpandNwOvertureSuppressAiConfig,
            primaryGoal: StrategicGoal.conquer,
            seeds: AISeedBundle.fromTurnSeed(2509231),
            suggestionAPI: kExpandNwTribeOvertureApi,
            economyPlan: kExpandNwOvertureSuppressEconomyPlan,
          ),
        );

        expect(
          expandNwOvertureTargets(orders),
          contains(kExpandNwOvertureSuppressTribeId),
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
      final game = buildExpandNwOvertureSuppressScenarioGame(
        gp1OwProvinces: kGp1OwProvincesBelowQuota,
        diplomacyRelations: kExpandNwOvertureTribePeaceRelations,
        overtureStates: kExpandNwOvertureEmbassyStage,
      );
      const topology = MapTopology(nodes: [], edges: []);
      final view = buildPlayerView(
        game,
        topology,
        kExpandNwOvertureSuppressNationId,
      );
      final snapshot = buildOrchestratorExpandNwTribeTargetSnapshot(
        tribePeaceRelationScore: 60,
      );

      Orders runOnce(int turnSeed) => runDomainPlanners(
        DomainPlannerInput(
          game: game,
          topology: topology,
          nationId: kExpandNwOvertureSuppressNationId,
          view: view,
          snapshot: snapshot,
          config: kExpandNwOvertureSuppressAiConfig,
          primaryGoal: StrategicGoal.expand,
          seeds: AISeedBundle.fromTurnSeed(turnSeed),
          suggestionAPI: kExpandNwTribeOvertureApi,
          economyPlan: kExpandNwOvertureSuppressEconomyPlan,
        ),
      );

      final firstRun = runOnce(2509232);
      final secondRun = runOnce(2509232);

      List<String> diplomaticFingerprint(Orders orders) => <String>[
        for (final o
            in orders.diplomaticOrdersByPlayerId[
                    kExpandNwOvertureSuppressNationId] ??
                const [])
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
