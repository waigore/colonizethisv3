// COLONIAL-lite vs EXPAND orchestrator pins: SPEC/ai/ai-architecture.md
// § Observer goal phases (Full AI) (Refs #2509 S10, #4602).

import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/observer_goal_phase.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';

import '../support/domain_planner_orchestrator_test_support.dart';

import 'domain_planner_orchestrator_colonial_lite_cases.dart';
import 'domain_planner_orchestrator_colonial_lite_support.dart';

void main() {
  group('runDomainPlanners COLONIAL-lite phase orchestrator contract', () {
    test('COLONIAL-lite drops NW purchase_land, keeps NW build_improvement and '
        'NW-tribe establishOverture', () {
      // Turn 120 + OW 9 + tribe-owned NW = COLONIAL-lite per
      // `isObserverColonialLitePhase`.
      final game = buildOrchestratorColonialLiteWorkPhasingScenarioGame(
        id: 'g-2509-colonial-lite-orchestrator',
        turnNumber: kObserverColonialLiteMinTurn,
      );
      const topology = MapTopology(nodes: [], edges: []);
      final view = buildPlayerView(
        game,
        topology,
        colonialLiteOrchestratorNationId,
      );
      final snapshot = colonialLiteOrchestratorNearQuotaSnapshot();

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
        DomainPlannerInput(
          game: game,
          topology: topology,
          nationId: colonialLiteOrchestratorNationId,
          view: view,
          snapshot: snapshot,
          config: colonialLiteOrchestratorAiConfig,
          primaryGoal: StrategicGoal.expand,
          seeds: AISeedBundle.fromTurnSeed(2509120),
          suggestionAPI: colonialLiteOrchestratorPhasePhasingApi,
          economyPlan: colonialLiteOrchestratorEconomyPlan,
        ),
      );

      final work = colonialLiteOrchestratorWorkOrders(orders);
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
        colonialLiteOrchestratorOvertureTargets(orders),
        contains(colonialLiteOrchestratorTribeId),
        reason:
            'COLONIAL-lite must allow establishOverture toward visible '
            'tribes/minors so Join Empire stays reachable as an NW '
            'acquisition route (SPEC § COLONIAL-lite: "allows '
            'establishOverture"). A missing tribe id here indicates the '
            'EXPAND overture suppression (shouldSuppressNewWorldColonial'
            'Orders) leaked into COLONIAL-lite.',
      );
    });
    registerDomainPlannerOrchestratorColonialLiteControlCases();
  });
}
