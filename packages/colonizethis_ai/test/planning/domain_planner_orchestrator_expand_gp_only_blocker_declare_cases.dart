// Case bodies for EXPAND GP-only invadable frontier blocker orchestrator pin.

import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/observer_goal_phase.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../support/domain_planner_orchestrator_test_support.dart';
import 'domain_planner_orchestrator_expand_gp_only_blocker_declare_support.dart';

void registerDomainPlannerOrchestratorExpandGpOnlyBlockerDeclareCases() {
  group('runDomainPlanners EXPAND GP-only blocker declareWar', () {
    test(
      'emits forced declareWar toward GP-only invadable frontier blocker in EXPAND',
      () {
        final game = buildOrchestratorExpandGpOnlyBlockerScenarioGame(
          id: 'g-2509-expand-gp-only-blocker',
          gp1OwProvinces: kGp1OwProvincesBelowQuota,
        );
        const topology = MapTopology(nodes: [], edges: []);
        final view = buildPlayerView(game, topology, kExpandGpOnlyBlockerNationId);
        final snapshot = buildOrchestratorExpandGpOnlyBlockerSnapshot();

        expect(
          observerGoalPhaseFor(snapshot: snapshot, game: game),
          ObserverGoalPhase.expand,
          reason:
              'Fixture must place GP in EXPAND so the GP-only invadable '
              'frontier blocker forced declare-war path is exercised by '
              'the orchestrator (not the COLONIAL/DEVELOP fall-through, '
              'which gates `_plateauGpBlockerDeclarePlannerResultIfNeeded` '
              'off at `!isBelowObserverConquestQuota` per SPEC § Observer '
              'goal phases (Full AI) EXPAND declare-war priority order).',
        );

        final orders = runDomainPlanners(
          DomainPlannerInput(
            game: game,
            topology: topology,
            nationId: kExpandGpOnlyBlockerNationId,
            view: view,
            snapshot: snapshot,
            config: kExpandGpOnlyBlockerAiConfig,
            primaryGoal: StrategicGoal.expand,
            seeds: AISeedBundle.fromTurnSeed(2509121),
            suggestionAPI: kExpandGpOnlyBlockerEmptyApi,
            economyPlan: kExpandGpOnlyBlockerEconomyPlan,
          ),
        );

        expect(
          expandGpOnlyBlockerDeclareWarTargets(orders),
          contains(kExpandGpOnlyBlockerGpId),
          reason:
              'EXPAND below quota with a GP-only invadable Old World '
              'frontier (no minor on the border) must surface the forced '
              '`declareWar` toward the primary invadable blocker GP in '
              'merged diplomatic orders so the GP can break the GP-only '
              'frontier and pursue the turn-100 per-GP +3 net OW gain '
              'gate (SPEC § Observer goal phases (Full AI), EXPAND '
              'declare-war priority order; PR #2577 narrative).',
        );
      },
    );

    test(
      'suppresses GP blocker declareWar at quota in DEVELOP',
      () {
        final game = buildOrchestratorExpandGpOnlyBlockerScenarioGame(
          id: 'g-2509-expand-gp-only-blocker',
          gp1OwProvinces: kGp1OwProvincesDevelop,
        );
        const topology = MapTopology(nodes: [], edges: []);
        final view = buildPlayerView(game, topology, kExpandGpOnlyBlockerNationId);
        final snapshot = buildOrchestratorDevelopGpOnlyBlockerSnapshot();

        expect(
          observerGoalPhaseFor(snapshot: snapshot, game: game),
          ObserverGoalPhase.develop,
          reason:
              'Negative-control fixture must place GP in DEVELOP so the '
              'observer-quota gate inside '
              '`stalledGpBlockerDeclareWarTarget` (and the matching '
              'wrapper gate in `_plateauGpBlockerDeclarePlannerResultIfNeeded`) '
              'is exercised (otherwise this case would silently re-emit '
              'the EXPAND short-circuit and not verify the regression '
              'target).',
        );

        final orders = runDomainPlanners(
          DomainPlannerInput(
            game: game,
            topology: topology,
            nationId: kExpandGpOnlyBlockerNationId,
            view: view,
            snapshot: snapshot,
            config: kExpandGpOnlyBlockerAiConfig,
            primaryGoal: StrategicGoal.diplomacy,
            seeds: AISeedBundle.fromTurnSeed(2509122),
            suggestionAPI: kExpandGpOnlyBlockerEmptyApi,
            economyPlan: kExpandGpOnlyBlockerEconomyPlan,
          ),
        );

        expect(
          expandGpOnlyBlockerDeclareWarTargets(orders),
          isNot(contains(kExpandGpOnlyBlockerGpId)),
          reason:
              'DEVELOP must drop the GP-only invadable blocker forced '
              'declare (the helper short-circuits at the observer-quota / '
              'stalled-OW gate, the wrapper short-circuits at the same '
              'gate, and DEVELOP scoring zeroes every declare-war '
              'candidate from the non-forced fall-through). Suppressing '
              'this declare preserves civilian work bandwidth for the '
              'turn-150 70% extractable-tile improvement gate (SPEC § '
              'Observer goal phases (Full AI), DEVELOP).',
        );
      },
    );

    test(
      'emits identical diplomatic orders for identical EXPAND inputs',
      () {
        final game = buildOrchestratorExpandGpOnlyBlockerScenarioGame(
          id: 'g-2509-expand-gp-only-blocker',
          gp1OwProvinces: kGp1OwProvincesBelowQuota,
        );
        const topology = MapTopology(nodes: [], edges: []);
        final view = buildPlayerView(game, topology, kExpandGpOnlyBlockerNationId);
        final snapshot = buildOrchestratorExpandGpOnlyBlockerSnapshot();

        Orders runOnce(int turnSeed) => runDomainPlanners(
          DomainPlannerInput(
            game: game,
            topology: topology,
            nationId: kExpandGpOnlyBlockerNationId,
            view: view,
            snapshot: snapshot,
            config: kExpandGpOnlyBlockerAiConfig,
            primaryGoal: StrategicGoal.expand,
            seeds: AISeedBundle.fromTurnSeed(turnSeed),
            suggestionAPI: kExpandGpOnlyBlockerEmptyApi,
            economyPlan: kExpandGpOnlyBlockerEconomyPlan,
          ),
        );

        final firstRun = runOnce(2509123);
        final secondRun = runOnce(2509123);

        List<String> diplomaticFingerprint(Orders orders) => <String>[
          for (final o
              in orders.diplomaticOrdersByPlayerId[kExpandGpOnlyBlockerNationId] ??
                  const [])
            '${o.type}|${o.targetFactionId}|${o.overtureStage}',
        ];

        expect(
          diplomaticFingerprint(secondRun),
          diplomaticFingerprint(firstRun),
          reason:
              'Determinism (must-have #7): identical EXPAND-phase inputs '
              'on a GP-only invadable frontier must produce identical '
              'diplomatic orders across runs (forced-blocker declare is '
              'derived from `Game` state, not from rng-driven candidate '
              'sampling, so the fingerprint must be stable).',
        );
      },
    );
  });
}
