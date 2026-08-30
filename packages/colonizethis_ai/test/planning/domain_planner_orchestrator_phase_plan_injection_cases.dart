// Hoist-parity / determinism cases for phasePlan injection (Refs #4602).

import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/domain_planner_outcome.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';

import '../support/domain_planner_orchestrator_test_support.dart';

import 'domain_planner_orchestrator_phase_plan_injection_support.dart';

void registerDomainPlannerOrchestratorPhasePlanInjectionParityCases() {
  test('omitting `phasePlan` produces identical orders to passing the natural '
      '`runPhasePlanners(...)` result — internal compute and external '
      'hoist agree byte-for-byte', () {
    // Pins the fallback equivalence contract: the orchestrator's
    // internal `runPhasePlanners(...)` and a hoisted external
    // `runPhasePlanners(...)` against the same inputs must produce
    // the same downstream behaviour. A future refactor that
    // accidentally branched the two paths (for example by reading
    // additional state inside the orchestrator that the hoisted
    // version did not see) would diverge here.
    final game = buildOrchestratorExpandMinorWarScenarioGame(
      id: 'g-2509-orchestrator-phase-plan-injection',
    );
    const topology = MapTopology(nodes: [], edges: []);
    final view = buildPlayerView(game, topology, phasePlanInjectionNationId);
    final snapshot = buildOrchestratorExpandMinorWarAtWarSnapshot();

    final naturalPlan = runPhasePlanners(
      game: game,
      snapshot: snapshot,
      personalityId: phasePlanInjectionAiConfig.personalityId,
    );

    final ordersInternal = runDomainPlannersWithOutcome(
      DomainPlannerInput(
        game: game,
        topology: topology,
        nationId: phasePlanInjectionNationId,
        view: view,
        snapshot: snapshot,
        config: phasePlanInjectionAiConfig,
        primaryGoal: StrategicGoal.conquer,
        seeds: AISeedBundle.fromTurnSeed(2509301),
        suggestionAPI: phasePlanInjectionConquestCandidateApi,
        economyPlan: phasePlanInjectionEconomyPlan,
      ),
    ).orders;

    final ordersExternal = runDomainPlannersWithOutcome(
      DomainPlannerInput(
        game: game,
        topology: topology,
        nationId: phasePlanInjectionNationId,
        view: view,
        snapshot: snapshot,
        config: phasePlanInjectionAiConfig,
        primaryGoal: StrategicGoal.conquer,
        seeds: AISeedBundle.fromTurnSeed(2509301),
        suggestionAPI: phasePlanInjectionConquestCandidateApi,
        economyPlan: phasePlanInjectionEconomyPlan,
        options: OrchestratorOptions(phasePlan: naturalPlan),
      ),
    ).orders;

    expect(
      ordersExternal.armyMoveOrdersByPlayerId,
      ordersInternal.armyMoveOrdersByPlayerId,
      reason:
          'Hoisted-plan and internal-dispatch paths must agree on the '
          'army-move fingerprint when fed identical inputs. Divergence '
          'here means the orchestrator is reading state behind the '
          'parameter (or the dispatcher is non-deterministic for the '
          'same `(Game, AIWorldSnapshot, personalityId)` inputs — '
          'which violates Must-have #7).',
    );
    expect(
      ordersExternal.workOrdersByPlayerId,
      ordersInternal.workOrdersByPlayerId,
      reason:
          'Work-order fingerprint parity guards the economy-pass call '
          'sites that consume the same `PhasePlanOutcome` via '
          '`shouldSuppressWorkOrderFromPhasePlan` and the COLONIAL/'
          'DEVELOP civilian-work resolvers.',
    );
    expect(
      ordersExternal.buildUnitOrdersByPlayerId,
      ordersInternal.buildUnitOrdersByPlayerId,
      reason:
          'Build-order fingerprint parity guards the EXPAND '
          'rebuild-trap arms and the COLONIAL build cap, all of which '
          'route through the dispatched `PhasePlanOutcome` slots in '
          '`_appendEconomyBuildOrders`.',
    );
    expect(
      ordersExternal.diplomaticOrdersByPlayerId,
      ordersInternal.diplomaticOrdersByPlayerId,
      reason:
          'Diplomatic-order fingerprint parity guards the three '
          'declare-war suppression resolvers and the phase-specific '
          'peace-target functions that consume the dispatched '
          '`PhasePlanOutcome` in `runDiplomacyPlannerWithResult`.',
    );
    expect(
      ordersExternal.navalMoveOrdersByPlayerId,
      ordersInternal.navalMoveOrdersByPlayerId,
      reason:
          'Naval-move fingerprint parity guards the colonial naval '
          'boost / ranking that reads `resolvePhaseNavalDirective` '
          'off the dispatched plan in `runNavalPlanner`.',
    );
  });

  test('injecting the same `PhasePlanOutcome` twice into '
      'runDomainPlannersWithOutcome produces identical orders '
      '(Must-have #7 determinism under hoisted dispatch)', () {
    final game = buildOrchestratorExpandMinorWarScenarioGame(
      id: 'g-2509-orchestrator-phase-plan-injection',
    );
    const topology = MapTopology(nodes: [], edges: []);
    final view = buildPlayerView(game, topology, phasePlanInjectionNationId);
    final snapshot = buildOrchestratorExpandMinorWarAtWarSnapshot();

    final naturalPlan = runPhasePlanners(
      game: game,
      snapshot: snapshot,
      personalityId: phasePlanInjectionAiConfig.personalityId,
    );

    DomainPlannerOutcome runOnce() => runDomainPlannersWithOutcome(
      DomainPlannerInput(
        game: game,
        topology: topology,
        nationId: phasePlanInjectionNationId,
        view: view,
        snapshot: snapshot,
        config: phasePlanInjectionAiConfig,
        primaryGoal: StrategicGoal.conquer,
        seeds: AISeedBundle.fromTurnSeed(2509302),
        suggestionAPI: phasePlanInjectionConquestCandidateApi,
        economyPlan: phasePlanInjectionEconomyPlan,
        options: OrchestratorOptions(phasePlan: naturalPlan),
      ),
    );

    final first = runOnce();
    final second = runOnce();

    expect(
      second.orders.armyMoveOrdersByPlayerId,
      first.orders.armyMoveOrdersByPlayerId,
      reason:
          'Two consecutive `runDomainPlannersWithOutcome` calls with '
          'the same hoisted `PhasePlanOutcome` must produce the same '
          'army-move orders. Non-determinism here would silently '
          'desynchronize the strategic-AI hoisted dispatch from the '
          'orchestrator-internal fallback the same fixture exercises '
          'in the equivalence test above.',
    );
    expect(
      second.declaredWarTargetFactionId,
      first.declaredWarTargetFactionId,
      reason:
          'The declare-war target tracked on `DomainPlannerOutcome` '
          'must be stable across runs — it is the same compute the '
          'AI trace export reads.',
    );
    expect(
      second.conquestArmyMoveCount,
      first.conquestArmyMoveCount,
      reason:
          'The conquest army-move count is the orchestrator-level '
          'rollup the trace pin consumes; determinism across the '
          'hoisted-plan path must be preserved.',
    );
  });
}
