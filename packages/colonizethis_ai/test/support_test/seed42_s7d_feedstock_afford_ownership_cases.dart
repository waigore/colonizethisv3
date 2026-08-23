// Case bodies for seed42_s7d_feedstock_helpers_test afford/ownership pins
// (Refs #3997 Phase 8).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import '../support/seed42_s7d_feedstock_helpers.dart';
import '../support/seed42_s7d_feedstock_helpers_test_support.dart';
import 'seed42_s7d_feedstock_afford_ownership_cases_tail_cases.dart';

void registerSeed42S7dFeedstockAffordOwnershipCases() {
  final castIron = ProductionRecipesCatalog.castIronFromIron;
  final lumber = ProductionRecipesCatalog.lumberFromTimber;
  final fabricFromWool = ProductionRecipesCatalog.fabricFromWool;
  final timberId = CommodityCatalog.timber.id;
  final ironId = CommodityCatalog.iron.id;
  final woolId = CommodityCatalog.wool.id;
  final grainId = CommodityCatalog.grain.id;

  group('stockpileAffordsAnyProductionRecipe', () {
    test(
      'positive: holds every input of the sole recipe (castIron = 2 timber + '
      '2 iron)',
      () {
        final stockpile = Stockpile(quantities: {timberId: 2, ironId: 2});
        expect(
          stockpileAffordsAnyProductionRecipe(stockpile, [castIron]),
          isTrue,
        );
      },
    );

    test('positive: affords at least one of several candidate recipes', () {
      // Holds timber but no iron: cannot run castIron, but can run lumber
      // (2 timber). Any single affordable recipe satisfies the helper.
      final stockpile = Stockpile(quantities: {timberId: 2});
      expect(
        stockpileAffordsAnyProductionRecipe(stockpile, [castIron, lumber]),
        isTrue,
      );
    });

    test('positive: surplus above the input requirement still affords', () {
      final stockpile = Stockpile(quantities: {timberId: 71, ironId: 64});
      expect(
        stockpileAffordsAnyProductionRecipe(stockpile, [castIron]),
        isTrue,
      );
    });

    test('negative: missing one required input (iron) is not affordable', () {
      final stockpile = Stockpile(quantities: {timberId: 5, ironId: 1});
      expect(
        stockpileAffordsAnyProductionRecipe(stockpile, [castIron]),
        isFalse,
      );
    });

    test('negative: empty stockpile affords nothing', () {
      expect(
        stockpileAffordsAnyProductionRecipe(Stockpile.empty, [castIron]),
        isFalse,
      );
    });

    test('negative: empty recipe list is never affordable', () {
      final stockpile = Stockpile(quantities: {timberId: 99, ironId: 99});
      expect(
        stockpileAffordsAnyProductionRecipe(stockpile, const []),
        isFalse,
      );
    });

    test('boundary: exactly one short of an input is not affordable', () {
      final stockpile = Stockpile(quantities: {timberId: 2, ironId: 1});
      expect(
        stockpileAffordsAnyProductionRecipe(stockpile, [castIron]),
        isFalse,
      );
    });
  });

  group('stockpileAndLabourAffordAnyProductionRecipe', () {
    test(
      'positive: material on hand and effective labour covers one castIron run '
      '(labourPerOutput 5)',
      () {
        // 10 peasants fed by 10 grain -> 10 effective labour; castIron needs 5
        // labour and 2 timber + 2 iron, so feasibleRuns >= 1.
        final game = buildSeed42S7dFeedstockHelperGame(
          workers: const WorkerPool(peasants: 10),
          stockpile: Stockpile(
            quantities: {grainId: 10, timberId: 2, ironId: 2},
          ),
        );
        expect(
          stockpileAndLabourAffordAnyProductionRecipe(game, kSeed42S7dFeedstockHelperPlayerId, [
            castIron,
          ]),
          isTrue,
        );
      },
    );

    test(
      'negative (labour-starved): material present but effective labour below '
      'one run is not feasible',
      () {
        // 1 peasant fed by 1 grain -> 1 effective labour < castIron's 5, so the
        // recipe is materially affordable yet labour-starved. This is the
        // decisive split the diagnostic relies on.
        final stockpile = Stockpile(
          quantities: {grainId: 1, timberId: 2, ironId: 2},
        );
        final game = buildSeed42S7dFeedstockHelperGame(
          workers: const WorkerPool(peasants: 1),
          stockpile: stockpile,
        );
        expect(
          stockpileAffordsAnyProductionRecipe(stockpile, [castIron]),
          isTrue,
          reason: 'control: the same turn is material-feasible',
        );
        expect(
          stockpileAndLabourAffordAnyProductionRecipe(game, kSeed42S7dFeedstockHelperPlayerId, [
            castIron,
          ]),
          isFalse,
        );
      },
    );

    test('negative: missing a material input is not feasible even with labour', () {
      final game = buildSeed42S7dFeedstockHelperGame(
        workers: const WorkerPool(peasants: 10),
        stockpile: Stockpile(quantities: {grainId: 10, timberId: 2}),
      );
      expect(
        stockpileAndLabourAffordAnyProductionRecipe(game, kSeed42S7dFeedstockHelperPlayerId, [castIron]),
        isFalse,
      );
    });

    test('negative: empty recipe list is never feasible', () {
      final game = buildSeed42S7dFeedstockHelperGame(
        workers: const WorkerPool(peasants: 10),
        stockpile: Stockpile(quantities: {grainId: 10}),
      );
      expect(
        stockpileAndLabourAffordAnyProductionRecipe(game, kSeed42S7dFeedstockHelperPlayerId, const []),
        isFalse,
      );
    });
  });

  registerSeed42S7dFeedstockAffordOwnershipCasesTail();
}
