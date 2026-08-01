// AI recruitment luxury helpers delegate to shared industry counsel economy
// modules (Refs #4189).

import 'package:colonizethis_ai/src/planning/recruitment_planner_candidates_ledger.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('recruitment luxury helpers delegate to industry counsel economy', () {
    test('softLuxuryCapDeficitLimit matches industryCounselSoftLuxuryCapDeficitLimit', () {
      for (final sustainable in [0, 1, 5, 10, 99]) {
        expect(
          softLuxuryCapDeficitLimit(sustainable),
          industryCounselSoftLuxuryCapDeficitLimit(sustainable),
        );
      }
    });

    test('sustainableTrainedCounts matches industryCounselSustainableTrainedCounts', () {
      final stockpile = Stockpile()
          .applyDelta(CommodityCatalog.refinedSugar.id, 3)
          .applyDelta(CommodityCatalog.cigars.id, 7);
      const assignments = [
        AssignedRecipe(recipeId: 'refinedSugar_from_sugarCane', assignedLabour: 4),
        AssignedRecipe(recipeId: 'cigars_from_tobacco', assignedLabour: 6),
      ];
      final plan = EconomyPlan(
        productionAssignments: assignments,
        cargoPreference: CargoPreference.none,
      );

      expect(
        sustainableTrainedCounts(stockpile: stockpile, economyPlanHint: plan),
        industryCounselSustainableTrainedCounts(
          stockpile: stockpile,
          productionAssignments: assignments,
        ),
      );
    });

    test('projectedLuxuryOutput matches industryCounselProjectedLuxuryOutput', () {
      const assignments = [
        AssignedRecipe(recipeId: 'furHats_from_furs', assignedLabour: 8),
      ];
      final plan = EconomyPlan(
        productionAssignments: assignments,
        cargoPreference: CargoPreference.none,
      );

      expect(
        projectedLuxuryOutput(plan),
        industryCounselProjectedLuxuryOutput(assignments),
      );
      expect(projectedLuxuryOutput(null), industryCounselProjectedLuxuryOutput(const []));
    });

    test('totalAssignedLabourInEconomyPlan matches industryCounselTotalAssignedLabour', () {
      const assignments = [
        AssignedRecipe(recipeId: 'lumber_from_timber', assignedLabour: 5),
        AssignedRecipe(recipeId: 'fabric_from_wool', assignedLabour: 3),
      ];
      final plan = EconomyPlan(
        productionAssignments: assignments,
        cargoPreference: CargoPreference.none,
      );

      expect(
        totalAssignedLabourInEconomyPlan(plan),
        industryCounselTotalAssignedLabour(assignments),
      );
    });
  });
}
