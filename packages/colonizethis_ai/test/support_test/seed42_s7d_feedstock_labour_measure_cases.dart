// Case bodies for seed42_s7d_feedstock_helpers_test labour/measure pins
// (Refs #3997 Phase 8).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import '../support/seed42_s7d_feedstock_helpers.dart';
import '../support/seed42_s7d_feedstock_helpers_test_support.dart';
import 'seed42_s7d_feedstock_labour_measure_tail_cases.dart';

void registerSeed42S7dFeedstockLabourMeasureCases() {
  registerSeed42S7dFeedstockLabourMeasureTailCases();
  final castIron = ProductionRecipesCatalog.castIronFromIron;
  final fabricFromWool = ProductionRecipesCatalog.fabricFromWool;
  final timberId = CommodityCatalog.timber.id;
  final ironId = CommodityCatalog.iron.id;
  final woolId = CommodityCatalog.wool.id;
  final grainId = CommodityCatalog.grain.id;
  final meatId = CommodityCatalog.meat.id;

  group('playerRawLabourSupply', () {
    test('positive: tier-weighted population ceiling ignores food', () {
      // 2 peasants (1 each) + 1 journeyman (6) = 8 raw labour, regardless of an
      // empty stockpile — this is the fully-fed ceiling.
      final game = buildSeed42S7dFeedstockHelperGame(
        workers: const WorkerPool(peasants: 2, journeymen: 1),
      );
      expect(playerRawLabourSupply(game, kSeed42S7dFeedstockHelperPlayerId), 8);
    });

    test('positive: counts every tier (peasant/apprentice/journeyman/master)', () {
      // 1*1 + 1*4 + 1*6 + 1*8 = 19.
      final game = buildSeed42S7dFeedstockHelperGame(
        workers: const WorkerPool(
          peasants: 1,
          apprentices: 1,
          journeymen: 1,
          masters: 1,
        ),
      );
      expect(playerRawLabourSupply(game, kSeed42S7dFeedstockHelperPlayerId), 19);
    });

    test('negative: unknown player has no labour supply', () {
      final game = buildSeed42S7dFeedstockHelperGame(workers: const WorkerPool(peasants: 10));
      expect(playerRawLabourSupply(game, 'no_such_player'), 0);
    });
  });

  group('playerEffectiveLabour', () {
    test('positive: fully-fed workers supply their full labour', () {
      // 10 peasants fed by 10 grain -> 10 effective labour (no military upkeep).
      final game = buildSeed42S7dFeedstockHelperGame(
        workers: const WorkerPool(peasants: 10),
        stockpile: Stockpile(quantities: {grainId: 10}),
      );
      expect(playerEffectiveLabour(game, kSeed42S7dFeedstockHelperPlayerId), 10);
    });

    test(
      'food-starved: raw ceiling exceeds effective labour when food is short',
      () {
        // 10 peasants but only 3 grain -> 3 fed -> 3 effective labour, far below
        // the raw ceiling of 10. This is the food-starved fork condition.
        final game = buildSeed42S7dFeedstockHelperGame(
          workers: const WorkerPool(peasants: 10),
          stockpile: Stockpile(quantities: {grainId: 3}),
        );
        expect(playerRawLabourSupply(game, kSeed42S7dFeedstockHelperPlayerId), 10);
        expect(playerEffectiveLabour(game, kSeed42S7dFeedstockHelperPlayerId), lessThan(10));
        expect(playerEffectiveLabour(game, kSeed42S7dFeedstockHelperPlayerId), 3);
      },
    );

    test('negative: no food means every worker strikes (zero labour)', () {
      final game = buildSeed42S7dFeedstockHelperGame(
        workers: const WorkerPool(peasants: 10),
        stockpile: const Stockpile(),
      );
      expect(playerEffectiveLabour(game, kSeed42S7dFeedstockHelperPlayerId), 0);
    });

    test('negative: unknown player has no effective labour', () {
      final game = buildSeed42S7dFeedstockHelperGame(
        workers: const WorkerPool(peasants: 10),
        stockpile: Stockpile(quantities: {grainId: 10}),
      );
      expect(playerEffectiveLabour(game, 'no_such_player'), 0);
    });
  });

  group('playerFoodOnHand', () {
    final foodIds = {grainId, meatId};

    test('positive: sums grain and meat on hand', () {
      final game = buildSeed42S7dFeedstockHelperGame(
        stockpile: Stockpile(quantities: {grainId: 7, meatId: 5, timberId: 9}),
      );
      expect(playerFoodOnHand(game, kSeed42S7dFeedstockHelperPlayerId, foodIds), 12);
    });

    test('negative: empty stockpile holds no food', () {
      final game = buildSeed42S7dFeedstockHelperGame(stockpile: const Stockpile());
      expect(playerFoodOnHand(game, kSeed42S7dFeedstockHelperPlayerId, foodIds), 0);
    });

    test('negative: empty food id set returns zero', () {
      final game = buildSeed42S7dFeedstockHelperGame(
        stockpile: Stockpile(quantities: {grainId: 7, meatId: 5}),
      );
      expect(playerFoodOnHand(game, kSeed42S7dFeedstockHelperPlayerId, const {}), 0);
    });

    test('negative: unknown player holds no food', () {
      final game = buildSeed42S7dFeedstockHelperGame(
        stockpile: Stockpile(quantities: {grainId: 7, meatId: 5}),
      );
      expect(playerFoodOnHand(game, 'no_such_player', foodIds), 0);
    });
  });

  group('seed42S7dCastIronLabourTurnMeasure.fabricRecipeLabourFeasible', () {
    ({
      bool peasantRecruitGate,
      bool peasantRecruitAffordable,
      bool holdsFabricFeedstock,
      bool fabricRecipeFeasible,
      bool fabricRecipeLabourFeasible,
      bool castIronMaterialFeasible,
      bool castIronLabourFeasible,
      bool castIronLabourFoodStarved,
      bool castIronLabourPopulationBound,
      bool castIronOwnsFeedstockTile,
    })
    measure(Game game) => seed42S7dCastIronLabourTurnMeasure(
      game: game,
      playerId: kSeed42S7dFeedstockHelperPlayerId,
      fabricFeedstockIds: {woolId},
      fabricRecipes: [fabricFromWool],
      castIronRecipes: [castIron],
      castIronFeedstockIds: {timberId, ironId},
      castIronMinLabourPerOutput: 5,
    );

    test('positive: fabric material- and labour-feasible at 2 labour', () {
      final ci = measure(
        buildSeed42S7dFeedstockHelperGame(
          workers: const WorkerPool(peasants: 2),
          stockpile: Stockpile(quantities: {grainId: 2, woolId: 2}),
        ),
      );
      expect(ci.fabricRecipeFeasible, isTrue);
      expect(ci.fabricRecipeLabourFeasible, isTrue);
    });

    test(
      'negative (circular deadlock): fabric material-feasible yet labour-'
      'starved at a single effective labour',
      () {
        final ci = measure(
          buildSeed42S7dFeedstockHelperGame(
            workers: const WorkerPool(peasants: 1),
            stockpile: Stockpile(quantities: {grainId: 1, woolId: 2}),
          ),
        );
        expect(ci.fabricRecipeFeasible, isTrue);
        expect(ci.fabricRecipeLabourFeasible, isFalse);
      },
    );

    test(
      'subset invariant: labour-feasible is false whenever material-feasible '
      'is false (no wool on hand)',
      () {
        final ci = measure(
          buildSeed42S7dFeedstockHelperGame(
            workers: const WorkerPool(peasants: 10),
            stockpile: Stockpile(quantities: {grainId: 10}),
          ),
        );
        expect(ci.fabricRecipeFeasible, isFalse);
        expect(ci.fabricRecipeLabourFeasible, isFalse);
      },
    );
  });
}

void main() {
  registerSeed42S7dFeedstockLabourMeasureCases();
}

