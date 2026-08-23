// Case bodies for emit order, determinism, and edge-case groups in
// `recruitment_planner_test.dart` (Refs #4104 Slice C).

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'recruitment_planner_test_support.dart';
import 'recruitment_planner_emit_edge_cases_tail_cases.dart';

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

  registerRecruitmentPlannerEmitEdgeCasesTail();
}
