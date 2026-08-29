// Determinism tail for EXPAND-phase NW declareWar orchestrator suppression pins
// (Refs #2509 / #4669 Slice D densify).

import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/orchestrator_options.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../support/domain_planner_orchestrator_test_support.dart';
import 'domain_planner_orchestrator_expand_nw_declare_war_suppression_support.dart';

void registerDomainPlannerOrchestratorExpandNwDeclareWarSuppressionTailCases() {
  group('runDomainPlanners EXPAND-phase NW declareWar suppression', () {
    test('emits identical diplomatic orders for identical EXPAND inputs', () {
      final game = buildOrchestratorGp1TribeNwScenarioGame(
        id: 'g-2509-expand-nw-declare-suppress',
        gp1OwProvinces: kGp1OwProvincesBelowQuota,
        diplomacyRelations: const <DiplomacyRelation>[
          DiplomacyRelation(
            factionId1: kOrchestratorGp1NationId,
            factionId2: kOrchestratorTribeId,
            state: RelationState.atPeace,
            score: 0,
          ),
        ],
      );
      const topology = MapTopology(nodes: [], edges: []);
      final view = buildPlayerView(game, topology, kExpandNwDeclareWarSuppressionNationId);
      final snapshot = buildOrchestratorExpandNwTribeTargetSnapshot(tribePeaceRelationScore: 0);

      Orders runOnce(int turnSeed) => runDomainPlanners(
        DomainPlannerInput(
          game: game,
          topology: topology,
          nationId: kExpandNwDeclareWarSuppressionNationId,
          view: view,
          snapshot: snapshot,
          config: kExpandNwDeclareWarSuppressionAiConfig,
          primaryGoal: StrategicGoal.expand,
          seeds: AISeedBundle.fromTurnSeed(turnSeed),
          suggestionAPI: kNwTribeDeclareWarApi,
          economyPlan: kExpandNwDeclareWarSuppressionEconomyPlan,
          options: OrchestratorOptions(phasePlan: kExpandPhasePlanHardSuppressNw),
        ),
      );

      final firstRun = runOnce(2509242);
      final secondRun = runOnce(2509242);

      List<String> diplomaticFingerprint(Orders orders) => <String>[
        for (final o
            in orders.diplomaticOrdersByPlayerId[kExpandNwDeclareWarSuppressionNationId] ??
                const [])
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
