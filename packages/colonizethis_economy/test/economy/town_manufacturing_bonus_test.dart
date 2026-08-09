import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_test/test.dart';

import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';

void main() {
  group('townManufacturingBonusMultiplier (Refs #3872)', () {
    test('level 2 → 1, level 4 → 2, others → 0', () {
      expect(townManufacturingBonusMultiplier(2), 1);
      expect(townManufacturingBonusMultiplier(4), 2);
      expect(townManufacturingBonusMultiplier(1), 0);
      expect(townManufacturingBonusMultiplier(3), 0);
      expect(townManufacturingBonusMultiplier(0), 0);
    });
  });

  group('isTownManufacturingRecipeEligible', () {
    test('recipe excluded when any input is manufactured', () {
      expect(
        isTownManufacturingRecipeEligible(
          ProductionRecipe(
            id: 'test_steel_from_castIron',
            outputCommodityId: CommodityCatalog.steel.id,
            outputQuantity: 1,
            inputQuantities: {
              CommodityCatalog.castIron.id: 2,
              CommodityCatalog.coal.id: 1,
            },
            labourPerOutput: 5,
          ),
        ),
        isFalse,
      );
    });

    test('steel from iron and coal is eligible (all raw inputs)', () {
      expect(
        isTownManufacturingRecipeEligible(
          ProductionRecipesCatalog.steelFromIronCoal,
        ),
        isTrue,
      );
    });

    test('lumber from timber is eligible', () {
      expect(
        isTownManufacturingRecipeEligible(
          ProductionRecipesCatalog.lumberFromTimber,
        ),
        isTrue,
      );
    });
  });

  group('computeTownManufacturingBonusForProvince', () {
    runLabeledScenarios(townManufacturingBonusProvinceScenarios(), (scenario) {
      runTownManufacturingBonusProvinceScenario(scenario);
    }, labelOf: (s) => s.label);
  });

  runLabeledScenarioGroup(
    'computeTownManufacturingBonusForGame',
    townManufacturingBonusGameScenarios(),
    runTownManufacturingBonusGameScenario,
    labelOf: (s) => s.label,
  );
}
