// Case bodies for `growth_stage_planner_test.dart` (Refs #4104 Slice C).

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/growth_stage_work_priorities.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import '../support/growth_stage_planner_test_support.dart';
import '../support/planner_test_helpers.dart';
import 'growth_stage_planner_core_tail_cases.dart';

void registerGrowthStagePlannerCoreCases() {
  group('GrowthStage.compute — AC10 determinism', () {
    test('identical inputs yield identical priorities', () {
      final game = bootstrapFabricGame();
      final a = GrowthStage.compute(game, 'gp1');
      final b = GrowthStage.compute(game, 'gp1');
      expect(a.workerGrowthPriority, b.workerGrowthPriority);
      expect(a.infrastructurePriority, b.infrastructurePriority);
      expect(a.resourceProductionPriority, b.resourceProductionPriority);
      expect(a.militaryPriority, b.militaryPriority);
    });
  });

  group('runEconomyPlanner growth-stage — AC1 bootstrap worker growth', () {
    test('fabric recipe receives the most labour', () {
      final game = bootstrapFabricGame();
      final view = buildPlayerView(game, kTestTopology, 'gp1');
      final plan = runEconomyPlanner(
        game: game,
        view: view,
        config: kTestAiConfig,
        seeds: kTestSeeds,
        growthStagePlannerEnabled: true,
      );

      final fabricLabour = labourForRecipe(
        plan,
        ProductionRecipesCatalog.fabricFromWool.id,
      );
      expect(fabricLabour, greaterThan(0));
      for (final assignment in plan.productionAssignments) {
        if (assignment.recipeId ==
            ProductionRecipesCatalog.fabricFromWool.id) {
          continue;
        }
        expect(
          fabricLabour,
          greaterThan(assignment.assignedLabour),
          reason:
              'fabric should receive more labour than ${assignment.recipeId}',
        );
      }
    });
  });

  group('runEconomyPlanner growth-stage — AC2 infrastructure', () {
    test('assigns labour to castIron when mature and inputs on hand', () {
      final game = matureCastIronGame();
      final view = buildPlayerView(game, kTestTopology, 'gp1');
      final plan = runEconomyPlanner(
        game: game,
        view: view,
        config: kTestAiConfig,
        seeds: kTestSeeds,
        growthStagePlannerEnabled: true,
      );

      expect(
        labourForRecipe(
          plan,
          ProductionRecipesCatalog.castIronFromIron.id,
        ),
        greaterThan(0),
      );
    });
  });

  group('stageScaledRecipeScore — AC5 stockpile damping', () {
    test('high castIron stockpile dampens castIron recipe score', () {
      const workers = WorkerPool(peasants: 12);
      const agenda = 'peacemaker';
      final matureStage = GrowthStage.compute(matureCastIronGame(), 'gp1');
      final stockLow = const Stockpile()
          .applyDelta(CommodityCatalog.grain.id, 80)
          .applyDelta(CommodityCatalog.timber.id, 30)
          .applyDelta(CommodityCatalog.iron.id, 10);
      final stockHigh = stockLow.applyDelta(CommodityCatalog.castIron.id, 25);

      final scoreLow = stageScaledRecipeScore(
        recipe: ProductionRecipesCatalog.castIronFromIron,
        stockpile: stockLow,
        workers: workers,
        agendaId: agenda,
        stage: matureStage,
      );
      final scoreHigh = stageScaledRecipeScore(
        recipe: ProductionRecipesCatalog.castIronFromIron,
        stockpile: stockHigh,
        workers: workers,
        agendaId: agenda,
        stage: matureStage,
      );
      expect(scoreHigh, lessThan(scoreLow));
    });
  });

  group('GrowthStage — AC6 at-war military floor', () {
    test('at-war GP with 4 labour has militaryPriority 0.3', () {
      final game = bootstrapFabricGame();
      final stage = GrowthStage.compute(
        game,
        'gp1',
        snapshot: atWarSnapshot('gp1'),
      );
      expect(stage.militaryPriority, kAtWarMilitaryFloor);
    });

    test('military-input recipe receives labour under at-war floor', () {
      final game = Game(
        id: 'g-3371-ac6',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: const RegionData(
            provinces: [
              Province(id: 'oldWorld|p0', regionId: 'oldWorld', ownerId: 'gp1'),
            ],
          ),
          newWorld: const RegionData(),
        ),
        players: [
          Player(
            id: 'gp1',
            displayName: 'GP1',
            isHuman: false,
            capitalProvinceId: 'oldWorld|p0',
            stockpile: const Stockpile()
                .applyDelta(CommodityCatalog.grain.id, 40)
                .applyDelta(CommodityCatalog.copper.id, 5)
                .applyDelta(CommodityCatalog.tin.id, 5),
            workerPool: const WorkerPool(peasants: 4),
          ),
        ],
      );
      final view = buildPlayerView(game, kTestTopology, 'gp1');
      final plan = runEconomyPlanner(
        game: game,
        view: view,
        config: kTestAiConfig,
        seeds: kTestSeeds,
        snapshot: atWarSnapshot('gp1'),
        growthStagePlannerEnabled: true,
      );

      final bronzeLabour = labourForRecipe(
        plan,
        ProductionRecipesCatalog.bronzeFromCopperTin.id,
      );
      expect(bronzeLabour, greaterThan(0));
    });
  });

  registerGrowthStagePlannerCoreTailCases();
}
