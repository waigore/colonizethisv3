// Tests for production recipe affordance helpers. SPEC/ui/production-panel.md.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/widgets/production/production_recipe_affordance.dart';

void main() {
  suppressLogsForTests();

  final lumberRecipe = ProductionRecipesCatalog.lumberFromTimber;

  group('recipeAllocationComfortHeadroomActive', () {
    test('false when desired >= max', () {
      final stock = Stockpile(
        quantities: {CommodityCatalog.timber.id: 100},
      );
      expect(
        recipeAllocationComfortHeadroomActive(
          recipe: lumberRecipe,
          desiredOutput: 3,
          maxDesiredOutput: 3,
          stockpile: stock,
          desiredOutputByRecipe: const {},
          effectiveLabour: 100,
        ),
        isFalse,
      );
    });

    test('false when max is zero', () {
      final stock = Stockpile(quantities: const {});
      expect(
        recipeAllocationComfortHeadroomActive(
          recipe: lumberRecipe,
          desiredOutput: 0,
          maxDesiredOutput: 0,
          stockpile: stock,
          desiredOutputByRecipe: const {},
          effectiveLabour: 100,
        ),
        isFalse,
      );
    });

    test('true at desired zero when max > 0 and strict slack on inputs/labour',
        () {
      final stock = Stockpile(
        quantities: {CommodityCatalog.timber.id: 10},
      );
      expect(
        recipeAllocationComfortHeadroomActive(
          recipe: lumberRecipe,
          desiredOutput: 0,
          maxDesiredOutput: 5,
          stockpile: stock,
          desiredOutputByRecipe: const {},
          effectiveLabour: 100,
        ),
        isTrue,
      );
    });

    test('false when input stock does not strictly exceed current need', () {
      final stock = Stockpile(
        quantities: {CommodityCatalog.timber.id: 4},
      );
      expect(
        recipeAllocationComfortHeadroomActive(
          recipe: lumberRecipe,
          desiredOutput: 2,
          maxDesiredOutput: 50,
          stockpile: stock,
          desiredOutputByRecipe: const {},
          effectiveLabour: 100,
        ),
        isFalse,
      );
    });

    test('true when desired < max and inputs/labour strictly exceed need', () {
      final stock = Stockpile(
        quantities: {CommodityCatalog.timber.id: 10},
      );
      expect(
        recipeAllocationComfortHeadroomActive(
          recipe: lumberRecipe,
          desiredOutput: 2,
          maxDesiredOutput: 5,
          stockpile: stock,
          desiredOutputByRecipe: const {},
          effectiveLabour: 100,
        ),
        isTrue,
      );
    });

    test('false when labour does not strictly exceed current need', () {
      final stock = Stockpile(
        quantities: {CommodityCatalog.timber.id: 100},
      );
      expect(
        recipeAllocationComfortHeadroomActive(
          recipe: lumberRecipe,
          desiredOutput: 5,
          maxDesiredOutput: 50,
          stockpile: stock,
          desiredOutputByRecipe: const {},
          effectiveLabour: 10,
        ),
        isFalse,
      );
    });
  });
}
