// EXPAND-control / determinism cases for COLONIAL-lite orchestrator (Refs #4602).

import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/observer_goal_phase.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../support/domain_planner_orchestrator_test_support.dart';

import 'domain_planner_orchestrator_colonial_lite_support.dart';

void registerDomainPlannerOrchestratorColonialLiteControlCases() {
  test('EXPAND control: turn 90 keeps NW civilian work but drops NW-tribe '
      'establishOverture', () {
    // Same OW=9 + tribe-owned NW fixture, but turn 90 is below
    // `kObserverColonialLiteMinTurn` (120) so the GP stays in EXPAND.
    // Soft-phase work-order filter keeps NW civilian work at low
    // priority; colonial diplomacy suppression still blocks overtures.
    final game = buildOrchestratorColonialLiteWorkPhasingScenarioGame(
      id: 'g-2509-colonial-lite-orchestrator',
      turnNumber: 90,
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
      ObserverGoalPhase.expand,
      reason:
          'Negative-control fixture must place GP in EXPAND so the '
          'COLONIAL-lite contract is verified to **not** fire here. '
          'Otherwise a regression that mis-tags EXPAND as COLONIAL-lite '
          '(loosening the EXPAND NW suppressions before turn 100) would '
          'also pass the positive case.',
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
        seeds: AISeedBundle.fromTurnSeed(2509121),
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
      reason: 'EXPAND must also keep NW build_improvement at low priority.',
    );
    expect(
      colonialLiteOrchestratorOvertureTargets(orders),
      isNot(contains(colonialLiteOrchestratorTribeId)),
      reason:
          'EXPAND must drop NW-tribe establishOverture candidates — '
          'this is the second contract differentiating EXPAND from '
          'COLONIAL-lite. A surviving overture target here means the '
          'EXPAND NW colonial diplomacy suppression '
          '(shouldSuppressNewWorldColonialOrders) is bypassed.',
    );
  });

  test('emits identical work and diplomatic orders for identical COLONIAL-lite '
      'inputs', () {
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

    Orders runOnce(int turnSeed) => runDomainPlanners(
      DomainPlannerInput(
        game: game,
        topology: topology,
        nationId: colonialLiteOrchestratorNationId,
        view: view,
        snapshot: snapshot,
        config: colonialLiteOrchestratorAiConfig,
        primaryGoal: StrategicGoal.expand,
        seeds: AISeedBundle.fromTurnSeed(turnSeed),
        suggestionAPI: colonialLiteOrchestratorPhasePhasingApi,
        economyPlan: colonialLiteOrchestratorEconomyPlan,
      ),
    );

    final first = runOnce(2509122);
    final second = runOnce(2509122);

    List<String> workFingerprint(Orders orders) => <String>[
      for (final w
          in orders.workOrdersByPlayerId[colonialLiteOrchestratorNationId] ??
              const [])
        '${w.unitId}|${w.target}|${w.targetTileKey}',
    ];
    List<String> diplomaticFingerprint(Orders orders) => <String>[
      for (final d
          in orders
                  .diplomaticOrdersByPlayerId[colonialLiteOrchestratorNationId] ??
              const [])
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
  });
}
