// Ported from colonizethis_logic (Refs #4090 Slice E).
// Unit tests for the production-input consumption projector
// `productionInputConsumptionByCommodityIdForAssignments` (Refs #3093 —
// industry-allocation reservation slice).
//
// SPEC/game/world-market.md § Per-commodity quantity cap,
// SPEC/program/order-projections.md § Production input consumption
// projection.
// Table-driven (Refs #3939) for economy scenario-table preference.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

typedef _ConsumptionScenario = ({
  String label,
  List<AssignedRecipe> assignments,
  Map<CommodityId, int> expected,
});

List<_ConsumptionScenario> _scenarios() => [
      (
        label: 'returns empty map for empty assignments',
        assignments: const <AssignedRecipe>[],
        expected: const <CommodityId, int>{},
      ),
      (
        // paper_from_timber: inputQuantities = {timber: 2}, labourPerOutput = 2.
        // Assigned labour = 2 → runs = 1 → 2 timber reserved (#3093 AC).
        label: 'sums input quantity x runs per commodity (paper_from_timber: '
            'labour 2 -> runs 1 -> consumes 2 timber)',
        assignments: const [
          AssignedRecipe(recipeId: 'paper_from_timber', assignedLabour: 2),
        ],
        expected: {CommodityCatalog.timber.id: 2},
      ),
      (
        label: 'single-input recipe (castIron_from_iron: iron 2, '
            'labour 2 -> runs 1) populates input commodity',
        assignments: const [
          AssignedRecipe(recipeId: 'castIron_from_iron', assignedLabour: 2),
        ],
        expected: {CommodityCatalog.iron.id: 2},
      ),
      (
        // paper_from_timber labourPerOutput = 2; labour 8 → runs 4 → 8 timber.
        label: 'floor(assignedLabour / labourPerOutput) — fractional runs drop',
        assignments: const [
          AssignedRecipe(recipeId: 'paper_from_timber', assignedLabour: 8),
        ],
        expected: {CommodityCatalog.timber.id: 8},
      ),
      (
        // paper_from_timber (2 labour → 2 timber) + lumber_from_timber
        // (4 labour → runs 2 → 4 timber) = 6 timber.
        label: 'multiple recipes contributing to the same input sum together',
        assignments: const [
          AssignedRecipe(recipeId: 'paper_from_timber', assignedLabour: 2),
          AssignedRecipe(recipeId: 'lumber_from_timber', assignedLabour: 4),
        ],
        expected: {CommodityCatalog.timber.id: 6},
      ),
      (
        label: 'zero labour assignments contribute nothing (negative labour is '
            'forbidden by AssignedRecipe constructor assert)',
        assignments: const [
          AssignedRecipe(recipeId: 'paper_from_timber', assignedLabour: 0),
        ],
        expected: const <CommodityId, int>{},
      ),
      (
        label: 'unknown recipe ids are silently skipped (defensive)',
        assignments: const [
          AssignedRecipe(
            recipeId: 'ghost_recipe_does_not_exist',
            assignedLabour: 9999,
          ),
          AssignedRecipe(recipeId: 'paper_from_timber', assignedLabour: 2),
        ],
        expected: {CommodityCatalog.timber.id: 2},
      ),
      (
        // paper_from_timber needs 2 labour/run; 1 labour → runs 0 → absent key.
        label: 'sub-labourPerOutput assignment contributes zero (runs = 0; '
            'commodity absent from map, not present with value 0)',
        assignments: const [
          AssignedRecipe(recipeId: 'paper_from_timber', assignedLabour: 1),
        ],
        expected: const <CommodityId, int>{},
      ),
      (
        label: 'steel_from_iron_coal consumes iron and coal per normalized '
            'recipe (Refs #3873)',
        assignments: const [
          AssignedRecipe(recipeId: 'steel_from_iron_coal', assignedLabour: 2),
        ],
        expected: {
          CommodityCatalog.iron.id: 1,
          CommodityCatalog.coal.id: 1,
        },
      ),
    ];

void main() {
  group('productionInputConsumptionByCommodityIdForAssignments (Refs #3093)',
      () {
    runLabeledScenarios(_scenarios(), (scenario) {
      final consumption =
          productionInputConsumptionByCommodityIdForAssignments(
        scenario.assignments,
      );
      expect(consumption, scenario.expected);
      // Negative: unrelated inputs must not appear as zero placeholders.
      if (!scenario.expected.containsKey(CommodityCatalog.timber.id)) {
        expect(consumption.containsKey(CommodityCatalog.timber.id), isFalse);
      }
      if (!scenario.expected.containsKey(CommodityCatalog.coal.id)) {
        expect(consumption.containsKey(CommodityCatalog.coal.id), isFalse);
      }
      if (!scenario.expected.containsKey(CommodityCatalog.castIron.id)) {
        expect(
          consumption.containsKey(CommodityCatalog.castIron.id),
          isFalse,
        );
      }
    }, labelOf: (s) => s.label);
  });
}
