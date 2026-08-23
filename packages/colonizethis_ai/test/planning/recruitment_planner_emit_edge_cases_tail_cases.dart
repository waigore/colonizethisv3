// Case bodies for emit order, determinism, and edge-case groups in
// `recruitment_planner_test.dart` (Refs #4104 Slice C).

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'recruitment_planner_test_support.dart';

void registerRecruitmentPlannerEmitEdgeCasesTail() {
  group('runRecruitmentPlanner — emit order by phase (AC-RP-5)', () {
    Player playerWithOnePeasant() => const Player(
      id: 'gp1',
      displayName: 'A',
      isHuman: false,
      workerPool: WorkerPool(peasants: 1, apprentices: 5),
      stockpile: Stockpile(quantities: {'refinedSugar': 10}),
    );

    test('returns empty plan when player view targets unknown player', () {
      final game = recruitmentPlannerTestGameWith(
        const Player(
          id: 'gp1',
          displayName: 'A',
          isHuman: false,
          workerPool: WorkerPool(peasants: 1),
        ),
      );
      // Reuse gp1's view but resolve against a game without that player.
      final view = buildPlayerView(
        game,
        recruitmentPlannerTestTopology,
        'gp1',
      );
      final emptyGame = Game(
        id: 'empty',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: RegionData(provinces: [], units: []),
          newWorld: RegionData(provinces: [], units: []),
        ),
        players: const [],
      );
      final api = recruitmentPlannerFakeApi(
        recruit: const [RecruitWorkerOrder(targetTier: WorkerTier.peasant)],
      );

      final plan = runRecruitmentPlanner(RecruitmentPlannerInput(
        game: emptyGame,
        view: view,
        currentOrders: const Orders(),
        config: recruitmentPlannerTestConfig,
        seeds: AISeedBundle.fromTurnSeed(0),
        goalPhase: ObserverGoalPhase.develop,
        suggestionApi: api,
      ));

      expect(plan.recruitOrders, isEmpty);
      expect(plan.buildUnitOrders, isEmpty);
      expect(plan.rejected, isEmpty);
    });

    test('returns empty plan when suggestion API returns nothing', () {
      final game = recruitmentPlannerTestGameWith(
        const Player(
          id: 'gp1',
          displayName: 'A',
          isHuman: false,
          workerPool: WorkerPool(peasants: 5),
        ),
      );
      final view = buildPlayerView(
        game,
        recruitmentPlannerTestTopology,
        'gp1',
      );
      final api = recruitmentPlannerFakeApi();

      final plan = runRecruitmentPlanner(RecruitmentPlannerInput(
        game: game,
        view: view,
        currentOrders: const Orders(),
        config: recruitmentPlannerTestConfig,
        seeds: AISeedBundle.fromTurnSeed(0),
        goalPhase: ObserverGoalPhase.expand,
        suggestionApi: api,
      ));

      expect(plan.recruitOrders, isEmpty);
      expect(plan.buildUnitOrders, isEmpty);
      expect(plan.rejected, isEmpty);
    });

    test(
      'multiple peasant-consuming recruits draw down the budget in order',
      () {
        // 3 peasants, no pending consumes. Three recruit candidates:
        // peasant (free), apprentice (consumes 1), journeyman (consumes 1).
        // sustainable: refinedSugar=10, cigars=10 → both fit.
        // Result: all 3 emitted, budget after = 1 peasant remaining.
        final game = recruitmentPlannerTestGameWith(
          const Player(
            id: 'gp1',
            displayName: 'A',
            isHuman: false,
            workerPool: WorkerPool(peasants: 3),
            stockpile: Stockpile(
              quantities: {'refinedSugar': 10, 'cigars': 10},
            ),
          ),
        );
        final view = buildPlayerView(
          game,
          recruitmentPlannerTestTopology,
          'gp1',
        );
        final api = recruitmentPlannerFakeApi(
          recruit: const [
            RecruitWorkerOrder(targetTier: WorkerTier.peasant),
            RecruitWorkerOrder(targetTier: WorkerTier.apprentice),
            RecruitWorkerOrder(targetTier: WorkerTier.journeyman),
          ],
        );

        final plan = runRecruitmentPlanner(RecruitmentPlannerInput(
          game: game,
          view: view,
          currentOrders: const Orders(),
          config: recruitmentPlannerTestConfig,
          seeds: AISeedBundle.fromTurnSeed(0),
          goalPhase: ObserverGoalPhase.develop,
          suggestionApi: api,
        ));

        expect(
          plan.recruitOrders.map((o) => o.targetTier).toList(),
          const [
            WorkerTier.peasant,
            WorkerTier.apprentice,
            WorkerTier.journeyman,
          ],
        );
        expect(plan.rejected, isEmpty);
      },
    );
  });
}
