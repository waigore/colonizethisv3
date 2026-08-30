// Case bodies for `domain_planner_orchestrator_develop_declare_war_suppression_test.dart`.

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/observer_goal_phase.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import '../support/domain_planner_orchestrator_test_support.dart';
import 'domain_planner_orchestrator_develop_declare_war_suppression_support.dart';

void registerDomainPlannerOrchestratorDevelopDeclareWarSuppressionCases() {
  group('runDomainPlanners DEVELOP-phase declareWar suppression', () {
    test('DEVELOP drops declareWar toward at-war tribe candidate', () {
      final game = buildOrchestratorDevelopGpOwnedNwScenarioGame(
        id: 'g-2509-develop-declare-war-suppress',
      );
      const topology = MapTopology(nodes: [], edges: []);
      final view = buildPlayerView(game, topology, kDevelopDeclareWarSuppressNationId);
      final snapshot = buildOrchestratorDevelopNoColonialTargetsSnapshot(
        atWarWith: const [kDevelopDeclareWarSuppressTribeId],
        tribeRelationScore: 10,
      );

      expect(
        observerGoalPhaseFor(snapshot: snapshot, game: game),
        ObserverGoalPhase.develop,
      );

      final orders = runDomainPlanners(
        DomainPlannerInput(
          game: game,
          topology: topology,
          nationId: kDevelopDeclareWarSuppressNationId,
          view: view,
          snapshot: snapshot,
          config: kDevelopDeclareWarSuppressAiConfig,
          primaryGoal: StrategicGoal.diplomacy,
          seeds: AISeedBundle.fromTurnSeed(2509330),
          suggestionAPI: kDevelopDeclareWarSuppressTribeDeclareWarApi,
          economyPlan: kDevelopDeclareWarSuppressEconomyPlan,
        ),
      );

      expect(
        declareWarTargetsForNation(orders, kDevelopDeclareWarSuppressNationId),
        isNot(contains(kDevelopDeclareWarSuppressTribeId)),
      );
    });

    test(
      'COLONIAL allows declareWar toward the same at-war tribe candidate',
      () {
        final game = buildOrchestratorGp1TribeNwScenarioGame(
          id: 'g-2509-develop-declare-war-suppress-colonial-control',
          gp1OwProvinces: kGp1OwProvincesAtQuota,
          turnNumber: 130,
        );
        const topology = MapTopology(nodes: [], edges: []);
        final view = buildPlayerView(game, topology, kDevelopDeclareWarSuppressNationId);
        final snapshot = buildOrchestratorColonialNwTribeTargetSnapshot(
          atWarWith: const [kDevelopDeclareWarSuppressTribeId],
          tribeRelationScore: 10,
          tribeRelationState: RelationState.atWar,
        );

        expect(
          observerGoalPhaseFor(snapshot: snapshot, game: game),
          ObserverGoalPhase.colonial,
        );

        final orders = runDomainPlanners(
          DomainPlannerInput(
            game: game,
            topology: topology,
            nationId: kDevelopDeclareWarSuppressNationId,
            view: view,
            snapshot: snapshot,
            config: kDevelopDeclareWarSuppressAiConfig,
            primaryGoal: StrategicGoal.conquer,
            seeds: AISeedBundle.fromTurnSeed(2509331),
            suggestionAPI: kDevelopDeclareWarSuppressTribeDeclareWarApi,
            economyPlan: kDevelopDeclareWarSuppressEconomyPlan,
          ),
        );

        expect(
          declareWarTargetsForNation(orders, kDevelopDeclareWarSuppressNationId),
          contains(kDevelopDeclareWarSuppressTribeId),
        );
      },
    );

    test('emits identical diplomatic orders for identical DEVELOP inputs', () {
      final game = buildOrchestratorDevelopGpOwnedNwScenarioGame(
        id: 'g-2509-develop-declare-war-suppress',
      );
      const topology = MapTopology(nodes: [], edges: []);
      final view = buildPlayerView(game, topology, kDevelopDeclareWarSuppressNationId);
      final snapshot = buildOrchestratorDevelopNoColonialTargetsSnapshot(
        atWarWith: const [kDevelopDeclareWarSuppressTribeId],
        tribeRelationScore: 10,
      );

      Orders runOnce(int turnSeed) => runDomainPlanners(
        DomainPlannerInput(
          game: game,
          topology: topology,
          nationId: kDevelopDeclareWarSuppressNationId,
          view: view,
          snapshot: snapshot,
          config: kDevelopDeclareWarSuppressAiConfig,
          primaryGoal: StrategicGoal.diplomacy,
          seeds: AISeedBundle.fromTurnSeed(turnSeed),
          suggestionAPI: kDevelopDeclareWarSuppressTribeDeclareWarApi,
          economyPlan: kDevelopDeclareWarSuppressEconomyPlan,
        ),
      );

      final firstRun = runOnce(2509332);
      final secondRun = runOnce(2509332);

      expect(
        diplomaticFingerprintForNation(
          secondRun,
          kDevelopDeclareWarSuppressNationId,
        ),
        diplomaticFingerprintForNation(
          firstRun,
          kDevelopDeclareWarSuppressNationId,
        ),
      );
    });
  });
}
