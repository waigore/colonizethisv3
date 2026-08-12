// Case bodies for `runDomainPlanners` OW-boundary pins (Refs #4310 Slice D).

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/observer_goal_phase.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import '../support/domain_planner_orchestrator_quota_consts.dart';
import '../support/observer_goal_phase_transition_boundary_test_support.dart';

void registerObserverGoalPhaseTransitionBoundaryOrchestratorCases() {
  group('runDomainPlanners OW-boundary phase transition', () {
    test(
      'OW=10 (COLONIAL) surfaces NW tribe overture',
      () {
        final game = observerGoalPhaseTransitionBoundaryGameAtQuota();
        final view = buildPlayerView(
          game,
          observerGoalPhaseTransitionBoundaryTopology,
          kOrchestratorGp1NationId,
        );
        final snapshot = observerGoalPhaseTransitionBoundaryColonialSnapshot();

        expect(
          observerGoalPhaseFor(snapshot: snapshot, game: game),
          ObserverGoalPhase.colonial,
          reason:
              'Sanity: the at-quota fixture must land in COLONIAL so the '
              'orchestrator pin below exercises the COLONIAL allow path. '
              'A failure here means the phase boundary itself drifted, '
              'and the orchestrator assertion would be measuring the '
              'wrong contract.',
        );

        final orders = runDomainPlanners(
          DomainPlannerInput(
            game: game,
            topology: observerGoalPhaseTransitionBoundaryTopology,
            nationId: kOrchestratorGp1NationId,
            view: view,
            snapshot: snapshot,
            config: observerGoalPhaseTransitionBoundaryAiConfig,
            primaryGoal: StrategicGoal.conquer,
            seeds: AISeedBundle.fromTurnSeed(2509330),
            suggestionAPI: observerGoalPhaseTransitionBoundaryNwTribeOvertureApi,
            economyPlan: observerGoalPhaseTransitionBoundaryEconomyPlan,
          ),
        );

        expect(
          observerGoalPhaseTransitionBoundaryOvertureTargets(orders),
          contains(kOrchestratorTribeId),
          reason:
              'At quota (OW=10) the GP is in COLONIAL: SPEC § COLONIAL '
              'phase acquisition priority allows Join Empire (and the '
              'establishOverture candidate the fake API supplies). Over-'
              'suppression here would strip Join Empire from the NW '
              'acquisition routes and stall turn-150 NW ownership.',
        );
      },
    );

    test(
      'OW=9 (post-loss EXPAND) drops the same NW tribe overture',
      () {
        final game = observerGoalPhaseTransitionBoundaryGameJustBelowQuota();
        final view = buildPlayerView(
          game,
          observerGoalPhaseTransitionBoundaryTopology,
          kOrchestratorGp1NationId,
        );
        final snapshot = observerGoalPhaseTransitionBoundaryExpandSnapshot();

        expect(
          observerGoalPhaseFor(snapshot: snapshot, game: game),
          ObserverGoalPhase.expand,
          reason:
              'Sanity: dropping a single province from quota (10 -> 9) '
              'must put the GP in EXPAND immediately (no hysteresis band '
              'at quota+1). A failure here means the phase guard drifted '
              'and the orchestrator suppression below would be '
              'spuriously verified against the wrong phase.',
        );

        final orders = runDomainPlanners(
          DomainPlannerInput(
            game: game,
            topology: observerGoalPhaseTransitionBoundaryTopology,
            nationId: kOrchestratorGp1NationId,
            view: view,
            snapshot: snapshot,
            config: observerGoalPhaseTransitionBoundaryAiConfig,
            primaryGoal: StrategicGoal.expand,
            seeds: AISeedBundle.fromTurnSeed(2509331),
            suggestionAPI: observerGoalPhaseTransitionBoundaryNwTribeOvertureApi,
            economyPlan: observerGoalPhaseTransitionBoundaryEconomyPlan,
          ),
        );

        expect(
          observerGoalPhaseTransitionBoundaryOvertureTargets(orders),
          isNot(contains(kOrchestratorTribeId)),
          reason:
              'Issue #2509 § Phase transition guard: a province loss '
              'from quota immediately restores EXPAND so NW work cannot '
              'mask OW regression. The orchestrator must therefore drop '
              'the same NW tribe overture candidate it surfaced at OW=10. '
              'A regression that retained the COLONIAL phase (hysteresis) '
              'would let NW work continue and threaten the canonical '
              'seed-42 `--verify-conquest` per-GP +3 net OW gain gate.',
        );
      },
    );

    test(
      'identical OW=9 inputs produce identical EXPAND orders across runs',
      () {
        final game = observerGoalPhaseTransitionBoundaryGameJustBelowQuota();
        final view = buildPlayerView(
          game,
          observerGoalPhaseTransitionBoundaryTopology,
          kOrchestratorGp1NationId,
        );
        final snapshot = observerGoalPhaseTransitionBoundaryExpandSnapshot();

        Orders runOnce(int turnSeed) => runDomainPlanners(
          DomainPlannerInput(
            game: game,
            topology: observerGoalPhaseTransitionBoundaryTopology,
            nationId: kOrchestratorGp1NationId,
            view: view,
            snapshot: snapshot,
            config: observerGoalPhaseTransitionBoundaryAiConfig,
            primaryGoal: StrategicGoal.expand,
            seeds: AISeedBundle.fromTurnSeed(turnSeed),
            suggestionAPI: observerGoalPhaseTransitionBoundaryNwTribeOvertureApi,
            economyPlan: observerGoalPhaseTransitionBoundaryEconomyPlan,
          ),
        );

        final firstRun = runOnce(2509332);
        final secondRun = runOnce(2509332);

        List<String> diplomaticFingerprint(Orders orders) => <String>[
          for (final o
              in orders.diplomaticOrdersByPlayerId[kOrchestratorGp1NationId] ??
                  const [])
            '${o.type}|${o.targetFactionId}|${o.overtureStage}',
        ];

        expect(
          diplomaticFingerprint(secondRun),
          diplomaticFingerprint(firstRun),
          reason:
              'Determinism (must-have #7): the just-below-quota fixture '
              'must surface identical diplomatic orders across repeated '
              'runs. A divergence here indicates a non-deterministic '
              'phase-boundary path that a single-run pin would miss.',
        );
      },
    );
  });
}
