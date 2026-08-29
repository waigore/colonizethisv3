// Case bodies for EXPAND adjacent invadable OW minor declare-war orchestrator pin.

import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/observer_goal_phase.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../support/domain_planner_orchestrator_test_support.dart';
import 'domain_planner_orchestrator_expand_minor_declare_war_support.dart';

void registerDomainPlannerOrchestratorExpandMinorDeclareWarCases() {
  group('runDomainPlanners EXPAND minor declareWar', () {
    test('emits declareWar toward adjacent invadable OW minor in EXPAND', () {
      final game = buildOrchestratorExpandAdjacentMinorScenarioGame(
        id: 'g-2509-expand-minor-declare-war',
        gp1OwProvinces: kGp1OwProvincesBelowQuota,
      );
      const topology = MapTopology(nodes: [], edges: []);
      final view = buildPlayerView(game, topology, kExpandMinorDeclareWarNationId);
      final snapshot = buildOrchestratorExpandAdjacentMinorSnapshot();

      expect(
        observerGoalPhaseFor(snapshot: snapshot, game: game),
        ObserverGoalPhase.expand,
        reason:
            'Fixture must place GP in EXPAND so the adjacent invadable '
            'minor declare-war AC is exercised by the orchestrator (not '
            'the COLONIAL fall-through, which routes through a different '
            'tribe/Join-Empire path, or DEVELOP which suppresses all '
            'declare-war candidates).',
      );

      final orders = runDomainPlanners(
        DomainPlannerInput(
          game: game,
          topology: topology,
          nationId: kExpandMinorDeclareWarNationId,
          view: view,
          snapshot: snapshot,
          config: kExpandMinorDeclareWarAiConfig,
          primaryGoal: StrategicGoal.expand,
          seeds: AISeedBundle.fromTurnSeed(2509101),
          suggestionAPI: kExpandMinorDeclareWarApi,
          economyPlan: kExpandMinorDeclareWarEconomyPlan,
        ),
      );

      expect(
        expandMinorDeclareWarTargets(orders),
        contains(kExpandMinorDeclareWarMinorId),
        reason:
            'EXPAND with an adjacent invadable OW minor must surface the '
            'minor declare-war candidate in merged diplomatic orders so '
            'the GP can pursue OW conquest pressure toward the turn-100 '
            'per-GP +3 net OW gain gate (SPEC § Observer goal phases '
            '(Full AI), EXPAND declare-war priority order (a)).',
      );
    });

    test('suppresses minor declareWar in DEVELOP at quota', () {
      final game = buildOrchestratorExpandAdjacentMinorScenarioGame(
        id: 'g-2509-expand-minor-declare-war',
        gp1OwProvinces: kGp1OwProvincesDevelop,
      );
      const topology = MapTopology(nodes: [], edges: []);
      final view = buildPlayerView(game, topology, kExpandMinorDeclareWarNationId);
      final snapshot = buildOrchestratorDevelopAdjacentMinorSnapshot();

      expect(
        observerGoalPhaseFor(snapshot: snapshot, game: game),
        ObserverGoalPhase.develop,
        reason:
            'Negative-control fixture must place GP in DEVELOP so the '
            'phase-wide declare-war suppression is exercised (otherwise '
            'this case would silently re-emit the EXPAND short-circuit '
            'and not verify the regression target).',
      );

      final orders = runDomainPlanners(
        DomainPlannerInput(
          game: game,
          topology: topology,
          nationId: kExpandMinorDeclareWarNationId,
          view: view,
          snapshot: snapshot,
          config: kExpandMinorDeclareWarAiConfig,
          primaryGoal: StrategicGoal.diplomacy,
          seeds: AISeedBundle.fromTurnSeed(2509102),
          suggestionAPI: kExpandMinorDeclareWarApi,
          economyPlan: kExpandMinorDeclareWarEconomyPlan,
        ),
      );

      expect(
        expandMinorDeclareWarTargets(orders),
        isNot(contains(kExpandMinorDeclareWarMinorId)),
        reason:
            'DEVELOP must drop every declare-war candidate (including '
            'adjacent invadable OW minors) so improvement-first civilian '
            'work proceeds unblocked toward the turn-150 70% extractable-'
            'tile improvement gate (SPEC § Observer goal phases (Full '
            'AI), DEVELOP).',
      );
    });

    test('emits identical diplomatic orders for identical EXPAND inputs', () {
      final game = buildOrchestratorExpandAdjacentMinorScenarioGame(
        id: 'g-2509-expand-minor-declare-war',
        gp1OwProvinces: kGp1OwProvincesBelowQuota,
      );
      const topology = MapTopology(nodes: [], edges: []);
      final view = buildPlayerView(game, topology, kExpandMinorDeclareWarNationId);
      final snapshot = buildOrchestratorExpandAdjacentMinorSnapshot();

      Orders runOnce(int turnSeed) => runDomainPlanners(
        DomainPlannerInput(
          game: game,
          topology: topology,
          nationId: kExpandMinorDeclareWarNationId,
          view: view,
          snapshot: snapshot,
          config: kExpandMinorDeclareWarAiConfig,
          primaryGoal: StrategicGoal.expand,
          seeds: AISeedBundle.fromTurnSeed(turnSeed),
          suggestionAPI: kExpandMinorDeclareWarApi,
          economyPlan: kExpandMinorDeclareWarEconomyPlan,
        ),
      );

      final firstRun = runOnce(2509103);
      final secondRun = runOnce(2509103);

      List<String> diplomaticFingerprint(Orders orders) => <String>[
        for (final o
            in orders.diplomaticOrdersByPlayerId[kExpandMinorDeclareWarNationId] ??
                const [])
          '${o.type}|${o.targetFactionId}|${o.overtureStage}',
      ];

      expect(
        diplomaticFingerprint(secondRun),
        diplomaticFingerprint(firstRun),
        reason:
            'Determinism (must-have #7): identical EXPAND-phase inputs '
            'must produce identical diplomatic orders across runs.',
      );
    });
  });
}
