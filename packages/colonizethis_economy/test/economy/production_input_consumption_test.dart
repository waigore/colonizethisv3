// Ported from colonizethis_logic (Refs #4090 Slice E).
// Unit tests for the production-input consumption projector
// `productionInputConsumptionByCommodityIdForAssignments` (Refs #3093 —
// industry-allocation reservation slice).
//
// SPEC/game/world-market.md § Per-commodity quantity cap,
// SPEC/program/order-projections.md § Production input consumption
// projection.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('productionInputConsumptionByCommodityIdForAssignments (Refs #3093)',
      () {
    test('returns empty map for empty assignments', () {
      expect(
        productionInputConsumptionByCommodityIdForAssignments(
          const <AssignedRecipe>[],
        ),
        isEmpty,
      );
    });

    test(
        'sums input quantity x runs per commodity (paper_from_timber: '
        'labour 2 -> runs 1 -> consumes 2 timber)', () {
      // paper_from_timber recipe: inputQuantities = {timber: 2},
      // labourPerOutput = 2. Assigned labour = 2 → runs = 1 → 2 timber
      // reserved. This is the canonical AC example from #3093:
      //   "industry allocation reserving 2"
      final consumption =
          productionInputConsumptionByCommodityIdForAssignments(
        const [
          AssignedRecipe(
            recipeId: 'paper_from_timber',
            assignedLabour: 2,
          ),
        ],
      );
      expect(consumption[CommodityCatalog.timber.id], 2);
      expect(consumption.length, 1);
    });

    test(
        'single-input recipe (castIron_from_iron: iron 2, '
        'labour 2 -> runs 1) populates input commodity', () {
      final consumption =
          productionInputConsumptionByCommodityIdForAssignments(
        const [
          AssignedRecipe(
            recipeId: 'castIron_from_iron',
            assignedLabour: 2,
          ),
        ],
      );
      expect(consumption[CommodityCatalog.iron.id], 2);
      expect(consumption.containsKey(CommodityCatalog.timber.id), isFalse);
      expect(consumption.containsKey(CommodityCatalog.coal.id), isFalse);
    });

    test('floor(assignedLabour / labourPerOutput) — fractional runs drop', () {
      // paper_from_timber: labourPerOutput = 2. Assigned labour = 8 →
      // runs = floor(8/2) = 4 → 8 timber consumed.
      final consumption =
          productionInputConsumptionByCommodityIdForAssignments(
        const [
          AssignedRecipe(
            recipeId: 'paper_from_timber',
            assignedLabour: 8,
          ),
        ],
      );
      expect(consumption[CommodityCatalog.timber.id], 8);
    });

    test('multiple recipes contributing to the same input sum together', () {
      // paper_from_timber (2 labour → 2 timber) +
      // lumber_from_timber (4 labour → runs 2 → 4 timber) = 6 timber.
      final consumption =
          productionInputConsumptionByCommodityIdForAssignments(
        const [
          AssignedRecipe(
            recipeId: 'paper_from_timber',
            assignedLabour: 2,
          ),
          AssignedRecipe(
            recipeId: 'lumber_from_timber',
            assignedLabour: 4,
          ),
        ],
      );
      expect(consumption[CommodityCatalog.timber.id], 6);
    });

    test(
        'zero labour assignments contribute nothing (negative labour is '
        'forbidden by AssignedRecipe constructor assert)', () {
      final consumption =
          productionInputConsumptionByCommodityIdForAssignments(
        const [
          AssignedRecipe(
            recipeId: 'paper_from_timber',
            assignedLabour: 0,
          ),
        ],
      );
      expect(consumption, isEmpty);
    });

    test('unknown recipe ids are silently skipped (defensive)', () {
      final consumption =
          productionInputConsumptionByCommodityIdForAssignments(
        const [
          AssignedRecipe(
            recipeId: 'ghost_recipe_does_not_exist',
            assignedLabour: 9999,
          ),
          AssignedRecipe(
            recipeId: 'paper_from_timber',
            assignedLabour: 2,
          ),
        ],
      );
      expect(consumption[CommodityCatalog.timber.id], 2);
      expect(consumption.length, 1);
    });

    test(
        'sub-labourPerOutput assignment contributes zero (runs = 0; '
        'commodity absent from map, not present with value 0)', () {
      // paper_from_timber needs 2 labour per run; 1 labour → runs 0
      // → no consumption. The commodity should NOT appear as a 0
      // entry — callers treat absence as 0.
      final consumption =
          productionInputConsumptionByCommodityIdForAssignments(
        const [
          AssignedRecipe(
            recipeId: 'paper_from_timber',
            assignedLabour: 1,
          ),
        ],
      );
      expect(consumption.containsKey(CommodityCatalog.timber.id), isFalse);
      expect(consumption, isEmpty);
    });

    test(
        'steel_from_iron_coal consumes iron and coal per normalized recipe '
        '(Refs #3873)',
        () {
      final consumption =
          productionInputConsumptionByCommodityIdForAssignments(
        const [
          AssignedRecipe(
            recipeId: 'steel_from_iron_coal',
            assignedLabour: 2,
          ),
        ],
      );
      expect(consumption[CommodityCatalog.iron.id], 1);
      expect(consumption[CommodityCatalog.coal.id], 1);
      expect(consumption.containsKey(CommodityCatalog.castIron.id), isFalse);
    });
  });
}
