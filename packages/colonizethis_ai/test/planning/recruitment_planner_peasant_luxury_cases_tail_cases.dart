// Case bodies for peasant reservation + soft luxury cap groups in
// `recruitment_planner_test.dart` (Refs #4104 Slice C).

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'recruitment_planner_test_support.dart';

void registerRecruitmentPlannerPeasantLuxuryCasesTail() {
  group('runRecruitmentPlanner — peasant reservation (AC-RP-1)', () {
    test(
      'AC-RP-3: deficit override caps journeyman recruit at 1.2 × sustainable '
      '(floor)',
      () {
        // sustainable[journeyman] = stockpile.cigars + projected = 1 + 0 = 1.
        // deficit limit floor(1 * 12 / 10) = 1.
        // current = 1, projected after one emit = 2 > 1 → reject.
        final game = recruitmentPlannerTestGameWith(
          const Player(
            id: 'gp1',
            displayName: 'A',
            isHuman: false,
            workerPool: WorkerPool(peasants: 5, journeymen: 1),
            stockpile: Stockpile(quantities: {'cigars': 1}),
          ),
        );
        final view = buildPlayerView(
          game,
          recruitmentPlannerTestTopology,
          'gp1',
        );
        final api = recruitmentPlannerFakeApi(
          recruit: const [RecruitWorkerOrder(targetTier: WorkerTier.journeyman)],
        );
        // Deficit hint: target labour 100, effective labour from workers
        // (5 peasants × 1 + 1 journeyman × 6 = 11) → 11 × 10 < 100 × 8 → deficit.
        const hint = EconomyPlan(
          productionAssignments: [
            AssignedRecipe(recipeId: 'lumber_from_timber', assignedLabour: 100),
          ],
          cargoPreference: CargoPreference.none,
        );

        final plan = runRecruitmentPlanner(RecruitmentPlannerInput(
          game: game,
          view: view,
          currentOrders: const Orders(),
          config: recruitmentPlannerTestConfig,
          seeds: AISeedBundle.fromTurnSeed(0),
          goalPhase: ObserverGoalPhase.develop,
          suggestionApi: api,
          economyPlanHint: hint,
        ));

        expect(plan.recruitOrders, isEmpty);
        expect(plan.rejected, hasLength(1));
        expect(plan.rejected.single.reason, kRecruitmentRejectSoftLuxuryCap);
        expect(plan.rejected.single.targetTier, 'journeyman');
      },
    );

    test(
      'accepts apprentice when projected count fits sustainableTrainedCount',
      () {
        // sustainable[apprentice] = 3 (stockpile) + 0 (no hint) = 3.
        // current = 0, projected after one emit = 1 ≤ 3 → accept.
        final game = recruitmentPlannerTestGameWith(
          const Player(
            id: 'gp1',
            displayName: 'A',
            isHuman: false,
            workerPool: WorkerPool(peasants: 1, apprentices: 0),
            stockpile: Stockpile(quantities: {'refinedSugar': 3}),
          ),
        );
        final view = buildPlayerView(
          game,
          recruitmentPlannerTestTopology,
          'gp1',
        );
        final api = recruitmentPlannerFakeApi(
          recruit: const [RecruitWorkerOrder(targetTier: WorkerTier.apprentice)],
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
        expect(plan.rejected, isEmpty);
      },
    );

    test(
      'economyPlanHint projected refinedSugar output raises sustainable for '
      'apprentice tier',
      () {
        // sustainable[apprentice] = 0 (stockpile) + 2 (projected: 4 labour at
        // 2 labour/run × 1 output = 2). projected after one emit = 1 ≤ 2 → accept.
        final game = recruitmentPlannerTestGameWith(
          const Player(
            id: 'gp1',
            displayName: 'A',
            isHuman: false,
            workerPool: WorkerPool(peasants: 1, apprentices: 0),
          ),
        );
        final view = buildPlayerView(
          game,
          recruitmentPlannerTestTopology,
          'gp1',
        );
        final api = recruitmentPlannerFakeApi(
          recruit: const [RecruitWorkerOrder(targetTier: WorkerTier.apprentice)],
        );
        const hint = EconomyPlan(
          productionAssignments: [
            AssignedRecipe(
              recipeId: 'refinedSugar_from_sugarCane',
              assignedLabour: 4,
            ),
          ],
          cargoPreference: CargoPreference.none,
        );

        final plan = runRecruitmentPlanner(RecruitmentPlannerInput(
          game: game,
          view: view,
          currentOrders: const Orders(),
          config: recruitmentPlannerTestConfig,
          seeds: AISeedBundle.fromTurnSeed(0),
          goalPhase: ObserverGoalPhase.develop,
          suggestionApi: api,
          economyPlanHint: hint,
        ));

        expect(plan.recruitOrders, hasLength(1));
        expect(plan.rejected, isEmpty);
      },
    );
  });
}
