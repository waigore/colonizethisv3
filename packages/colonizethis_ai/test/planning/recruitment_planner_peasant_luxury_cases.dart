// Case bodies for peasant reservation + soft luxury cap groups in
// `recruitment_planner_test.dart` (Refs #4104 Slice C).

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'recruitment_planner_test_support.dart';
import 'recruitment_planner_peasant_luxury_cases_tail_cases.dart';

void registerRecruitmentPlannerPeasantLuxuryCases() {
  group('runRecruitmentPlanner — peasant reservation (AC-RP-1)', () {
    test(
      'drops both candidates when pending consumes already exhaust peasants',
      () {
        final game = recruitmentPlannerTestGameWith(
          const Player(
            id: 'gp1',
            displayName: 'A',
            isHuman: false,
            workerPool: WorkerPool(peasants: 1),
          ),
        );
        final view = buildPlayerView(
          game,
          recruitmentPlannerTestTopology,
          'gp1',
        );
        final currentOrders = const Orders(
          buildUnitOrdersByPlayerId: {
            'gp1': [
              BuildUnitOrder(
                unitType: 'peasant_levies',
                isMilitary: true,
                spawnProvinceId: 'oldWorld|P1',
              ),
            ],
          },
        );
        final api = recruitmentPlannerFakeApi(
          recruit: const [RecruitWorkerOrder(targetTier: WorkerTier.apprentice)],
          build: const [
            BuildUnitOrder(
              unitType: 'pikemen',
              isMilitary: true,
              spawnProvinceId: 'oldWorld|P1',
            ),
          ],
        );

        final plan = runRecruitmentPlanner(RecruitmentPlannerInput(
          game: game,
          view: view,
          currentOrders: currentOrders,
          config: recruitmentPlannerTestConfig,
          seeds: AISeedBundle.fromTurnSeed(42),
          goalPhase: ObserverGoalPhase.develop,
          suggestionApi: api,
        ));

        expect(plan.recruitOrders, isEmpty);
        expect(plan.buildUnitOrders, isEmpty);
        expect(plan.rejected, hasLength(2));
        expect(
          plan.rejected.every(
            (r) => r.reason == kRecruitmentRejectInsufficientWorkers,
          ),
          isTrue,
        );
        final tierLabels = plan.rejected.map((r) => r.targetTier).toSet();
        expect(tierLabels, containsAll(<String>{'apprentice', 'pikemen'}));
      },
    );

    test('peasant recruit consumes no peasant (free to emit)', () {
      final game = recruitmentPlannerTestGameWith(
        const Player(
          id: 'gp1',
          displayName: 'A',
          isHuman: false,
          workerPool: WorkerPool(peasants: 0),
        ),
      );
      final view = buildPlayerView(
        game,
        recruitmentPlannerTestTopology,
        'gp1',
      );
      final api = recruitmentPlannerFakeApi(
        recruit: const [RecruitWorkerOrder(targetTier: WorkerTier.peasant)],
      );

      final plan = runRecruitmentPlanner(RecruitmentPlannerInput(
        game: game,
        view: view,
        currentOrders: const Orders(),
        config: recruitmentPlannerTestConfig,
        seeds: AISeedBundle.fromTurnSeed(7),
        goalPhase: ObserverGoalPhase.develop,
        suggestionApi: api,
      ));

      expect(plan.recruitOrders, hasLength(1));
      expect(plan.recruitOrders.single.targetTier, WorkerTier.peasant);
      expect(plan.rejected, isEmpty);
    });

    test(
      'civilian builds do not draw on peasant budget; trained recruit still '
      'fits a single peasant',
      () {
        final game = recruitmentPlannerTestGameWith(
          const Player(
            id: 'gp1',
            displayName: 'A',
            isHuman: false,
            workerPool: WorkerPool(peasants: 1, apprentices: 5),
            stockpile: Stockpile(quantities: {'refinedSugar': 10}),
          ),
        );
        final view = buildPlayerView(
          game,
          recruitmentPlannerTestTopology,
          'gp1',
        );
        final api = recruitmentPlannerFakeApi(
          recruit: const [RecruitWorkerOrder(targetTier: WorkerTier.apprentice)],
          build: const [
            BuildUnitOrder(
              unitType: 'builder',
              isMilitary: false,
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
        expect(plan.buildUnitOrders, hasLength(1));
        expect(plan.buildUnitOrders.single.unitType, 'builder');
        expect(plan.rejected, isEmpty);
      },
    );
  });

  group('runRecruitmentPlanner — soft luxury cap', () {
    test(
      'AC-RP-2: rejects apprentice when sustainableTrainedCount == 0 and '
      'no deficit override',
      () {
        // sustainable[apprentice] = stockpile.refinedSugar + projected = 0 + 0 = 0
        // projected after emit = 0 + 1 = 1 > 0 → reject.
        final game = recruitmentPlannerTestGameWith(
          const Player(
            id: 'gp1',
            displayName: 'A',
            isHuman: false,
            workerPool: WorkerPool(peasants: 5, apprentices: 0),
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

        expect(plan.recruitOrders, isEmpty);
        expect(plan.rejected, hasLength(1));
        expect(plan.rejected.single.reason, kRecruitmentRejectSoftLuxuryCap);
        expect(plan.rejected.single.targetTier, 'apprentice');
      },
    );
  });

  registerRecruitmentPlannerPeasantLuxuryCasesTail();
}
