// Industry counsel pure economy APIs (Refs #4189/#4190).
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

// dart format off
Game _growthStageFixtureGame() => TestFixtures.minimalGame(
  players: [
    Player(
      id: 'gp1',
      displayName: 'GP',
      isHuman: true,
      stockpile: Stockpile().applyDelta(CommodityCatalog.fabric.id, 30).applyDelta(CommodityCatalog.lumber.id, 30).applyDelta(CommodityCatalog.castIron.id, 30),
      workerPool: const WorkerPool(peasants: 8),
    ),
  ],
  resourceByTileKey: const {'oldWorld|p1|0|0': 'timber'},
  tileState: const TileMapState(improvementByTile: {'oldWorld|p1|0|0': 1}),
  oldWorld: const RegionData(provinces: [Province(id: 'oldWorld|p1', regionId: 'oldWorld', ownerId: 'gp1')]),
  tileKeysByRegionAndProvince: const {'oldWorld': {'p1': ['oldWorld|p1|0|0']}},
);

void main() {
  final lumberRecipe = ProductionRecipesCatalog.byId['lumber_from_timber']!;
  final fabricRecipe = ProductionRecipesCatalog.byId['fabric_from_wool']!;

  group('industryCounselFeasibleRuns', () {
    test('returns zero when labour per output is zero', () {
      const bad = ProductionRecipe(id: 'x', outputCommodityId: 'lumber', outputQuantity: 1, labourPerOutput: 0, inputQuantities: {});
      expect(industryCounselFeasibleRuns(recipe: bad, stockpile: const Stockpile(), remainingLabour: 10), 0);
    });
    test('limits by inputs and labour', () {
      final stockpile = Stockpile().applyDelta(CommodityCatalog.timber.id, 10);
      expect(industryCounselFeasibleRuns(recipe: lumberRecipe, stockpile: stockpile, remainingLabour: 100), 5);
      expect(industryCounselFeasibleRuns(recipe: lumberRecipe, stockpile: stockpile, remainingLabour: 2), 1);
      expect(industryCounselFeasibleRuns(recipe: lumberRecipe, stockpile: const Stockpile(), remainingLabour: 100), 0);
    });
  });

  group('industryCounselScoreRecipe', () {
    test('neutral agenda scores lower than warmonger on military outputs', () {
      final castIron = ProductionRecipesCatalog.byId['castIron_from_iron']!;
      final neutral = industryCounselScoreRecipe(recipe: castIron, stockpile: const Stockpile(), workers: const WorkerPool(), agendaId: kIndustryCounselNeutralAgendaId);
      final warmonger = industryCounselScoreRecipe(recipe: castIron, stockpile: const Stockpile(), workers: const WorkerPool(), agendaId: 'warmonger');
      expect(warmonger, greaterThan(neutral));
    });
    test('chain and merchant agenda paths', () {
      final sugar = ProductionRecipesCatalog.byId['refinedSugar_from_sugarCane']!;
      final workers = const WorkerPool(apprentices: 1);
      final stocked = Stockpile().applyDelta(CommodityCatalog.refinedSugar.id, kIndustryCounselShortageThreshold);
      expect(industryCounselScoreRecipe(recipe: sugar, stockpile: stocked, workers: workers, agendaId: 'merchant'), greaterThan(0));
      expect(industryCounselPrimaryReasonForRecipeScore(recipe: sugar, stockpile: stocked, workers: workers), IndustryCounselReasonKey.chainLuxury);
    });
    test('shortage drives outputShortage reason', () {
      expect(industryCounselPrimaryReasonForRecipeScore(recipe: lumberRecipe, stockpile: const Stockpile(), workers: const WorkerPool()), IndustryCounselReasonKey.outputShortage);
    });
  });

  group('industryCounselStageScaledRecipeScore', () {
    test('applies growth-stage category priority', () {
      const stage = IndustryCounselGrowthStage(workerGrowthPriority: 0.8, infrastructurePriority: 0.2, resourceProductionPriority: 0.5, militaryPriority: 0.1);
      final scaled = industryCounselStageScaledRecipeScore(recipe: fabricRecipe, stockpile: const Stockpile(), workers: const WorkerPool(peasants: 2), agendaId: kIndustryCounselNeutralAgendaId, stage: stage);
      final plain = industryCounselScoreRecipe(recipe: fabricRecipe, stockpile: const Stockpile(), workers: const WorkerPool(peasants: 2), agendaId: kIndustryCounselNeutralAgendaId);
      expect(scaled, greaterThan(plain));
    });
  });

  group('industryCounselAllocateLabourCore', () {
    test('assigns labour to feasible recipes', () {
      final stockpile = Stockpile().applyDelta(CommodityCatalog.timber.id, 20);
      final assignments = industryCounselAllocateLabourCore(stockpile: stockpile, workers: const WorkerPool(peasants: 4), effectiveLabour: 8, techUnlocked: const {'lumber_from_timber': true});
      expect(assignments, isNotEmpty);
      expect(industryCounselTotalAssignedLabour(assignments), lessThanOrEqualTo(8));
      final first = assignments.first;
      expect(industryCounselDesiredOutputForAssignment(first), greaterThan(0));
    });
    test('growth-stage path when enabled', () {
      const stage = IndustryCounselGrowthStage(workerGrowthPriority: 0.5, infrastructurePriority: 0.5, resourceProductionPriority: 0.5, militaryPriority: 0.5);
      final stockpile = Stockpile().applyDelta(CommodityCatalog.timber.id, 10).applyDelta(CommodityCatalog.wool.id, 10);
      final assignments = industryCounselAllocateLabourCore(stockpile: stockpile, workers: const WorkerPool(peasants: 6), effectiveLabour: 12, techUnlocked: const {'lumber_from_timber': true, 'fabric_from_wool': true}, growthStage: stage, growthStagePlannerEnabled: true);
      expect(assignments, isNotEmpty);
    });
  });

  group('industryCounsel luxury helpers', () {
    test('projected luxury and sustainable trained counts', () {
      final sugarRecipe = ProductionRecipesCatalog.byId['refinedSugar_from_sugarCane']!;
      final assignments = [AssignedRecipe(recipeId: sugarRecipe.id, assignedLabour: sugarRecipe.labourPerOutput * 2)];
      final projected = industryCounselProjectedLuxuryOutput(assignments);
      expect(projected[CommodityCatalog.refinedSugar.id], 2);
      final sustainable = industryCounselSustainableTrainedCounts(stockpile: const Stockpile(), productionAssignments: assignments);
      expect(sustainable[WorkerTier.apprentice], 2);
      expect(industryCounselSoftLuxuryCapDeficitLimit(5), 6);
    });
    test('luxury commodity per tier and train scores', () {
      expect(industryCounselLuxuryCommodityForTier(WorkerTier.peasant), isNull);
      expect(industryCounselLuxuryCommodityForTier(WorkerTier.apprentice), CommodityCatalog.refinedSugar.id);
      final peasantScore = industryCounselScoreTrainWorker(tier: WorkerTier.peasant, stockpile: const Stockpile(), effectiveLabour: 2, coreAssignedLabour: 8, sustainableTrainedCounts: const {});
      expect(peasantScore, greaterThan(0));
      final apprenticeScore = industryCounselScoreTrainWorker(tier: WorkerTier.apprentice, stockpile: const Stockpile(), effectiveLabour: 8, coreAssignedLabour: 8, sustainableTrainedCounts: {WorkerTier.apprentice: 1});
      expect(apprenticeScore, greaterThan(0));
      expect(industryCounselScoreTrainWorker(tier: WorkerTier.apprentice, stockpile: Stockpile().applyDelta(CommodityCatalog.refinedSugar.id, 100), effectiveLabour: 8, coreAssignedLabour: 8, sustainableTrainedCounts: {WorkerTier.apprentice: 10}), 0);
    });
  });

  group('IndustryCounselGrowthStage', () {
    test('unknown player returns zero priorities', () {
      final game = TestFixtures.minimalGame(players: [Player(id: 'gp1', displayName: 'GP', isHuman: true)]);
      final stage = IndustryCounselGrowthStage.compute(game, 'missing');
      expect(stage.workerGrowthPriority, 0);
      expect(stage.infrastructurePriority, 0);
    });
    test('computes priorities from player state', () {
      final game = _growthStageFixtureGame();
      final stage = IndustryCounselGrowthStage.compute(game, 'gp1');
      expect(stage.workerGrowthPriority, lessThan(1));
      expect(stage.resourceProductionPriority, greaterThanOrEqualTo(0));
      expect(industryCounselProspectedImprovedFeedstockTileCount(game, 'gp1'), 1);
    });
    test('at-war floor raises military priority', () {
      final game = TestFixtures.minimalGame(
        players: [Player(id: 'gp1', displayName: 'GP', isHuman: true, workerPool: const WorkerPool(peasants: 2))],
        diplomacyRelations: [const DiplomacyRelation(factionId1: 'gp1', factionId2: 'gp2', state: RelationState.atWar)],
      );
      final stage = IndustryCounselGrowthStage.compute(game, 'gp1');
      expect(stage.militaryPriority, greaterThanOrEqualTo(kIndustryCounselAtWarMilitaryFloor));
    });
  });

  group('industryCounselCategoryPriorityForOutput', () {
    const stage = IndustryCounselGrowthStage(workerGrowthPriority: 0.9, infrastructurePriority: 0.4, resourceProductionPriority: 0.2, militaryPriority: 0.6);
    test('fabric uses worker growth vs resource production', () {
      expect(industryCounselCategoryPriorityForOutput(CommodityCatalog.fabric.id, stage), 0.9);
    });
    test('infrastructure outputs use infrastructure priority', () {
      expect(industryCounselCategoryPriorityForOutput(CommodityCatalog.lumber.id, stage), 0.4);
    });
    test('luxury and military outputs use military priority', () {
      expect(industryCounselCategoryPriorityForOutput(CommodityCatalog.refinedSugar.id, stage), 0.6);
      expect(industryCounselCategoryPriorityForOutput(CommodityCatalog.steel.id, stage), 0.6);
    });
    test('unknown output uses max of four with floor', () {
      expect(industryCounselCategoryPriorityForOutput(CommodityCatalog.grain.id, const IndustryCounselGrowthStage(workerGrowthPriority: 0.01, infrastructurePriority: 0.01, resourceProductionPriority: 0.01, militaryPriority: 0.01)), kIndustryCounselMinCategoryFloor);
    });
  });
}
// dart format on
