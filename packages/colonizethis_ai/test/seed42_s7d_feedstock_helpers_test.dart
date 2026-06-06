// Unit coverage for the S7-D feedstock probe helper
// `stockpileAffordsAnyProductionRecipe` (Refs #2847).
//
// The helper backs the diagnostic's `gpCastIronRecipeFeasibleTurns` counter,
// which splits a flat `gpCastIronProductionAssignedTurns == 0` into "never
// materially feasible" vs "feasible yet never assigned". These tests pin its
// pure material-affordability semantics (every input commodity satisfied for at
// least one recipe in the list) so the counter cannot silently drift.
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'support/seed42_s7d_feedstock_helpers.dart';

void main() {
  final castIron = ProductionRecipesCatalog.castIronFromTimberIronCoal;
  final lumber = ProductionRecipesCatalog.lumberFromTimber;
  final timberId = CommodityCatalog.timber.id;
  final ironId = CommodityCatalog.iron.id;

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
}
