// Tests for production recipe affordance helpers. SPEC/ui/production-panel.md.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/widgets/production/production_recipe_affordance.dart';
import 'package:colonizethis_app/features/game/widgets/production/production_recipe_affordance_copy.dart';

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

  group('computeRecipeAffordance capLimited (Refs #4717)', () {
    test('sets capLimited when unconstrained batches exceed slider cap', () {
      final recipe = ProductionRecipesCatalog.byId['lumber_from_timber']!;
      final stockpile = const Stockpile().applyDelta('timber', 200);
      final affordance = computeRecipeAffordance(
        recipe: recipe,
        stockpile: stockpile,
        desiredOutputByRecipe: const {},
        effectiveLabour: 200,
      );

      expect(affordance.maxDesiredOutput, kProductionAllocationSliderCap);
      expect(affordance.capLimited, isTrue);
      expect(affordance.limitingLabel, 'timber');
      expect(affordance.limitingCommodityId, 'timber');
    });

    test('does not set capLimited when unconstrained batches equal slider cap', () {
      final recipe = ProductionRecipesCatalog.byId['lumber_from_timber']!;
      final stockpile = const Stockpile().applyDelta('timber', 100);
      final affordance = computeRecipeAffordance(
        recipe: recipe,
        stockpile: stockpile,
        desiredOutputByRecipe: const {},
        effectiveLabour: 200,
      );

      expect(affordance.maxDesiredOutput, 50);
      expect(affordance.capLimited, isFalse);
      expect(affordance.limitingCommodityId, 'timber');
    });
  });

  group('limitingCommodityId and opensDevelopment (Refs #4725)', () {
    test('sets limitingCommodityId for commodity bottleneck', () {
      final recipe = ProductionRecipesCatalog.byId['lumber_from_timber']!;
      final stockpile = const Stockpile().applyDelta('timber', 4);
      final affordance = computeRecipeAffordance(
        recipe: recipe,
        stockpile: stockpile,
        desiredOutputByRecipe: const {},
        effectiveLabour: 200,
      );
      expect(affordance.limitingCommodityId, 'timber');
      expect(recipeAffordanceOpensDevelopment(affordance), isTrue);
    });

    test('null limitingCommodityId when labour-limited', () {
      final recipe = ProductionRecipesCatalog.byId['lumber_from_timber']!;
      final stockpile = const Stockpile().applyDelta('timber', 100);
      final affordance = computeRecipeAffordance(
        recipe: recipe,
        stockpile: stockpile,
        desiredOutputByRecipe: const {},
        effectiveLabour: 0,
      );
      expect(affordance.limitingCommodityId, isNull);
      expect(recipeAffordanceOpensDevelopment(affordance), isFalse);
    });

    test('capLimited does not open Development', () {
      final recipe = ProductionRecipesCatalog.byId['lumber_from_timber']!;
      final stockpile = const Stockpile().applyDelta('timber', 200);
      final affordance = computeRecipeAffordance(
        recipe: recipe,
        stockpile: stockpile,
        desiredOutputByRecipe: const {},
        effectiveLabour: 200,
      );
      expect(affordance.capLimited, isTrue);
      expect(affordance.limitingCommodityId, 'timber');
      expect(recipeAffordanceOpensDevelopment(affordance), isFalse);
    });

    test('multi-input tie uses first-tied commodity id', () {
      final recipe = ProductionRecipesCatalog.byId['paper_from_timber']!;
      // Force both inputs (if any) / labour so first input in map order wins.
      // paper_from_timber typically: timber + labour; with low timber, timber wins.
      final stockpile = const Stockpile().applyDelta('timber', 2);
      final affordance = computeRecipeAffordance(
        recipe: recipe,
        stockpile: stockpile,
        desiredOutputByRecipe: const {},
        effectiveLabour: 200,
      );
      expect(affordance.limitingCommodityId, isNotNull);
      final firstInputId = recipe.inputQuantities.keys.first;
      expect(affordance.limitingCommodityId, firstInputId);
    });
  });
}
