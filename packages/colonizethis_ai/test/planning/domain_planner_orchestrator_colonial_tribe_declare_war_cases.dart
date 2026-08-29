// Case bodies for COLONIAL tribe declare-war orchestrator pin (Refs #2509).

import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/orchestrator_options.dart';
import 'package:colonizethis_ai/src/planning/observer_goal_phase.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../support/domain_planner_orchestrator_test_support.dart';
import 'domain_planner_orchestrator_colonial_tribe_declare_war_support.dart';

void registerDomainPlannerOrchestratorColonialTribeDeclareWarCases() {
  group('runDomainPlanners COLONIAL tribe declareWar', () {
    test('emits declareWar toward visible NW tribe when in COLONIAL', () {
      final game = buildOrchestratorGp1TribeNwScenarioGame(
        id: 'g-2509-colonial-tribe-declare',
        gp1OwProvinces: kGp1OwProvincesAtQuota,
      );
      const topology = MapTopology(nodes: [], edges: []);
      final view = buildPlayerView(game, topology, kColonialTribeDeclareWarNationId);
      final snapshot = buildOrchestratorColonialNwTribeTargetSnapshot();

      expect(
        observerGoalPhaseFor(snapshot: snapshot, game: game),
        ObserverGoalPhase.colonial,
        reason:
            'Fixture must place GP in COLONIAL so the tribe declare-war '
            'AC is exercised by the orchestrator (not the EXPAND '
            'fall-through, which suppresses NW declare-war).',
      );

      final orders = runDomainPlanners(
        DomainPlannerInput(
          game: game,
          topology: topology,
          nationId: kColonialTribeDeclareWarNationId,
          view: view,
          snapshot: snapshot,
          config: kColonialTribeDeclareWarAiConfig,
          primaryGoal: StrategicGoal.conquer,
          seeds: AISeedBundle.fromTurnSeed(2509120),
          suggestionAPI: kColonialTribeDeclareWarApi,
          economyPlan: kColonialTribeDeclareWarEconomyPlan,
        ),
      );

      expect(
        colonialTribeDeclareWarTargets(orders),
        contains(kColonialTribeDeclareWarTribeId),
        reason:
            'COLONIAL with a visible tribe owning a sea-reachable NW '
            'province must surface the tribe declare-war candidate in '
            'merged diplomatic orders (SPEC § Observer goal phases (Full '
            'AI), COLONIAL declare-war rule).',
      );
    });

    test('suppresses tribe declareWar in EXPAND below OW quota', () {
      final game = buildOrchestratorGp1TribeNwScenarioGame(
        id: 'g-2509-colonial-tribe-declare',
        gp1OwProvinces: kGp1OwProvincesBelowQuota,
      );
      const topology = MapTopology(nodes: [], edges: []);
      final view = buildPlayerView(game, topology, kColonialTribeDeclareWarNationId);
      final snapshot = buildOrchestratorExpandNwTribeTargetSnapshot();

      expect(
        observerGoalPhaseFor(snapshot: snapshot, game: game),
        ObserverGoalPhase.expand,
        reason:
            'Negative-control fixture must place GP in EXPAND so the NW '
            'declare-war suppression is verified (otherwise the test would '
            'silently exercise COLONIAL).',
      );

      final orders = runDomainPlanners(
        DomainPlannerInput(
          game: game,
          topology: topology,
          nationId: kColonialTribeDeclareWarNationId,
          view: view,
          snapshot: snapshot,
          config: kColonialTribeDeclareWarAiConfig,
          primaryGoal: StrategicGoal.expand,
          seeds: AISeedBundle.fromTurnSeed(2509121),
          suggestionAPI: kColonialTribeDeclareWarApi,
          economyPlan: kColonialTribeDeclareWarEconomyPlan,
          options: OrchestratorOptions(
            phasePlan: kColonialTribeDeclareWarExpandPhasePlanHardSuppressNw,
          ),
        ),
      );

      expect(
        colonialTribeDeclareWarTargets(orders),
        isNot(contains(kColonialTribeDeclareWarTribeId)),
        reason:
            'Under the explicit `newWorldAcquisition = 0.0` override '
            '(legacy hard-suppress regression contract), EXPAND below '
            'OW quota must drop NW tribe declare-war candidates so OW '
            'conquest pressure is preserved (SPEC § Observer goal '
            'phases (Full AI), EXPAND suppression rule).',
      );
    });

    test('emits identical diplomatic orders for identical COLONIAL inputs', () {
      final game = buildOrchestratorGp1TribeNwScenarioGame(
        id: 'g-2509-colonial-tribe-declare',
        gp1OwProvinces: kGp1OwProvincesAtQuota,
      );
      const topology = MapTopology(nodes: [], edges: []);
      final view = buildPlayerView(game, topology, kColonialTribeDeclareWarNationId);
      final snapshot = buildOrchestratorColonialNwTribeTargetSnapshot();

      Orders runOnce(int turnSeed) => runDomainPlanners(
        DomainPlannerInput(
          game: game,
          topology: topology,
          nationId: kColonialTribeDeclareWarNationId,
          view: view,
          snapshot: snapshot,
          config: kColonialTribeDeclareWarAiConfig,
          primaryGoal: StrategicGoal.conquer,
          seeds: AISeedBundle.fromTurnSeed(turnSeed),
          suggestionAPI: kColonialTribeDeclareWarApi,
          economyPlan: kColonialTribeDeclareWarEconomyPlan,
        ),
      );

      final firstRun = runOnce(2509122);
      final secondRun = runOnce(2509122);

      List<String> diplomaticFingerprint(Orders orders) => <String>[
        for (final o
            in orders.diplomaticOrdersByPlayerId[kColonialTribeDeclareWarNationId] ??
                const [])
          '${o.type}|${o.targetFactionId}|${o.overtureStage}',
      ];

      expect(
        diplomaticFingerprint(secondRun),
        diplomaticFingerprint(firstRun),
        reason:
            'Determinism (must-have #7): identical COLONIAL-phase inputs '
            'must produce identical diplomatic orders across runs.',
      );
    });
  });
}
