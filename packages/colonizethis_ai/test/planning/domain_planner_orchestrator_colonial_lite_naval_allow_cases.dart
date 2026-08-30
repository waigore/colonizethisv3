// Case bodies for COLONIAL-lite naval ALLOW orchestrator contract (Refs #2509 / #4669).

import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/observer_goal_phase.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../support/domain_planner_orchestrator_test_support.dart';
import 'domain_planner_orchestrator_colonial_lite_naval_allow_support.dart';

void registerDomainPlannerOrchestratorColonialLiteNavalAllowCases() {
  group('runDomainPlanners COLONIAL-lite naval move ALLOW contract', () {
    test(
      'COLONIAL-lite emits the colonial naval move candidate under the '
      'colonial pressure boost',
      () {
        final game = buildOrchestratorColonialLiteNavalAllowScenarioGame(
          id: 'g-2509-colonial-lite-naval-allow',
          turnNumber: kObserverColonialLiteMinTurn,
        );
        const topology = MapTopology(nodes: [], edges: []);
        final view = buildPlayerView(game, topology, kColonialLiteNavalAllowNationId);
        final snapshot = colonialLiteNavalAllowNearQuotaSnapshot();

        expect(
          observerGoalPhaseFor(snapshot: snapshot, game: game),
          ObserverGoalPhase.colonialLite,
          reason:
              'Fixture must place GP in COLONIAL-lite so the colonial naval '
              'ALLOW contract is exercised, not EXPAND (which suppresses the '
              'naval colonial boost) or COLONIAL (which does not require '
              'the COLONIAL-lite safeguard).',
        );

        final orders = runDomainPlanners(
          DomainPlannerInput(
            game: game,
            topology: topology,
            nationId: kColonialLiteNavalAllowNationId,
            view: view,
            snapshot: snapshot,
            config: kColonialLiteNavalAllowAiConfig,
            primaryGoal: StrategicGoal.expand,
            seeds: AISeedBundle.fromTurnSeed(2509200),
            suggestionAPI: kColonialLiteNavalAllowCandidateApi,
            economyPlan: kColonialLiteNavalAllowEconomyPlan,
          ),
        );

        final navalMoves = colonialLiteNavalAllowNavalMoves(orders);
        expect(
          navalMoves,
          isNotEmpty,
          reason:
              'COLONIAL-lite must allow colonial naval moves (SPEC § '
              'Observer goal phases (Full AI), COLONIAL-lite allow list: '
              '"colonial naval/cargo"). An empty list here means the '
              'colonial naval boost has been stripped in COLONIAL-lite '
              '(`hasColonialTargets` false) and `runNavalPlanner` skipped '
              'at the < 25 weight floor.',
        );
        expect(
          navalMoves.first.destinationSeaZoneId,
          kColonialLiteNavalAllowNwSeaZoneId,
          reason:
              'The single candidate targets the visible NW sea zone — when '
              'emitted, the colonial-pressure-ranked output must surface '
              'that NW destination so the COLONIAL-lite safeguard actually '
              'advances NW progress for the near-quota GP.',
        );
      },
    );

    test(
      'EXPAND control: turn 90 with the same fixture resolves to EXPAND '
      '(phase-classification negative-control for the COLONIAL-lite ALLOW '
      'contract above) — Refs #2847 Phase 3 soft-phase intent',
      () {
        final game = buildOrchestratorColonialLiteNavalAllowScenarioGame(
          id: 'g-2509-colonial-lite-naval-allow',
          turnNumber: 90,
        );
        const topology = MapTopology(nodes: [], edges: []);
        final view = buildPlayerView(game, topology, kColonialLiteNavalAllowNationId);
        final snapshot = colonialLiteNavalAllowNearQuotaSnapshot();

        expect(
          observerGoalPhaseFor(snapshot: snapshot, game: game),
          ObserverGoalPhase.expand,
          reason:
              'Negative-control fixture must place GP in EXPAND so the '
              'COLONIAL-lite naval ALLOW contract is verified to **not** '
              'fire here. Otherwise a regression that mis-tagged EXPAND as '
              'COLONIAL-lite (re-enabling the colonial naval boost before '
              'turn 100) would also pass the positive case.',
        );

        final orders = runDomainPlanners(
          DomainPlannerInput(
            game: game,
            topology: topology,
            nationId: kColonialLiteNavalAllowNationId,
            view: view,
            snapshot: snapshot,
            config: kColonialLiteNavalAllowAiConfig,
            primaryGoal: StrategicGoal.expand,
            seeds: AISeedBundle.fromTurnSeed(2509201),
            suggestionAPI: kColonialLiteNavalAllowCandidateApi,
            economyPlan: kColonialLiteNavalAllowEconomyPlan,
          ),
        );

        expect(
          colonialLiteNavalAllowNavalMoves(orders),
          isNotEmpty,
          reason:
              'Refs #2847 Phase 3 naval colonial-pressure floor wiring: at '
              'OW=9 the soft-phase newWorldAcquisition weight (0.20) lifts '
              'the naval-pass weight above kNavalRunMinWeight via the '
              'continuous-scale floor (round(85 × 0.20) = 17), so the '
              'EXPAND phase plan emits the colonial naval candidate — the '
              'legacy hard-phase EXPAND naval suppression is deliberately '
              'retired in this slice (negative-control payload for the '
              'COLONIAL-lite ALLOW contract is the phase-classification '
              'check above).',
        );
      },
    );
  });
}

void registerDomainPlannerOrchestratorColonialLiteNavalAllowTailCases() {
  group('runDomainPlanners COLONIAL-lite naval move ALLOW contract', () {
    test(
      'emits identical naval move orders for identical COLONIAL-lite inputs',
      () {
        final game = buildOrchestratorColonialLiteNavalAllowScenarioGame(
          id: 'g-2509-colonial-lite-naval-allow',
          turnNumber: kObserverColonialLiteMinTurn,
        );
        const topology = MapTopology(nodes: [], edges: []);
        final view = buildPlayerView(game, topology, kColonialLiteNavalAllowNationId);
        final snapshot = colonialLiteNavalAllowNearQuotaSnapshot();

        Orders runOnce(int turnSeed) => runDomainPlanners(
              DomainPlannerInput(
                game: game,
                topology: topology,
                nationId: kColonialLiteNavalAllowNationId,
                view: view,
                snapshot: snapshot,
                config: kColonialLiteNavalAllowAiConfig,
                primaryGoal: StrategicGoal.expand,
                seeds: AISeedBundle.fromTurnSeed(turnSeed),
                suggestionAPI: kColonialLiteNavalAllowCandidateApi,
                economyPlan: kColonialLiteNavalAllowEconomyPlan,
              ),
            );

        List<String> navalMoveFingerprint(Orders orders) => <String>[
              for (final m in colonialLiteNavalAllowNavalMoves(orders))
                '${m.fleetId}|${m.destinationSeaZoneId ?? ''}|'
                    '${m.destinationPortProvinceId ?? ''}',
            ];

        expect(
          navalMoveFingerprint(runOnce(2509202)),
          navalMoveFingerprint(runOnce(2509202)),
          reason:
              'Determinism (must-have #7): identical COLONIAL-lite inputs '
              'must produce identical naval move orders so a flaky '
              'colonial naval boost path cannot mask the ALLOW contract.',
        );
      },
    );
  });
}
