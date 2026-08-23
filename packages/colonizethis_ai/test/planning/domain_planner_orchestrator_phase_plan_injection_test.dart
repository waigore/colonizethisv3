// Hoisted phasePlan vs internal runPhasePlanners fallback:
// SPEC/ai/phase-planner-dispatch.md (Refs #2509 S5, #4602).

import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/observer_goal_phase.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';

import '../support/domain_planner_orchestrator_test_support.dart';

import 'domain_planner_orchestrator_phase_plan_injection_cases.dart';
import 'domain_planner_orchestrator_phase_plan_injection_support.dart';

void main() {
  group('runDomainPlannersWithOutcome phasePlan injection', () {
    test('natural-fixture sanity: EXPAND dispatch commits at least one '
        'conquest army move when phasePlan is omitted (legacy internal '
        'compute)', () {
      final game = buildOrchestratorExpandMinorWarScenarioGame(
        id: 'g-2509-orchestrator-phase-plan-injection',
      );
      const topology = MapTopology(nodes: [], edges: []);
      final view = buildPlayerView(game, topology, phasePlanInjectionNationId);
      final snapshot = buildOrchestratorExpandMinorWarAtWarSnapshot();

      expect(
        observerGoalPhaseFor(snapshot: snapshot, game: game),
        ObserverGoalPhase.expand,
        reason:
            'Sanity guard for the injection contract: the fixture must '
            'place the GP in EXPAND so the contrast between the '
            'internal-compute (EXPAND, `conquestArmyMoveCount > 0`) '
            'and injected `defaultDevelop` (DEVELOP, '
            '`conquestArmyMoveCount == 0`) paths is decided by the '
            'new parameter, not by the fixture itself.',
      );

      final outcome = runDomainPlannersWithOutcome(
        DomainPlannerInput(
          game: game,
          topology: topology,
          nationId: phasePlanInjectionNationId,
          view: view,
          snapshot: snapshot,
          config: phasePlanInjectionAiConfig,
          primaryGoal: StrategicGoal.conquer,
          seeds: AISeedBundle.fromTurnSeed(2509300),
          suggestionAPI: phasePlanInjectionConquestCandidateApi,
          economyPlan: phasePlanInjectionEconomyPlan,
        ),
      );

      expect(
        outcome.conquestArmyMoveCount,
        greaterThan(0),
        reason:
            'EXPAND dispatch must run the conquest army-move planner '
            'and commit the candidate. A zero count here means the '
            'fixture itself is not exercising the conquest pass — '
            'rewire before relying on the positive injection assertion '
            'below.',
      );
    });

    test('injected `defaultDevelop` PhasePlanOutcome forces DEVELOP routing — '
        'orchestrator skips the conquest pass (conquestArmyMoveCount == 0), '
        'overriding the natural EXPAND dispatch', () {
      final game = buildOrchestratorExpandMinorWarScenarioGame(
        id: 'g-2509-orchestrator-phase-plan-injection',
      );
      const topology = MapTopology(nodes: [], edges: []);
      final view = buildPlayerView(game, topology, phasePlanInjectionNationId);
      final snapshot = buildOrchestratorExpandMinorWarAtWarSnapshot();

      expect(
        observerGoalPhaseFor(snapshot: snapshot, game: game),
        ObserverGoalPhase.expand,
        reason:
            'The injection contract is observable only when the natural '
            'dispatch would have routed to EXPAND. If a future fixture '
            'drift flipped the natural phase, this guard catches it '
            'before the assertion below silently passes.',
      );

      final outcome = runDomainPlannersWithOutcome(
        DomainPlannerInput(
          game: game,
          topology: topology,
          nationId: phasePlanInjectionNationId,
          view: view,
          snapshot: snapshot,
          config: phasePlanInjectionAiConfig,
          primaryGoal: StrategicGoal.conquer,
          seeds: AISeedBundle.fromTurnSeed(2509300),
          suggestionAPI: phasePlanInjectionConquestCandidateApi,
          economyPlan: phasePlanInjectionEconomyPlan,
          options: OrchestratorOptions(
            phasePlan: PhasePlanOutcome.defaultDevelop,
          ),
        ),
      );

      expect(
        outcome.conquestArmyMoveCount,
        0,
        reason:
            'When `phasePlan: PhasePlanOutcome.defaultDevelop` is '
            'supplied, `runConquestArmyMovePlanner` must short-circuit '
            'via `resolvePhaseConquestInvadable.skipConquestPass` '
            '(active only under DEVELOP) and contribute zero entries '
            'to `conquestArmyMoveCount`. A positive count here means '
            'the orchestrator silently ignored the injected plan and '
            'recomputed EXPAND internally — exactly the regression '
            'this pin guards against. (Total army-move orders may be '
            'non-zero in DEVELOP via the relocation pass; the '
            'orchestrator-tracked `conquestArmyMoveCount` is the only '
            'count that separates the two paths.)',
      );
    });
    registerDomainPlannerOrchestratorPhasePlanInjectionParityCases();
  });
}
