import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('build_cost', () {
    test('canAffordBuild returns false for unknown unit type', () {
      const player = Player(id: 'p1', displayName: 'P', isHuman: true);
      const workers = WorkerPool(peasants: 10);
      const stockpile = Stockpile();
      const order = BuildUnitOrder(
        unitType: 'unknown_unit_xyz',
        isMilitary: false,
        spawnProvinceId: 'oldWorld|p1',
      );
      final result = canAffordBuild(
        player,
        order,
        workers,
        stockpile,
        10000,
      );
      expect(result.canAfford, isFalse);
      expect(result.reason, isNotNull);
    });

    test('applyBuildCostDeduction returns unchanged state for unknown unit type', () {
      const player = Player(id: 'p1', displayName: 'P', isHuman: true);
      const workers = WorkerPool(peasants: 5);
      const stockpile = Stockpile();
      const order = BuildUnitOrder(
        unitType: 'unknown_unit_xyz',
        isMilitary: false,
        spawnProvinceId: 'oldWorld|p1',
      );
      final result = applyBuildCostDeduction(
        player,
        order,
        workers,
        stockpile,
        1000,
      );
      expect(result.workers.peasants, 5);
      expect(result.treasury, 1000);
    });
  });
}
