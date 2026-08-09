// Case bodies for emit order, determinism, and edge-case groups in
// `recruitment_planner_test.dart` (Refs #4104 Slice C).

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'recruitment_planner_test_support.dart';

void registerRecruitmentPlannerEmitEdgeCases() {
  group('runRecruitmentPlanner — emit order by phase (AC-RP-5)', () {
    Player playerWithOnePeasant() => const Player(
      id: 'gp1',
      displayName: 'A',
      isHuman: false,
      workerPool: WorkerPool(peasants: 1, apprentices: 5),
      stockpile: Stockpile(quantities: {'refinedSugar': 10}),
    );

    test('DEVELOP processes recruit before build (recruit wins peasant)', () {
      final game = recruitmentPlannerTestGameWith(playerWithOnePeasant());
      final view = buildPlayerView(
        game,
        recruitmentPlannerTestTopology,
        'gp1',
      );
      final api = recruitmentPlannerFakeApi(
        recruit: const [RecruitWorkerOrder(targetTier: WorkerTier.apprentice)],
        build: const [
          BuildUnitOrder(
            unitType: 'peasant_levies',
            isMilitary: true,
            spawnProvinceId: 'oldWorld|P1',
          ),
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

      expect(plan.recruitOrders, hasLength(1));
      expect(plan.recruitOrders.single.targetTier, WorkerTier.apprentice);
      expect(plan.buildUnitOrders, isEmpty);
      expect(plan.rejected, hasLength(1));
      expect(plan.rejected.single.reason, kRecruitmentRejectInsufficientWorkers);
      expect(plan.rejected.single.targetTier, 'peasant_levies');
    });

    test('EXPAND processes build before recruit (military wins peasant)', () {
      final game = recruitmentPlannerTestGameWith(playerWithOnePeasant());
      final view = buildPlayerView(
        game,
        recruitmentPlannerTestTopology,
        'gp1',
      );
      final api = recruitmentPlannerFakeApi(
        recruit: const [RecruitWorkerOrder(targetTier: WorkerTier.apprentice)],
        build: const [
          BuildUnitOrder(
            unitType: 'peasant_levies',
            isMilitary: true,
            spawnProvinceId: 'oldWorld|P1',
          ),
        ],
      );

      final plan = runRecruitmentPlanner(RecruitmentPlannerInput(
        game: game,
        view: view,
        currentOrders: const Orders(),
        config: recruitmentPlannerTestConfig,
        seeds: AISeedBundle.fromTurnSeed(0),
        goalPhase: ObserverGoalPhase.expand,
        suggestionApi: api,
      ));

      expect(plan.buildUnitOrders, hasLength(1));
      expect(plan.buildUnitOrders.single.unitType, 'peasant_levies');
      expect(plan.recruitOrders, isEmpty);
      expect(plan.rejected, hasLength(1));
      expect(plan.rejected.single.reason, kRecruitmentRejectInsufficientWorkers);
      expect(plan.rejected.single.targetTier, 'apprentice');
    });

    test('COLONIAL also processes build before recruit (matches EXPAND)', () {
      final game = recruitmentPlannerTestGameWith(playerWithOnePeasant());
      final view = buildPlayerView(
        game,
        recruitmentPlannerTestTopology,
        'gp1',
      );
      final api = recruitmentPlannerFakeApi(
        recruit: const [RecruitWorkerOrder(targetTier: WorkerTier.apprentice)],
        build: const [
          BuildUnitOrder(
            unitType: 'peasant_levies',
            isMilitary: true,
            spawnProvinceId: 'oldWorld|P1',
          ),
        ],
      );

      final plan = runRecruitmentPlanner(RecruitmentPlannerInput(
        game: game,
        view: view,
        currentOrders: const Orders(),
        config: recruitmentPlannerTestConfig,
        seeds: AISeedBundle.fromTurnSeed(0),
        goalPhase: ObserverGoalPhase.colonial,
        suggestionApi: api,
      ));

      expect(plan.buildUnitOrders, hasLength(1));
      expect(plan.recruitOrders, isEmpty);
    });
  });

  group('runRecruitmentPlanner — determinism (AC-RP-4)', () {
    test('two identical invocations return equal plans', () {
      final game = recruitmentPlannerTestGameWith(
        const Player(
          id: 'gp1',
          displayName: 'A',
          isHuman: false,
          workerPool: WorkerPool(peasants: 2, apprentices: 1),
          stockpile: Stockpile(quantities: {'refinedSugar': 5}),
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
        ],
        build: const [
          BuildUnitOrder(
            unitType: 'pikemen',
            isMilitary: true,
            spawnProvinceId: 'oldWorld|P1',
          ),
        ],
      );

      final plan1 = runRecruitmentPlanner(RecruitmentPlannerInput(
        game: game,
        view: view,
        currentOrders: const Orders(),
        config: recruitmentPlannerTestConfig,
        seeds: AISeedBundle.fromTurnSeed(42),
        goalPhase: ObserverGoalPhase.develop,
        suggestionApi: api,
      ));
      final plan2 = runRecruitmentPlanner(RecruitmentPlannerInput(
        game: game,
        view: view,
        currentOrders: const Orders(),
        config: recruitmentPlannerTestConfig,
        seeds: AISeedBundle.fromTurnSeed(42),
        goalPhase: ObserverGoalPhase.develop,
        suggestionApi: api,
      ));

      expect(
        plan1.recruitOrders.map((o) => o.targetTier).toList(),
        plan2.recruitOrders.map((o) => o.targetTier).toList(),
      );
      expect(
        plan1.buildUnitOrders.map((o) => o.unitType).toList(),
        plan2.buildUnitOrders.map((o) => o.unitType).toList(),
      );
      expect(plan1.rejected, plan2.rejected);
    });
  });

  group('runRecruitmentPlanner — edge cases', () {
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
