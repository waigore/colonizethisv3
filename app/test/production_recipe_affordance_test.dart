// Unit tests for production recipe affordance. SPEC/ui/production-panel.md.

import 'package:colonizethis_app/features/game/production_recipe_affordance.dart';
import 'package:colonizethis_app/features/game/widgets/production_panel_demo_data.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

void main() {
  suppressLogsForTests();

  group('computeRecipeAffordance', () {
    test('partial player: lumber capped by labour', () {
      final player = partialAvailabilityProductionPlayer();
      final effectiveLabour = effectiveLabourForWorkers(
        workers: player.workerPool,
        stockpile: player.stockpile,
      );
      final affordance = computeRecipeAffordance(
        recipe: ProductionRecipesCatalog.lumberFromTimber,
        stockpile: player.stockpile,
        desiredOutputByRecipe: const {},
        effectiveLabour: effectiveLabour,
      );
      expect(affordance.maxDesiredOutput, 1);
      expect(affordance.limitingLabel, 'Labour');
    });

    test('other recipes committed inputs reduce lumber max', () {
      final stockpile = Stockpile(
        quantities: {
          CommodityCatalog.grain.id: 20,
          CommodityCatalog.timber.id: 100,
        },
      );
      const workers = WorkerPool(
        peasants: 100,
        apprentices: 0,
        journeymen: 0,
        masters: 0,
      );
      final effectiveLabour = effectiveLabourForWorkers(
        workers: workers,
        stockpile: stockpile,
      );
      final baseline = computeRecipeAffordance(
        recipe: ProductionRecipesCatalog.lumberFromTimber,
        stockpile: stockpile,
        desiredOutputByRecipe: const {},
        effectiveLabour: effectiveLabour,
      );
      expect(baseline.maxDesiredOutput, kProductionAllocationSliderCap);

      final affordance = computeRecipeAffordance(
        recipe: ProductionRecipesCatalog.lumberFromTimber,
        stockpile: stockpile,
        desiredOutputByRecipe: const {'paper_from_timber': 10},
        effectiveLabour: effectiveLabour,
      );
      expect(affordance.maxDesiredOutput, 35);
      expect(affordance.limitingLabel, 'Timber');
    });

    test('tie on inputs uses first input in recipe map order', () {
      final stockpile = Stockpile(
        quantities: {
          CommodityCatalog.timber.id: 10,
          CommodityCatalog.iron.id: 10,
        },
      );
      final affordance = computeRecipeAffordance(
        recipe: ProductionRecipesCatalog.castIronFromTimberIronCoal,
        stockpile: stockpile,
        desiredOutputByRecipe: const {},
        effectiveLabour: 500,
      );
      expect(affordance.maxDesiredOutput, 5);
      expect(affordance.limitingLabel, 'Timber');
    });

    test('applies slider cap when stock and labour are abundant', () {
      final stockpile = Stockpile(
        quantities: {
          CommodityCatalog.grain.id: 20,
          CommodityCatalog.timber.id: 500,
        },
      );
      const workers = WorkerPool(
        peasants: 150,
        apprentices: 0,
        journeymen: 0,
        masters: 0,
      );
      final effectiveLabour = effectiveLabourForWorkers(
        workers: workers,
        stockpile: stockpile,
      );
      final affordance = computeRecipeAffordance(
        recipe: ProductionRecipesCatalog.lumberFromTimber,
        stockpile: stockpile,
        desiredOutputByRecipe: const {},
        effectiveLabour: effectiveLabour,
      );
      expect(affordance.maxDesiredOutput, kProductionAllocationSliderCap);
      expect(affordance.limitingLabel, 'Labour');
    });

    test('zero remaining labour for recipe yields 0 and Labour', () {
      final player = fullAvailabilityProductionPlayer();
      final effectiveLabour = effectiveLabourForWorkers(
        workers: player.workerPool,
        stockpile: player.stockpile,
      );
      final affordance = computeRecipeAffordance(
        recipe: ProductionRecipesCatalog.lumberFromTimber,
        stockpile: player.stockpile,
        desiredOutputByRecipe: const {'fabric_from_wool': 25},
        effectiveLabour: effectiveLabour,
      );
      expect(affordance.maxDesiredOutput, 0);
      expect(affordance.limitingLabel, 'Labour');
    });
  });
}
