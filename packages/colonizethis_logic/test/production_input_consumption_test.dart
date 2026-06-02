// Unit tests for the production-input consumption projector
// `productionInputConsumptionByCommodityIdForAssignments` (Refs #3093 —
// industry-allocation reservation slice).
//
// SPEC/game/world-market.md § Per-commodity quantity cap,
// SPEC/program/order-projections.md § Production input consumption
// projection.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
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
        'labour 3 -> runs 1 -> consumes 3 timber)', () {
      // paper_from_timber recipe: inputQuantities = {timber: 3},
      // labourPerOutput = 3. Assigned labour = 3 → runs = 1 → 3 timber
      // reserved. This is the canonical AC example from #3093:
      //   "industry allocation reserving 3"
      final consumption =
          productionInputConsumptionByCommodityIdForAssignments(
        const [
          AssignedRecipe(
            recipeId: 'paper_from_timber',
            assignedLabour: 3,
          ),
        ],
      );
      expect(consumption[CommodityCatalog.timber.id], 3);
      expect(consumption.length, 1);
    });

    test(
        'multi-input recipe (castIron_from_timber_iron_coal: timber 2, '
        'iron 2 — coal removed; labour 5 -> runs 1) populates every '
        'input commodity', () {
      // castIron_from_timber_iron_coal recipe at the time of writing
      // consumes 2 timber + 2 iron per run (5 labour per output).
      final consumption =
          productionInputConsumptionByCommodityIdForAssignments(
        const [
          AssignedRecipe(
            recipeId: 'castIron_from_timber_iron_coal',
            assignedLabour: 5,
          ),
        ],
      );
      expect(consumption[CommodityCatalog.timber.id], 2);
      expect(consumption[CommodityCatalog.iron.id], 2);
      expect(consumption.containsKey(CommodityCatalog.coal.id), isFalse,
          reason: 'castIron recipe no longer lists coal as an input.');
    });

    test('floor(assignedLabour / labourPerOutput) — fractional runs drop', () {
      // paper_from_timber: labourPerOutput = 3. Assigned labour = 8 →
      // runs = floor(8/3) = 2 → 6 timber consumed.
      final consumption =
          productionInputConsumptionByCommodityIdForAssignments(
        const [
          AssignedRecipe(
            recipeId: 'paper_from_timber',
            assignedLabour: 8,
          ),
        ],
      );
      expect(consumption[CommodityCatalog.timber.id], 6);
    });

    test('multiple recipes contributing to the same input sum together', () {
      // paper_from_timber (3 labour → 3 timber) +
      // lumber_from_timber (4 labour → runs 2 → 4 timber) = 7 timber.
      final consumption =
          productionInputConsumptionByCommodityIdForAssignments(
        const [
          AssignedRecipe(
            recipeId: 'paper_from_timber',
            assignedLabour: 3,
          ),
          AssignedRecipe(
            recipeId: 'lumber_from_timber',
            assignedLabour: 4,
          ),
        ],
      );
      expect(consumption[CommodityCatalog.timber.id], 7);
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
            assignedLabour: 3,
          ),
        ],
      );
      expect(consumption[CommodityCatalog.timber.id], 3);
      expect(consumption.length, 1);
    });

    test(
        'sub-labourPerOutput assignment contributes zero (runs = 0; '
        'commodity absent from map, not present with value 0)', () {
      // paper_from_timber needs 3 labour per run; 1 labour → runs 0
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
  });
}
