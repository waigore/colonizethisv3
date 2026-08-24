import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  suppressLogsForTests();

  group('previewForceFeeding', () {
    test('hides when no regiments or ships', () {
      final snapshot = previewForceFeeding(stockpile: const Stockpile());
      expect(snapshot.hasAnyForces, isFalse);
      expect(snapshot.isFullyFed, isTrue);
    });

    test('land fully fed when stockpile covers demand', () {
      final snapshot = previewForceFeeding(
        stockpile: const Stockpile().applyDelta('grain', 10),
        foodCounts: const MilitaryNavyFoodCounts(
          regimentCountsById: {'pikemen': 2},
        ),
      );
      expect(snapshot.totalRegiments, 2);
      expect(snapshot.fullyFedRegiments, 2);
      expect(snapshot.landCombatTier, ForceFeedingCombatTier.full);
      expect(snapshot.isLandFullyFed, isTrue);
    });

    test('land moderate tier when coverage is in [0.5, 1.0)', () {
      final snapshot = previewForceFeeding(
        stockpile: const Stockpile().applyDelta('grain', 4),
        foodCounts: const MilitaryNavyFoodCounts(
          regimentCountsById: {'pikemen': 3},
        ),
      );
      expect(snapshot.landCombatTier, ForceFeedingCombatTier.moderate);
      expect(snapshot.isLandFullyFed, isFalse);
    });

    test('land severe tier when coverage is below 0.5', () {
      final snapshot = previewForceFeeding(
        stockpile: const Stockpile().applyDelta('grain', 2),
        foodCounts: const MilitaryNavyFoodCounts(
          regimentCountsById: {'pikemen': 3},
        ),
      );
      expect(snapshot.landCombatTier, ForceFeedingCombatTier.severe);
    });

    test('matches allocateConsumption military/navy fully-fed counts', () {
      const foodCounts = MilitaryNavyFoodCounts(
        regimentCountsById: {'pikemen': 3},
        shipCountsById: {'carrack': 1},
      );
      final stockpile = const Stockpile().applyDelta('grain', 8);
      final preview = previewForceFeeding(
        stockpile: stockpile,
        foodCounts: foodCounts,
      );
      final alloc = allocateConsumption(
        stockpile: stockpile,
        workers: WorkerPool.empty,
        foodCounts: foodCounts,
      );
      expect(preview.totalRegiments, alloc.totalRegiments);
      expect(preview.fullyFedRegiments, alloc.fullyFedRegiments);
      expect(preview.totalShips, alloc.totalShips);
      expect(preview.fullyFedShips, alloc.fullyFedShips);
      expect(
        preview.forcesFoodDemand,
        allocateMilitaryNavyFood(
          stockpile: stockpile,
          foodCounts: foodCounts,
        ).forcesFoodDemand,
      );
    });
  });
}
