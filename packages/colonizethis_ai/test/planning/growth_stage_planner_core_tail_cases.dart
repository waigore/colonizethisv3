// Tail case bodies for `growth_stage_planner_test.dart` (Refs #4104 Slice C).

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/growth_stage_work_priorities.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import '../support/growth_stage_planner_test_support.dart';
import '../support/planner_test_helpers.dart';

void registerGrowthStagePlannerCoreTailCases() {
  group('stageScaledRecipeScore — AC11 shortage dominance', () {
    test('fabric stageScaledScore beats military input in bootstrap', () {
      final game = Game(
        id: 'g-3371-ac11',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: const RegionData(
            provinces: [
              Province(id: 'oldWorld|p0', regionId: 'oldWorld', ownerId: 'gp1'),
            ],
          ),
          newWorld: const RegionData(),
          resourceByTileKey: const {'oldWorld|p0|1|0': 'wool'},
        ),
        players: [
          Player(
            id: 'gp1',
            displayName: 'GP1',
            isHuman: false,
            capitalProvinceId: 'oldWorld|p0',
            stockpile: const Stockpile()
                .applyDelta(CommodityCatalog.grain.id, 40)
                .applyDelta(CommodityCatalog.wool.id, 10)
                .applyDelta(CommodityCatalog.copper.id, 5)
                .applyDelta(CommodityCatalog.tin.id, 5),
            workerPool: const WorkerPool(peasants: 2),
          ),
        ],
      );
      final stage = GrowthStage.compute(game, 'gp1');
      expect(stage.workerGrowthPriority, greaterThan(0.8));

      const workers = WorkerPool(peasants: 2);
      final stockpile = game.players.first.stockpile;

      final fabricScore = stageScaledRecipeScore(
        recipe: ProductionRecipesCatalog.fabricFromWool,
        stockpile: stockpile,
        workers: workers,
        agendaId: 'peacemaker',
        stage: stage,
      );
      final militaryScore = stageScaledRecipeScore(
        recipe: ProductionRecipesCatalog.bronzeFromCopperTin,
        stockpile: stockpile,
        workers: workers,
        agendaId: 'peacemaker',
        stage: stage,
      );
      expect(fabricScore, greaterThan(militaryScore));
    });
  });

  group('runRecruitmentPlanner growth-stage — AC4 bootstrap build suppression',
      () {
    test('suppresses regiment builds when military priority is low', () {
      final game = gameWithPlayer(
        Player(
          id: 'gp1',
          displayName: 'A',
          isHuman: false,
          workerPool: const WorkerPool(peasants: 3),
          stockpile: const Stockpile().applyDelta(CommodityCatalog.grain.id, 30),
        ),
      );
      final view = buildPlayerView(game, kTestTopology, 'gp1');
      final api = buildFakeApi(
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
        config: kTestAiConfig,
        seeds: kTestSeeds,
        goalPhase: ObserverGoalPhase.expand,
        suggestionApi: api,
        growthStagePlannerEnabled: true,
      ));

      expect(plan.buildUnitOrders, isEmpty);
      expect(plan.rejected, hasLength(1));
      expect(
        plan.rejected.first.reason,
        kRecruitmentRejectMilitaryBuildSuppressed,
      );
    });
  });
}
